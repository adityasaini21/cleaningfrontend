import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/order.dart';
import '../models/product.dart';
import '../services/order_history_service.dart';
import '../services/cart_provider.dart';
import 'dart:async';
import '../services/notification_service.dart';
import 'package:url_launcher/url_launcher.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {

  final OrderHistoryService _service = OrderHistoryService();

  late Future<List<OrderModel>> _orders;

  StreamSubscription? _notificationSubscription;

  Timer? _timer;

  DateTime _now = DateTime.now();

  bool _isCancelling = false;

  @override
  void initState() {
    super.initState();

    _loadOrders();



    _timer = Timer.periodic(
      const Duration(seconds: 1),
          (_) {
        setState(() {
          _now = DateTime.now();
        });
      },
    );

    _notificationSubscription =
        NotificationService.notificationStream.listen((_) {

          setState(() {
            _loadOrders();
          });
        });
  }


  @override
  void dispose() {

    _timer?.cancel();

    _notificationSubscription?.cancel();

    super.dispose();
  }

  void _loadOrders() {
    _orders = _service.fetchMyOrders();
  }
  Future<void> _callDeliveryBoy(String phone) async {

    final Uri uri = Uri(
      scheme: 'tel',
      path: phone,
    );

    if (await canLaunchUrl(uri)) {

      await launchUrl(uri);

    } else {

      throw Exception("Could not launch phone dialer");
    }
  }

  // ====================================
  // 🔥 REORDER
  // ====================================
  void _reorder(OrderModel order) {

    final cart = context.read<CartProvider>();

    for (var item in order.items) {

      Product product = Product(

        id: item.productId,

        name: item.productName,

        description: "",

        price: item.price,

        costPrice: item.price,

        stock: 999,

        imageUrl: "",

        categoryId: 0,

        categoryName: "",

        averageRating: 0.0,

        reviewCount: 0,
      );

      cart.addToCartWithQuantity(
        product,
        item.quantity,
      );
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Items added to cart"),
      ),
    );
  }

  // ====================================
  // CANCEL ORDER
  // ====================================
  Future<void> _cancelOrder(int orderId) async {

    final confirm = await showDialog(
      context: context,
      builder: (context) {

        return AlertDialog(
          title: const Text("Cancel Order"),

          content: const Text(
            "Are you sure you want to cancel this order?",
          ),

          actions: [

            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text("No"),
            ),

            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text("Yes"),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    setState(() {
      _isCancelling = true;
    });

    try {

      await _service.cancelOrder(orderId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Order cancelled"),
        ),
      );

      setState(() {
        _loadOrders();
      });

    } catch (e) {

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Cancel failed"),
        ),
      );
    }

    if (!mounted) return;

    setState(() {
      _isCancelling = false;
    });
  }

  // ====================================
  // CANCEL TIMER
  // ====================================
  Duration _remainingCancelTime(OrderModel order) {

    final diff =
    _now.difference(order.createdAt);

    final remaining =
        const Duration(minutes: 1) - diff;

    return remaining.isNegative
        ? Duration.zero
        : remaining;
  }

  bool _canCancel(OrderModel order) {

    return order.orderStatus != "DELIVERED" &&
        order.orderStatus != "CANCELLED" &&
        _remainingCancelTime(order).inSeconds > 0;
  }

  String _formatCountdown(Duration duration) {

    final seconds = duration.inSeconds;

    final min = seconds ~/ 60;

    final sec = seconds % 60;

    return
      "${min.toString().padLeft(2, '0')}:"
          "${sec.toString().padLeft(2, '0')}";
  }

  // ====================================
  // ETA
  // ====================================
  Duration _remainingDeliveryTime(OrderModel order) {

    final estimatedDeliveryTime =
    order.createdAt.add(
      const Duration(minutes: 30),
    );

    final remaining =
    estimatedDeliveryTime.difference(_now);

    return remaining.isNegative
        ? Duration.zero
        : remaining;
  }

  String _formatETA(Duration duration) {

    return "Arriving in ${duration.inMinutes} min";
  }

  bool _showETA(OrderModel order) {

    return order.orderStatus != "DELIVERED" &&
        order.orderStatus != "CANCELLED";
  }

  // ====================================
  // PROGRESS BAR
  // ====================================
  Widget _buildProgressBar(String status) {

    if (status == "CANCELLED") {

      return Column(
        children: [

          const SizedBox(height: 10),

          LinearProgressIndicator(
            value: 0.3,
            color: Colors.red,
            backgroundColor:
            Colors.grey.shade300,
          ),

          const SizedBox(height: 6),

          const Text(
            "Order Cancelled",
            style: TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      );
    }

    List<String> steps = [

      "CREATED",

      "CONFIRMED",

      "OUT_FOR_DELIVERY",

      "DELIVERED"
    ];

    int currentIndex =
    steps.indexOf(status);

    if (currentIndex == -1) {
      currentIndex = 0;
    }

    double progress =
        (currentIndex + 1) / steps.length;

    return Column(
      children: [

        TweenAnimationBuilder<double>(

          tween: Tween(
            begin: 0,
            end: progress,
          ),

          duration:
          const Duration(milliseconds: 800),

          builder: (context, value, _) {

            return LinearProgressIndicator(
              value: value,
              minHeight: 4,
              backgroundColor:
              Colors.grey.shade300,
              color: Colors.green,
            );
          },
        ),

        const SizedBox(height: 8),

        Row(
          mainAxisAlignment:
          MainAxisAlignment.spaceBetween,

          children: [

            _buildStepIcon(
              Icons.shopping_bag,
              currentIndex >= 0,
            ),

            _buildStepIcon(
              Icons.check_circle,
              currentIndex >= 1,
            ),

            _buildStepIcon(
              Icons.local_shipping,
              currentIndex >= 2,
            ),

            _buildStepIcon(
              Icons.home,
              currentIndex >= 3,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStepIcon(
      IconData icon,
      bool active,
      ) {

    return AnimatedContainer(

      duration:
      const Duration(milliseconds: 300),

      padding: const EdgeInsets.all(4),

      decoration: BoxDecoration(
        color: active
            ? Colors.green
            : Colors.grey.shade300,

        shape: BoxShape.circle,
      ),

      child: Icon(
        icon,
        size: 12,
        color:
        active
            ? Colors.white
            : Colors.grey,
      ),
    );
  }

  // ====================================
  // TIMELINE
  // ====================================
  Widget _buildTrackingTimeline(String status) {

    if (status == "CANCELLED") {

      return Column(
        children: const [

          Row(
            children: [

              Icon(
                Icons.check_circle,
                color: Colors.green,
              ),

              SizedBox(width: 10),

              Text(
                "Order Placed",

                style: TextStyle(
                  fontWeight:
                  FontWeight.bold,
                ),
              ),
            ],
          ),

          SizedBox(height: 10),

          Row(
            children: [

              Icon(
                Icons.cancel,
                color: Colors.red,
              ),

              SizedBox(width: 10),

              Text(
                "Order Cancelled",

                style: TextStyle(
                  color: Colors.red,
                  fontWeight:
                  FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      );
    }

    List<Map<String, dynamic>> steps = [

      {
        "title": "Order Placed",
        "status": "CREATED"
      },

      {
        "title": "Confirmed",
        "status": "CONFIRMED"
      },

      {
        "title": "Out for Delivery",
        "status": "OUT_FOR_DELIVERY"
      },

      {
        "title": "Delivered",
        "status": "DELIVERED"
      },
    ];

    int currentIndex =
    steps.indexWhere(
            (s) => s["status"] == status);

    if (currentIndex == -1) {
      currentIndex = 0;
    }

    return Column(
      children: List.generate(
        steps.length,
            (index) {

          bool isCompleted =
              index <= currentIndex;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.0),
            child: Row(
              children: [

                Icon(
                  Icons.radio_button_checked,

                  color:
                  isCompleted
                      ? Colors.green
                      : Colors.grey,

                  size: 12,
                ),

                const SizedBox(width: 8),

                Text(
                  steps[index]["title"],

                  style: TextStyle(
                    fontSize: 12,
                    color: isCompleted ? Colors.white : Colors.white70,
                    fontWeight:
                    isCompleted
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {

    return
      "${date.day}/"
          "${date.month}/"
          "${date.year}";
  }

  String _formatTime(DateTime date) {

    int hour =
    date.hour > 12
        ? date.hour - 12
        : date.hour;

    String period =
    date.hour >= 12
        ? "PM"
        : "AM";

    String minute =
    date.minute.toString().padLeft(2, '0');

    return "$hour:$minute $period";
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text("My Orders"),
      ),

      body: FutureBuilder<List<OrderModel>>(

        future: _orders,

        builder: (context, snapshot) {

          if (snapshot.connectionState ==
              ConnectionState.waiting) {

            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {

            return Center(
              child: Text(
                "Error: ${snapshot.error}",
              ),
            );
          }

          final orders =
          snapshot.data!.reversed.toList();

          return ListView.builder(

            itemCount: orders.length,

            itemBuilder: (context, index) {

              final order = orders[index];

              print("Delivery Name = ${order.deliveryBoyName}");
              print("Delivery Phone = ${order.deliveryBoyPhone}");

              final cancelRemaining =
              _remainingCancelTime(order);

              final deliveryRemaining =
              _remainingDeliveryTime(order);

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1C1E),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF2C2C2E), width: 0.5),
                ),
                child: Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                    childrenPadding: const EdgeInsets.only(bottom: 6),
                    title: Text(
                      "Order #${order.orderId}",
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                    ),

                  subtitle: Column(

                    crossAxisAlignment:
                    CrossAxisAlignment.start,

                    children: [

                      Text(
                        "${_formatDate(order.createdAt)} • ${_formatTime(order.createdAt)}",
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),

                      const SizedBox(height: 2),

                      Text(
                        "Total: ₹${order.totalAmount}",
                        style: const TextStyle(fontSize: 11, color: Colors.white70),
                      ),

                      if (_showETA(order))
                        Text(
                          _formatETA(
                              deliveryRemaining),

                          style: const TextStyle(
                            color: Colors.blue,
                            fontSize: 11,
                            fontWeight:
                            FontWeight.bold,
                          ),
                        ),

                      if (_canCancel(order))
                        Text(
                          "Cancel in ${_formatCountdown(cancelRemaining)}",

                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 11,
                            fontWeight:
                            FontWeight.bold,
                          ),
                        ),
                    ],
                  ),

                  children: [

                    Padding(
                      padding:
                      const EdgeInsets.fromLTRB(12, 10, 12, 8),

                      child: _buildProgressBar(
                        order.orderStatus,
                      ),
                    ),

                    const Padding(
                      padding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 4),

                      child: Text(
                        "Order Tracking",

                        style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                          FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                      ),
                      child: _buildTrackingTimeline(
                        order.orderStatus,
                      ),
                    ),

                    if (order.deliveryBoyName.isNotEmpty) ...[

                      const SizedBox(height: 10),

                      Container(

                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                        ),

                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),

                        decoration: BoxDecoration(

                          color: Colors.green.withOpacity(0.08),

                          borderRadius:
                          BorderRadius.circular(8),

                          border: Border.all(
                            color: Colors.green.withOpacity(0.3),
                          ),
                        ),

                        child: Column(

                          crossAxisAlignment:
                          CrossAxisAlignment.start,

                          children: [

                            const Row(

                              children: [

                                Icon(
                                  Icons.delivery_dining,
                                  color: Colors.green,
                                  size: 18,
                                ),

                                SizedBox(width: 6),

                                Text(

                                  "Delivery Partner",

                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 6),

                            Text(
                              "Name: ${order.deliveryBoyName}",
                              style: const TextStyle(fontSize: 12),
                            ),

                            const SizedBox(height: 4),

                            Row(

                              children: [

                                Expanded(

                                  child: Text(
                                    "Phone: ${order.deliveryBoyPhone}",
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),

                                SizedBox(
                                  height: 28,
                                  child: ElevatedButton.icon(

                                    onPressed: () {

                                      _callDeliveryBoy(
                                        order.deliveryBoyPhone,
                                      );
                                    },

                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 10),
                                      textStyle: const TextStyle(fontSize: 11),
                                    ),

                                    icon: const Icon(Icons.call, size: 12),

                                    label: const Text("Call"),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 10),

                    ...order.items.map((item) {

                      return ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),

                        title:
                        Text(item.productName, style: const TextStyle(fontSize: 13)),

                        subtitle: Text(
                          "₹${item.price} x ${item.quantity}",
                          style: const TextStyle(fontSize: 11),
                        ),
                      );
                    }),

                    // 🔥 REORDER
                    Padding(
                      padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),

                      child: SizedBox(
                        width: double.infinity,
                        height: 34,

                        child:
                        ElevatedButton.icon(

                          onPressed: () {
                            _reorder(order);
                          },

                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),

                          icon: const Icon(
                            Icons.refresh,
                            size: 16,
                          ),

                          label: const Text(
                            "Reorder",
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                      ),
                    ),

                    // CANCEL BUTTON
                    if (_canCancel(order))
                      Padding(
                        padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),

                        child: SizedBox(
                          width: double.infinity,
                          height: 34,
                          child: ElevatedButton(

                            style:
                            ElevatedButton.styleFrom(
                              backgroundColor:
                              Colors.red,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),

                            onPressed:
                            _isCancelling
                                ? null
                                : () {
                              _cancelOrder(
                                order.orderId,
                              );
                            },

                            child:
                            _isCancelling
                                ? const SizedBox(
                                    height: 16,
                                    width: 16,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                              "Cancel Order",
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
            },
          );
        },
      ),
    );
  }
}