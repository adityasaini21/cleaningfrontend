import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/order.dart';
import '../services/order_history_service.dart';
import '../services/geocoding_service.dart';

import 'deleted_products_screen.dart';

class AdminOrdersScreen extends StatefulWidget {

  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() =>
      _AdminOrdersScreenState();
}

class _AdminOrdersScreenState
    extends State<AdminOrdersScreen> {

  final OrderHistoryService _service = OrderHistoryService();

  List<OrderModel>? _cachedOrders;
  bool _isLoading = true;
  String? _errorMessage;

  final Map<int, TextEditingController> _deliveryNameControllers = {};
  final Map<int, TextEditingController> _deliveryPhoneControllers = {};

  @override
  void dispose() {
    for (var controller in _deliveryNameControllers.values) {
      controller.dispose();
    }
    for (var controller in _deliveryPhoneControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  // =====================================
  // LOAD ORDERS
  // =====================================

  void _loadOrders({bool silent = false}) {
    if (!silent && _cachedOrders == null) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    _service.fetchAllOrders().then((data) {
      if (mounted) {
        setState(() {
          _cachedOrders = data;
          _isLoading = false;
          _errorMessage = null;
        });
      }
    }).catchError((err) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (_cachedOrders == null) {
            _errorMessage = err.toString();
          }
        });
      }
    });
  }

  // =====================================
  // =====================================
  // OPEN GOOGLE MAPS FOR CUSTOMER LOCATION
  // =====================================

  /// Extracts coordinates from text (e.g., "26.4499, 80.3319" or "lat: 26.44, lng: 80.33") if present
  static Map<String, double>? _tryExtractCoordinates(String text) {
    if (text.isEmpty) return null;
    final regex = RegExp(r'([-+]?\d{1,2}\.\d+)[,\s]+([-+]?\d{1,3}\.\d+)');
    final match = regex.firstMatch(text);
    if (match != null) {
      final lat = double.tryParse(match.group(1)!);
      final lng = double.tryParse(match.group(2)!);
      if (lat != null && lng != null && lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180) {
        return {'lat': lat, 'lng': lng};
      }
    }
    return null;
  }

  Future<void> _openGoogleMaps({
    required String address,
    required String pincode,
    double? latitude,
    double? longitude,
  }) async {
    // Check if coordinates were explicitly passed or embedded in address
    final extracted = (latitude != null && longitude != null)
        ? {'lat': latitude, 'lng': longitude}
        : _tryExtractCoordinates(address);

    Uri uri;
    if (extracted != null) {
      uri = Uri.parse("https://www.google.com/maps/search/?api=1&query=${extracted['lat']},${extracted['lng']}");
    } else {
      final query = [address, pincode].where((s) => s.trim().isNotEmpty).join(", ");
      if (query.isEmpty) return;
      uri = Uri.parse("https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}");
    }

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not open Google Maps")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error opening Maps: $e")),
      );
    }
  }

  // =====================================
  // SHARE DELIVERY DETAILS WITH RIDER
  // =====================================

  // =====================================
  // SHARE DELIVERY DETAILS WITH RIDER
  // =====================================

  void _shareDeliveryDetails(OrderModel order) {
    Map<String, double>? extractedCoords = _tryExtractCoordinates(order.shippingAddress);
    double? latVal = extractedCoords?['lat'];
    double? lngVal = extractedCoords?['lng'];
    bool isResolvingCoords = (latVal == null || lngVal == null);

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            // Trigger background forward geocoding if coords not yet extracted
            if (isResolvingCoords) {
              GeocodingService().forwardGeocode(
                address: order.shippingAddress,
                pincode: order.pincode,
              ).then((result) {
                if (result != null && ctx.mounted) {
                  setModalState(() {
                    latVal = result.lat;
                    lngVal = result.lng;
                    extractedCoords = {'lat': result.lat, 'lng': result.lng};
                    isResolvingCoords = false;
                  });
                } else if (ctx.mounted) {
                  setModalState(() {
                    isResolvingCoords = false;
                  });
                }
              }).catchError((_) {
                if (ctx.mounted) {
                  setModalState(() {
                    isResolvingCoords = false;
                  });
                }
              });
            }

            // Navigation Links
            final addressQuery = [order.shippingAddress, order.pincode].where((s) => s.trim().isNotEmpty).join(", ");
            final addressMapsLink = "https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(addressQuery)}";
            final coordMapsLink = (latVal != null && lngVal != null)
                ? "https://www.google.com/maps/search/?api=1&query=$latVal,$lngVal"
                : addressMapsLink;

            String buildMessage({bool useCoordinates = true}) {
              final navLink = (useCoordinates && latVal != null && lngVal != null) ? coordMapsLink : addressMapsLink;
              final coordText = (latVal != null && lngVal != null)
                  ? "\n🎯 *Exact GPS Coordinates:* ${latVal!.toStringAsFixed(5)}, ${lngVal!.toStringAsFixed(5)}"
                  : "";
              return """
📦 *NuKlean Delivery Assignment*
🆔 *Order ID:* ${order.orderCode}
👤 *Customer:* ${order.customerName.trim().isNotEmpty ? order.customerName.trim() : 'Customer'}
📞 *Phone:* ${order.phoneNumber}
📍 *Delivery Address:* ${order.shippingAddress}${order.pincode.trim().isNotEmpty ? " - ${order.pincode.trim()}" : ""}$coordText
🗺️ *Google Maps Navigation:* $navLink
💰 *Amount to Collect:* ₹${order.totalAmount.toStringAsFixed(2)} (${order.paymentStatus})
""";
            }

            final List<Widget> items = [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade600,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Share / Navigate to Customer",
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              if (latVal != null && lngVal != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  margin: const EdgeInsets.only(top: 4, bottom: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF30D158).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF30D158).withValues(alpha: 0.3), width: 0.8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.gps_fixed, color: Color(0xFF30D158), size: 14),
                      const SizedBox(width: 6),
                      Text(
                        "🎯 Exact GPS Coordinates: ${latVal!.toStringAsFixed(5)}, ${lngVal!.toStringAsFixed(5)}",
                        style: const TextStyle(color: Color(0xFF30D158), fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                )
              else if (isResolvingCoords)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF30D158))),
                      SizedBox(width: 8),
                      Text("Detecting pinpoint GPS coordinates...", style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                )
              else
                Text(
                  "Send delivery address & navigation link directly to your rider.",
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              const SizedBox(height: 14),
              // Option 1: WhatsApp (Address + Link + Coordinates)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFF25D366),
                  child: Icon(Icons.chat_bubble_outline, color: Colors.white),
                ),
                title: const Text("Share via WhatsApp", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                subtitle: Text(
                  order.deliveryBoyPhone.trim().isNotEmpty
                      ? "Send to rider (${order.deliveryBoyPhone})"
                      : "Open WhatsApp to choose contact",
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 14),
                onTap: () async {
                  Navigator.pop(ctx);
                  final message = buildMessage(useCoordinates: true);
                  final cleanPhone = order.deliveryBoyPhone.replaceAll(RegExp(r'[^0-9]'), '');
                  final waUrl = cleanPhone.isNotEmpty
                      ? "https://wa.me/$cleanPhone?text=${Uri.encodeComponent(message)}"
                      : "https://wa.me/?text=${Uri.encodeComponent(message)}";
                  final uri = Uri.parse(waUrl);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
              ),
              const Divider(color: Color(0xFF2C2C2E)),
              // Option 2: Copy Exact Navigation Link & GPS
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFF0A84FF),
                  child: Icon(Icons.copy, color: Colors.white),
                ),
                title: const Text("Copy Delivery Details & Link", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                subtitle: Text(
                  (latVal != null && lngVal != null)
                      ? "Includes exact coordinates (${latVal!.toStringAsFixed(4)}, ${lngVal!.toStringAsFixed(4)}) & Maps link"
                      : "Copy to clipboard for SMS or other apps",
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 14),
                onTap: () {
                  final message = buildMessage(useCoordinates: true);
                  Clipboard.setData(ClipboardData(text: message));
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("✅ Address and Google Maps link copied to clipboard!"),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
              ),
            ];

            // Option 3: Direct Maps Launch with Exact Coordinates
            if (latVal != null && lngVal != null) {
              items.add(const Divider(color: Color(0xFF2C2C2E)));
              items.add(
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFFF9F0A),
                    child: Icon(Icons.my_location, color: Colors.white),
                  ),
                  title: const Text("Open Exact Coordinates in Maps", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    "Target: ${latVal!.toStringAsFixed(6)}, ${lngVal!.toStringAsFixed(6)}",
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  trailing: const Icon(Icons.open_in_new, color: Colors.grey, size: 14),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final uri = Uri.parse("https://www.google.com/maps/search/?api=1&query=$latVal,$lngVal");
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  },
                ),
              );
            }

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: items,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // =====================================
  // SHARE PACKING LIST WITH PACKING TEAM
  // =====================================

  void _sharePackingList(OrderModel order) {
    final StringBuffer buffer = StringBuffer();
    buffer.writeln("📦 *ORDER PACKING LIST*");
    buffer.writeln("🆔 *Order ID:* #${order.orderCode}");
    if (order.customerName.trim().isNotEmpty) {
      buffer.writeln("👤 *Customer:* ${order.customerName.trim()}");
    }
    if (order.phoneNumber.trim().isNotEmpty) {
      final cleanPhone = order.phoneNumber.split("|")[0].replaceAll("(Alt)", "").trim();
      buffer.writeln("📞 *Phone:* $cleanPhone");
    }
    buffer.writeln("📅 *Date:* ${_formatDate(order.createdAt)}");
    buffer.writeln("");
    buffer.writeln("📋 *ITEMS TO PACK:*");
    buffer.writeln("----------------------------------");

    int totalQty = 0;
    for (int i = 0; i < order.items.length; i++) {
      final item = order.items[i];
      buffer.writeln("${i + 1}️⃣ *${item.productName}*");
      buffer.writeln("   • *Quantity:* ${item.quantity}");
      totalQty += item.quantity;
    }
    buffer.writeln("----------------------------------");
    buffer.writeln("📦 *Total Quantity:* $totalQty item${totalQty == 1 ? '' : 's'}");
    buffer.writeln("💰 *Total Order Value:* ₹${order.totalAmount.toStringAsFixed(2)}");
    if (order.shippingAddress.trim().isNotEmpty) {
      buffer.writeln("📍 *Delivery Address:* ${order.shippingAddress}");
    }

    final message = buffer.toString();

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade600,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.inventory_2_outlined, color: Color(0xFFFF9F0A), size: 24),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Send Packing Slip (#${order.orderCode})",
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  "Send product list and quantities directly to your order packing team.",
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 16),
                // WhatsApp Share
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFF25D366),
                    child: Icon(Icons.chat_bubble_outline, color: Colors.white),
                  ),
                  title: const Text("Share via WhatsApp", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  subtitle: const Text("Send to Packing Team contact or WhatsApp group", style: TextStyle(color: Colors.grey, fontSize: 12)),
                  trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 14),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final waUrl = "https://wa.me/?text=${Uri.encodeComponent(message)}";
                    final uri = Uri.parse(waUrl);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  },
                ),
                const Divider(color: Color(0xFF2C2C2E)),
                // Copy Option
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFF0A84FF),
                    child: Icon(Icons.copy, color: Colors.white),
                  ),
                  title: const Text("Copy Packing Slip Text", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  subtitle: const Text("Copy items & quantities to clipboard", style: TextStyle(color: Colors.grey, fontSize: 12)),
                  trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 14),
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: message));
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("✅ Packing slip copied to clipboard!"),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // =====================================
  // UPDATE STATUS
  // =====================================

  Future<void> _updateStatus({
    required int orderId,
    required String status,
  }) async {
    // In-memory optimistic update to prevent page scrolling/resetting
    if (_cachedOrders != null) {
      final index = _cachedOrders!.indexWhere((o) => o.orderId == orderId);
      if (index != -1) {
        _cachedOrders![index] = _cachedOrders![index].copyWith(orderStatus: status);
        setState(() {});
      }
    }

    try {
      await _service.updateOrderStatus(
        orderId: orderId,
        status: status,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Order updated to $status"),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to update status"),
        ),
      );
      _loadOrders(silent: true);
    }
  }

  // =====================================
  // STATUS COLOR
  // =====================================

  Color _statusColor(String status) {

    switch (status) {

      case "CREATED":
        return Colors.grey;

      case "CONFIRMED":
        return Colors.orange;

      case "OUT_FOR_DELIVERY":
        return Colors.blue;

      case "DELIVERED":
        return Colors.green;

      case "CANCELLED":
        return Colors.red;

      default:
        return Colors.black;
    }
  }

  // =====================================
  // FORMAT DATE
  // =====================================

  String _formatDate(DateTime date) {
    final localDate = date.toLocal();
    return "${localDate.day}/${localDate.month}/${localDate.year}";
  }

  bool _isToday(DateTime date) {
    final localDate = date.toLocal();
    final now = DateTime.now();

    return localDate.day == now.day &&
        localDate.month == now.month &&
        localDate.year == now.year;
  }

  bool _isThisWeek(DateTime date) {
    final localDate = date.toLocal();
    final now = DateTime.now();

    final difference =
        now.difference(localDate).inDays;

    return difference >= 0 &&
        difference < 7;
  }

  bool _isThisMonth(DateTime date) {
    final localDate = date.toLocal();
    final now = DateTime.now();

    return localDate.month == now.month &&
        localDate.year == now.year;
  }

  Future<void> _handleRefresh() async {
    _loadOrders(silent: true);
    await Future.delayed(const Duration(milliseconds: 600));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Orders Management"),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const DeletedProductsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          if (_isLoading && _cachedOrders == null) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (_errorMessage != null && _cachedOrders == null) {
            return RefreshIndicator(
              onRefresh: _handleRefresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.7,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                            const SizedBox(height: 12),
                            Text(
                              "Error: $_errorMessage",
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white70, fontSize: 13),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () => _loadOrders(),
                              icon: const Icon(Icons.refresh, size: 16),
                              label: const Text("Retry"),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          if (_cachedOrders == null || _cachedOrders!.isEmpty) {
            return RefreshIndicator(
              onRefresh: _handleRefresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.7,
                    child: const Center(
                      child: Text("No Orders Found", style: TextStyle(color: Colors.white70)),
                    ),
                  ),
                ],
              ),
            );
          }

          final orders = _cachedOrders!.reversed.toList();

          // Sync controllers with loaded data to prevent text resetting on typing
          for (var order in orders) {
            if (!_deliveryNameControllers.containsKey(order.orderId)) {
              _deliveryNameControllers[order.orderId] = TextEditingController(text: order.deliveryBoyName);
            } else if (_deliveryNameControllers[order.orderId]!.text != order.deliveryBoyName &&
                       !FocusScope.of(context).hasFocus) {
              _deliveryNameControllers[order.orderId]!.text = order.deliveryBoyName ?? "";
            }

            if (!_deliveryPhoneControllers.containsKey(order.orderId)) {
              _deliveryPhoneControllers[order.orderId] = TextEditingController(text: order.deliveryBoyPhone);
            } else if (_deliveryPhoneControllers[order.orderId]!.text != order.deliveryBoyPhone &&
                       !FocusScope.of(context).hasFocus) {
              _deliveryPhoneControllers[order.orderId]!.text = order.deliveryBoyPhone ?? "";
            }
          }

          // =====================================
          // STATS
          // =====================================

          final totalOrders =
              orders.length;

          final pendingOrders =
              orders.where((o) =>
              o.orderStatus != "DELIVERED")
                  .length;

          final deliveredOrders =
              orders.where((o) =>
              o.orderStatus == "DELIVERED")
                  .length;

          final todayOrders = orders
              .where((o) =>
              _isToday(o.createdAt))
              .length;

          final weeklyOrders = orders
              .where((o) =>
              _isThisWeek(o.createdAt))
              .length;

          final monthlyOrders = orders
              .where((o) =>
              _isThisMonth(o.createdAt))
              .length;

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 850),
              child: RefreshIndicator(
                onRefresh: () async {
                  setState(() {
                    _loadOrders();
                  });
                },

            child: ListView(

              padding:
              const EdgeInsets.all(16),

              children: [

                const Text(

                  "Business Analytics",

                  style: TextStyle(
                    fontSize: 28,
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 20),

                // =====================================
                // OVERVIEW CARDS
                // =====================================

                GridView.count(

                  crossAxisCount: 2,

                  shrinkWrap: true,

                  physics:
                  const NeverScrollableScrollPhysics(),

                  crossAxisSpacing: 12,

                  mainAxisSpacing: 12,

                  childAspectRatio: 1.15,

                  children: [

                    _buildCard(
                      title: "Total Orders",
                      value:
                      totalOrders.toString(),
                      icon:
                      Icons.shopping_bag,
                      color: Colors.blue,
                    ),

                    _buildCard(
                      title: "Pending",
                      value:
                      pendingOrders.toString(),
                      icon:
                      Icons.pending_actions,
                      color: Colors.orange,
                    ),

                    _buildCard(
                      title: "Delivered",
                      value:
                      deliveredOrders.toString(),
                      icon:
                      Icons.check_circle,
                      color: Colors.green,
                    ),

                    _buildCard(
                      title: "Today Orders",
                      value:
                      todayOrders.toString(),
                      icon:
                      Icons.today,
                      color: Colors.teal,
                    ),

                    _buildCard(
                      title: "Weekly Orders",
                      value:
                      weeklyOrders.toString(),
                      icon:
                      Icons.bar_chart,
                      color: Colors.indigo,
                    ),

                    _buildCard(
                      title: "Monthly Orders",
                      value:
                      monthlyOrders.toString(),
                      icon:
                      Icons.calendar_month,
                      color: Colors.deepOrange,
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                // =====================================
                // CHART
                // =====================================

                const Text(

                  "Orders Analytics",

                  style: TextStyle(
                    fontSize: 22,
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 20),

                Container(

                  height: 260,

                  padding:
                  const EdgeInsets.all(16),

                  decoration: BoxDecoration(

                    color: Colors.white,

                    borderRadius:
                    BorderRadius.circular(20),

                    boxShadow: [

                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                      ),
                    ],
                  ),

                  child: BarChart(

                    BarChartData(

                      alignment:
                      BarChartAlignment.spaceAround,

                      maxY: [
                        todayOrders.toDouble(),
                        weeklyOrders.toDouble(),
                        monthlyOrders.toDouble(),
                      ].reduce((a, b) => a > b ? a : b) + 5,

                      borderData:
                      FlBorderData(show: false),

                      gridData:
                      FlGridData(show: true),

                      titlesData: FlTitlesData(

                        topTitles:
                        AxisTitles(
                          sideTitles:
                          SideTitles(showTitles: false),
                        ),

                        rightTitles:
                        AxisTitles(
                          sideTitles:
                          SideTitles(showTitles: false),
                        ),

                        leftTitles:
                        AxisTitles(
                          sideTitles:
                          SideTitles(showTitles: true),
                        ),

                        bottomTitles: AxisTitles(

                          sideTitles: SideTitles(

                            showTitles: true,

                            getTitlesWidget:
                                (value, meta) {

                              switch (value.toInt()) {

                                case 0:
                                  return const Text("Today");

                                case 1:
                                  return const Text("Week");

                                case 2:
                                  return const Text("Month");
                              }

                              return const Text("");
                            },
                          ),
                        ),
                      ),

                      barGroups: [

                        BarChartGroupData(

                          x: 0,

                          barRods: [

                            BarChartRodData(
                              toY:
                              todayOrders.toDouble(),
                              width: 30,
                              color: Colors.teal,
                              borderRadius:
                              BorderRadius.circular(6),
                            ),
                          ],
                        ),

                        BarChartGroupData(

                          x: 1,

                          barRods: [

                            BarChartRodData(
                              toY:
                              weeklyOrders.toDouble(),
                              width: 30,
                              color: Colors.indigo,
                              borderRadius:
                              BorderRadius.circular(6),
                            ),
                          ],
                        ),

                        BarChartGroupData(

                          x: 2,

                          barRods: [

                            BarChartRodData(
                              toY:
                              monthlyOrders.toDouble(),
                              width: 30,
                              color: Colors.deepOrange,
                              borderRadius:
                              BorderRadius.circular(6),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                const Text(

                  "Manage Orders",

                  style: TextStyle(
                    fontSize: 22,
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 16),

                ...orders.map((order) {
                  final deliveryNameController = _deliveryNameControllers[order.orderId]!;
                  final deliveryPhoneController = _deliveryPhoneControllers[order.orderId]!;
                  final totalItemsCount = order.items.fold<int>(0, (sum, item) => sum + item.quantity);

                  final parts = order.phoneNumber.split("| Acct:");
                  final deliveryPhone = parts[0].replaceAll("(Alt)", "").trim();
                  final accountPhone = parts.length > 1 ? parts[1].trim() : "";

                  final List<String> defaultStatuses = [
                    "CREATED",
                    "CONFIRMED",
                    "OUT_FOR_DELIVERY",
                    "DELIVERED",
                    "CANCELLED"
                  ];
                  final List<String> dropdownItems = List.from(defaultStatuses);
                  final rawStatus = order.orderStatus.trim();
                  if (rawStatus.isNotEmpty && !dropdownItems.contains(rawStatus)) {
                    dropdownItems.add(rawStatus);
                  }
                  final String currentStatusValue = dropdownItems.contains(rawStatus)
                      ? rawStatus
                      : dropdownItems.first;

                  return Card(
                    margin: const EdgeInsets.only(
                      bottom: 16,
                    ),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(
                        color: Color(0xFF2C2C2E),
                        width: 0.5,
                      ),
                    ),
                    child: ExpansionTile(
                      shape: const Border(),
                      collapsedShape: const Border(),
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              "Order #${order.orderCode}",
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF9F0A).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFFF9F0A).withOpacity(0.3), width: 0.5),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.inventory_2_outlined, color: Color(0xFFFF9F0A), size: 12),
                                const SizedBox(width: 4),
                                Text(
                                  "$totalItemsCount Item${totalItemsCount == 1 ? '' : 's'}",
                                  style: const TextStyle(color: Color(0xFFFF9F0A), fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 6),
                          Text(
                            _formatDate(
                              order.createdAt,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                "Total Amount: ₹${order.totalAmount.toStringAsFixed(2)}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Color(0xFF30D158),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _statusColor(
                                    order.orderStatus,
                                  ).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  order.orderStatus,
                                  style: TextStyle(
                                    color: _statusColor(
                                      order.orderStatus,
                                    ),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // 📦 Quick Action Button for Packing Team
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFFF9F0A),
                              side: const BorderSide(color: Color(0xFFFF9F0A), width: 0.8),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            icon: const Icon(Icons.inventory_2_outlined, size: 14),
                            label: Text(
                              "Send to Packing Team ($totalItemsCount items)",
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                            onPressed: () => _sharePackingList(order),
                          ),
                        ],
                      ),

                      children: [

                        Container(

                          width: double.infinity,

                          margin: const EdgeInsets.all(16),

                          padding: const EdgeInsets.all(16),

                          decoration: BoxDecoration(

                            color: Colors.blue.withOpacity(0.08),

                            borderRadius: BorderRadius.circular(12),

                            border: Border.all(
                              color: Colors.blue.withOpacity(0.25),
                            ),
                          ),

                          child: Column(

                            crossAxisAlignment:
                            CrossAxisAlignment.start,

                            children: [

                              const Row(

                                children: [

                                  Icon(
                                    Icons.person,
                                    color: Colors.blue,
                                  ),

                                  SizedBox(width: 8),

                                  Text(

                                    "Customer Details",

                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 16),

                              if (order.customerName.isNotEmpty) ...[
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.account_circle,
                                      size: 18,
                                      color: Color(0xFF0A84FF),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        order.customerName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                              ],

                              if (order.phoneNumber.contains("| Acct:") || order.phoneNumber.contains("(Alt)")) ...[
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.phone_in_talk,
                                          size: 18,
                                          color: Color(0xFF30D158),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Text(
                                                    deliveryPhone,
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFF30D158).withOpacity(0.15),
                                                      borderRadius: BorderRadius.circular(4),
                                                      border: Border.all(color: const Color(0xFF30D158), width: 0.5),
                                                    ),
                                                    child: const Text(
                                                      "Call for Delivery",
                                                      style: TextStyle(
                                                        color: Color(0xFF30D158),
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              if (accountPhone.isNotEmpty) ...[
                                                const SizedBox(height: 3),
                                                Text(
                                                  "Account Phone: $accountPhone",
                                                  style: const TextStyle(
                                                    color: Color(0xFF8E8E93),
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ] else ...[
                                Row(
                                  children: [

                                    const Icon(
                                      Icons.phone,
                                      size: 18,
                                      color: Colors.green,
                                    ),

                                    const SizedBox(width: 8),

                                    Expanded(
                                      child: Text(
                                        order.phoneNumber,
                                      ),
                                    ),
                                  ],
                                ),
                              ],

                              const SizedBox(height: 12),

                              Row(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,

                                children: [

                                  const Icon(
                                    Icons.location_on,
                                    size: 18,
                                    color: Colors.red,
                                  ),

                                  const SizedBox(width: 8),

                                  Expanded(
                                    child: Text(
                                      order.shippingAddress,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 8),

                              // 🗺️ LOCATION ACTIONS: OPEN IN MAPS & SHARE WITH RIDER
                              Padding(
                                padding: const EdgeInsets.only(left: 26),
                                child: Wrap(
                                  spacing: 8,
                                  runSpacing: 6,
                                  children: [
                                    OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: const Color(0xFF0A84FF),
                                        side: const BorderSide(color: Color(0xFF0A84FF), width: 0.8),
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        minimumSize: Size.zero,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      icon: const Icon(Icons.map_outlined, size: 14),
                                      label: const Text("Open in Maps", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                      onPressed: () => _openGoogleMaps(
                                        address: order.shippingAddress,
                                        pincode: order.pincode,
                                      ),
                                    ),
                                    OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: const Color(0xFF30D158),
                                        side: const BorderSide(color: Color(0xFF30D158), width: 0.8),
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        minimumSize: Size.zero,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      icon: const Icon(Icons.share_location_outlined, size: 14),
                                      label: const Text("Share with Rider", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                      onPressed: () => _shareDeliveryDetails(order),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 12),

                              Row(
                                children: [

                                  const Icon(
                                    Icons.pin_drop,
                                    size: 18,
                                    color: Colors.orange,
                                  ),

                                  const SizedBox(width: 8),

                                  Text(
                                    order.pincode,
                                  ),
                                ],
                              ),

                              const SizedBox(height: 12),

                              Row(
                                children: [

                                  const Icon(
                                    Icons.payment,
                                    size: 18,
                                    color: Colors.purple,
                                  ),

                                  const SizedBox(width: 8),

                                  Text(
                                    order.paymentStatus,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 12),

                              Row(
                                children: [
                                  const Icon(
                                    Icons.receipt_long,
                                    size: 18,
                                    color: Color(0xFF30D158),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    "Total Amount: ₹${order.totalAmount.toStringAsFixed(2)}",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Color(0xFF30D158),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                          ),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              const Text(
                                "Ordered Products",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFF9F0A).withOpacity(0.2),
                                  foregroundColor: const Color(0xFFFF9F0A),
                                  side: const BorderSide(color: Color(0xFFFF9F0A), width: 0.8),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                icon: const Icon(Icons.send_to_mobile, size: 14),
                                label: const Text(
                                  "Send to Packing Team",
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                                onPressed: () => _sharePackingList(order),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 10),

                        ...order.items.map((item) {

                          return ListTile(

                            leading: const CircleAvatar(
                              child: Icon(Icons.inventory_2),
                            ),

                            title: Text(
                              item.productName,
                            ),

                            subtitle: Text(
                              "₹${item.price} x ${item.quantity}",
                            ),

                            trailing: Text(
                              "₹${item.price * item.quantity}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        }),

                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2C2C2E),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(0xFF3A3A3C),
                              width: 0.5,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Total Order Amount",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                "₹${order.totalAmount.toStringAsFixed(2)}",
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF30D158),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const Divider(),

                        Padding(

                          padding: const EdgeInsets.all(16),

                          child: Column(

                            children: [

                              TextField(

                                controller: deliveryNameController,

                                decoration: const InputDecoration(

                                  labelText: "Delivery Boy Name",
                                ),
                              ),

                              const SizedBox(height: 12),

                              TextField(

                                controller: deliveryPhoneController,

                                keyboardType: TextInputType.phone,

                                decoration: const InputDecoration(

                                  labelText: "Delivery Boy Phone",
                                ),
                              ),

                              const SizedBox(height: 12),

                              SizedBox(

                                width: double.infinity,

                                child: ElevatedButton.icon(

                                  icon: const Icon(
                                    Icons.delivery_dining,
                                  ),

                                  label: const Text(
                                    "Assign Delivery Boy",
                                  ),

                                  onPressed: () async {
                                    final name = deliveryNameController.text;
                                    final phone = deliveryPhoneController.text;

                                    if (_cachedOrders != null) {
                                      final index = _cachedOrders!.indexWhere((o) => o.orderId == order.orderId);
                                      if (index != -1) {
                                        _cachedOrders![index] = _cachedOrders![index].copyWith(
                                          deliveryBoyName: name,
                                          deliveryBoyPhone: phone,
                                        );
                                        setState(() {});
                                      }
                                    }

                                    try {
                                      await _service.assignDeliveryBoy(
                                        orderId: order.orderId,
                                        deliveryBoyName: name,
                                        deliveryBoyPhone: phone,
                                      );

                                      if (!mounted) return;

                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text("Delivery boy assigned"),
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                    } catch (e) {
                                      if (!mounted) return;

                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text("Assignment failed"),
                                        ),
                                      );
                                      _loadOrders(silent: true);
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),

                        const Divider(),

                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: DropdownButtonFormField<String>(
                            value: currentStatusValue,
                            decoration: const InputDecoration(
                              labelText: "Update Status",
                            ),
                            items: dropdownItems.map((status) {
                              return DropdownMenuItem(
                                value: status,
                                child: Text(status),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value == null) return;
                              _updateStatus(
                                orderId: order.orderId,
                                status: value,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      );
    },
  ),
);
}

  // =====================================
  // CARD
  // =====================================

  Widget _buildCard({

    required String title,

    required String value,

    required IconData icon,

    required Color color,

  }) {

    return Container(

      padding:
      const EdgeInsets.all(16),

      decoration: BoxDecoration(

        color: const Color(0xFF1C1C1E), // Apple System Gray 6 card color

        borderRadius:
        BorderRadius.circular(12), // Consistent with global card rounding

        border: Border.all(
          color: color.withOpacity(0.2), // Accent category color border
          width: 0.8,
        ),
      ),

      child: Column(

        crossAxisAlignment:
        CrossAxisAlignment.start,

        mainAxisAlignment:
        MainAxisAlignment.spaceBetween,

        children: [

          Icon(
            icon,
            color: color,
            size: 32,
          ),

          Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,

            children: [

              Text(
                value,

                style: TextStyle(
                  fontSize: 22,
                  fontWeight:
                  FontWeight.bold,
                  color: color,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                title,
                style: const TextStyle(
                  fontWeight:
                  FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}