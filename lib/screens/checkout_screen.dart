import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/cart_provider.dart';
import '../services/order_service.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';
import 'order_success_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() =>
      _CheckoutScreenState();
}

class _CheckoutScreenState
    extends State<CheckoutScreen> {

  final _addressController =
  TextEditingController();

  final _phoneController =
  TextEditingController();

  final _pincodeController =
  TextEditingController();

  final OrderService _orderService =
  OrderService();

  String _paymentMethod = "ONLINE";

  bool _loading = false;

  bool _isDeliverable = false;

  String _deliveryMessage = "";

  // =========================================
  // CHECK PINCODE
  // =========================================

  Future<void> _checkDelivery() async {

    final pincode =
    _pincodeController.text.trim();

    if (pincode.isEmpty) return;

    final result =
    await _orderService.checkPincode(
      pincode,
    );

    setState(() {

      _isDeliverable = result;

      _deliveryMessage = result
          ? "Delivery available in your area"
          : "Sorry, delivery is not available in your area";
    });
  }

  void _showPaymentVerificationDialog(int orderId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        bool verifying = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1C1C1E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFF2C2C2E), width: 0.5),
              ),
              title: const Row(
                children: [
                  Icon(Icons.security, color: Color(0xFF30D158)),
                  SizedBox(width: 8),
                  Text("Online Payment", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (verifying) ...[
                    const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF30D158))),
                    const SizedBox(height: 16),
                    const Text("Verifying transaction status...", style: TextStyle(color: Colors.white70, fontSize: 14)),
                  ] else ...[
                    const Text(
                      "We have opened the payment gateway. Once you complete the payment in the browser/UPI app, return here and tap 'Verify Payment'.",
                      style: TextStyle(color: Color(0xFF8E8E93), fontSize: 14, height: 1.4),
                    ),
                  ],
                ],
              ),
              actions: [
                if (!verifying) ...[
                  TextButton(
                    onPressed: () {
                      Navigator.pop(dialogContext);
                    },
                    child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF30D158),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () async {
                      setDialogState(() {
                        verifying = true;
                      });

                      final isPaid = await _orderService.checkOrderPaid(orderId);

                      if (isPaid) {
                        final cart = Provider.of<CartProvider>(context, listen: false);
                        cart.clearCart();
                        if (!mounted) return;
                        Navigator.pop(dialogContext); // close dialog
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const OrderSuccessScreen(),
                          ),
                        );
                      } else {
                        setDialogState(() {
                          verifying = false;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Payment not received yet. If you paid, please wait a moment and try again."),
                            duration: Duration(seconds: 3),
                          ),
                        );
                      }
                    },
                    child: const Text("Verify Payment", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ],
            );
          },
        );
      },
    );
  }

  // =========================================
  // PLACE ORDER
  // =========================================

  Future<void> _placeOrder() async {

    final cart =
    context.read<CartProvider>();

    if (_addressController.text.isEmpty ||
        _phoneController.text.isEmpty ||
        _pincodeController.text.isEmpty) {

      ScaffoldMessenger.of(context)
          .showSnackBar(

        const SnackBar(
          content:
          Text("Fill all fields"),
        ),
      );

      return;
    }

    if (!_isDeliverable) {

      ScaffoldMessenger.of(context)
          .showSnackBar(

        const SnackBar(
          content: Text(
            "Delivery not available in this area",
          ),
        ),
      );

      return;
    }

    setState(() {
      _loading = true;
    });

    final orderId = await _orderService.placeOrder(
      shippingAddress: _addressController.text,
      phoneNumber: _phoneController.text,
      pincode: _pincodeController.text,
      paymentMethod: _paymentMethod,
      items: cart.items,
    );

    if (orderId == null) {
      setState(() {
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Order failed")),
      );
      return;
    }

    if (_paymentMethod == "ONLINE") {
      final redirectUrl = await _orderService.initiatePhonePePayment(orderId);
      
      setState(() {
        _loading = false;
      });

      if (redirectUrl == null) {
        cart.clearCart();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to initiate online payment. Order placed.")),
        );
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const OrderSuccessScreen(),
          ),
        );
        return;
      }

      try {
        final launchSuccess = await launchUrl(
          Uri.parse(redirectUrl),
          mode: LaunchMode.externalApplication,
        );

        if (!launchSuccess) {
          cart.clearCart();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Could not launch payment gateway. Order placed.")),
          );
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const OrderSuccessScreen(),
            ),
          );
          return;
        }

        if (!mounted) return;
        _showPaymentVerificationDialog(orderId);

      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error launching payment: $e")),
        );
      }
    } else {
      setState(() {
        _loading = false;
      });
      cart.clearCart();
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const OrderSuccessScreen(),
        ),
      );
    }
  }

  // =========================================
  // CARD WIDGET
  // =========================================

  Widget _sectionCard({
    required Widget child,
  }) {

    return Container(

      width: double.infinity,

      padding:
      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),

      decoration: BoxDecoration(

        color:
        const Color(0xFF111827),

        borderRadius:
        BorderRadius.circular(12),

        border: Border.all(

          color:
          Colors.white.withOpacity(0.08),
          width: 0.5,
        ),
      ),

      child: child,
    );
  }

  bool _useProfileDetails = false;

  Widget _buildProfileImportCard() {
    return _sectionCard(
      child: Row(
        children: [
          const Icon(Icons.account_circle, color: Color(0xFF0A84FF), size: 28),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Use Profile Details",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  "Autofill address & contact info",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: _useProfileDetails,
            activeColor: const Color(0xFF0A84FF),
            onChanged: (val) {
              setState(() {
                _useProfileDetails = val;
                if (_useProfileDetails) {
                  _importFromProfile();
                } else {
                  _clearFields();
                }
              });
            },
          ),
        ],
      ),
    );
  }

  Future<void> _importFromProfile() async {
    setState(() {
      _loading = true;
    });

    try {
      final profile = await ProfileService().fetchProfile();
      if (profile != null) {
        final addressParts = [
          if (profile.address != null && profile.address!.isNotEmpty) profile.address,
          if (profile.landmark != null && profile.landmark!.isNotEmpty) "Landmark: ${profile.landmark}",
          if (profile.city != null && profile.city!.isNotEmpty) profile.city,
          if (profile.state != null && profile.state!.isNotEmpty) profile.state,
        ];
        _addressController.text = addressParts.where((p) => p != null).join(", ");
        
        final phone = AuthService().getUsernameFromToken() ?? '';
        _phoneController.text = phone;
        
        if (profile.pincode != null && profile.pincode!.isNotEmpty) {
          _pincodeController.text = profile.pincode!;
          await _checkDelivery();
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to load profile details")),
        );
        setState(() {
          _useProfileDetails = false;
        });
      }
    } catch (e) {
      debugPrint("Error importing profile: $e");
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  void _clearFields() {
    _addressController.clear();
    _phoneController.clear();
    _pincodeController.clear();
    setState(() {
      _isDeliverable = false;
      _deliveryMessage = "";
    });
  }

  @override
  Widget build(BuildContext context) {

    final cart =
    context.watch<CartProvider>();

    return Scaffold(

      appBar: AppBar(

        title:
        const Text("Checkout"),

        centerTitle: true,
      ),

      body: SingleChildScrollView(

        padding:
        const EdgeInsets.fromLTRB(
          16,
          16,
          16,
          170,
        ),

        child: Column(

          crossAxisAlignment:
          CrossAxisAlignment.start,

          children: [
            _buildProfileImportCard(),
            const SizedBox(height: 16),

            // =====================================
            // ADDRESS
            // =====================================

            _sectionCard(

              child: Column(

                crossAxisAlignment:
                CrossAxisAlignment.start,

                children: [

                  const Row(

                    children: [

                      Icon(
                        Icons.location_on,
                      ),

                      SizedBox(width: 8),

                      Text(

                        "Shipping Address",

                        style: TextStyle(

                          fontSize: 16,

                          fontWeight:
                          FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  TextField(

                    controller:
                    _addressController,

                    maxLines: 3,

                    decoration:
                    InputDecoration(

                      hintText:
                      "Enter delivery address",

                      border:
                      OutlineInputBorder(

                        borderRadius:
                        BorderRadius.circular(
                          14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // =====================================
            // CONTACT INFO
            // =====================================

            _sectionCard(

              child: Column(

                children: [

                  TextField(

                    controller:
                    _phoneController,

                    keyboardType:
                    TextInputType.phone,

                    decoration:
                    InputDecoration(

                      labelText:
                      "Phone Number",

                      prefixIcon:
                      const Icon(Icons.phone),

                      border:
                      OutlineInputBorder(

                        borderRadius:
                        BorderRadius.circular(
                          14,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  TextField(

                    controller:
                    _pincodeController,

                    keyboardType:
                    TextInputType.number,

                    onChanged: (value) {
                      final val = value.trim();
                      if (val.length != 6) {
                        setState(() {
                          _isDeliverable = false;
                          _deliveryMessage = "Pincode must be exactly 6 digits";
                        });
                      } else {
                        _checkDelivery();
                      }
                    },

                    decoration:
                    InputDecoration(

                      labelText:
                      "Pincode",

                      prefixIcon:
                      const Icon(Icons.pin_drop),

                      suffixIcon:
                      IconButton(

                        onPressed:
                        _checkDelivery,

                        icon:
                        const Icon(
                          Icons.check_circle,
                        ),
                      ),

                      border:
                      OutlineInputBorder(

                        borderRadius:
                        BorderRadius.circular(
                          14,
                        ),
                      ),
                    ),
                  ),

                  if (_deliveryMessage
                      .isNotEmpty) ...[

                    const SizedBox(
                      height: 14,
                    ),

                    Container(

                      width:
                      double.infinity,

                      padding:
                      const EdgeInsets.all(
                        12,
                      ),

                      decoration:
                      BoxDecoration(

                        color: _isDeliverable

                            ? Colors.green
                            .withOpacity(
                            0.12)

                            : Colors.red
                            .withOpacity(
                            0.12),

                        borderRadius:
                        BorderRadius.circular(
                          12,
                        ),
                      ),

                      child: Row(

                        children: [

                          Icon(

                            _isDeliverable

                                ? Icons.check_circle

                                : Icons.error,

                            color:
                            _isDeliverable

                                ? Colors.green

                                : Colors.red,
                          ),

                          const SizedBox(
                            width: 10,
                          ),

                          Expanded(

                            child: Text(

                              _deliveryMessage,

                              style:
                              TextStyle(

                                color:
                                _isDeliverable

                                    ? Colors.green

                                    : Colors.red,

                                fontWeight:
                                FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ]
                ],
              ),
            ),

            const SizedBox(height: 16),

            // =====================================
            // PAYMENT
            // =====================================

            _sectionCard(

              child: Column(

                crossAxisAlignment:
                CrossAxisAlignment.start,

                children: [

                  const Text(

                    "Payment Method",

                    style: TextStyle(

                      fontSize: 16,

                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 14),
                  
                  // PhonePe Online Option
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _paymentMethod = "ONLINE";
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _paymentMethod == "ONLINE"
                            ? const Color(0xFF1C1C1E)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _paymentMethod == "ONLINE"
                              ? const Color(0xFF30D158)
                              : const Color(0xFF2C2C2E),
                          width: _paymentMethod == "ONLINE" ? 1.5 : 0.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.account_balance_wallet,
                            color: _paymentMethod == "ONLINE"
                                ? const Color(0xFF30D158)
                                : const Color(0xFF8E8E93),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Pay Online (PhonePe)",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  "UPI, Cards, Netbanking & Wallets",
                                  style: TextStyle(
                                    color: Color(0xFF8E8E93),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Radio<String>(
                            value: "ONLINE",
                            groupValue: _paymentMethod,
                            activeColor: const Color(0xFF30D158),
                            onChanged: (val) {
                              setState(() {
                                _paymentMethod = val!;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // COD Option
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _paymentMethod = "COD";
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _paymentMethod == "COD"
                            ? const Color(0xFF1C1C1E)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _paymentMethod == "COD"
                              ? const Color(0xFF30D158)
                              : const Color(0xFF2C2C2E),
                          width: _paymentMethod == "COD" ? 1.5 : 0.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.payments,
                            color: _paymentMethod == "COD"
                                ? const Color(0xFF30D158)
                                : const Color(0xFF8E8E93),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Cash on Delivery (COD)",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  "Pay with cash upon delivery",
                                  style: TextStyle(
                                    color: Color(0xFF8E8E93),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Radio<String>(
                            value: "COD",
                            groupValue: _paymentMethod,
                            activeColor: const Color(0xFF30D158),
                            onChanged: (val) {
                              setState(() {
                                _paymentMethod = val!;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // =====================================
            // ORDER SUMMARY
            // =====================================

            _sectionCard(

              child: Column(

                children: [

                  const Row(

                    children: [

                      Icon(
                        Icons.receipt_long,
                      ),

                      SizedBox(width: 8),

                      Text(

                        "Order Summary",

                        style: TextStyle(

                          fontSize: 16,

                          fontWeight:
                          FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  Row(

                    mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,

                    children: [

                      const Text(
                        "Subtotal",
                      ),

                      Text(
                        "₹${cart.totalAmount.toStringAsFixed(2)}",
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  Row(

                    mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,

                    children: [

                      const Text("Delivery"),

                      Row(
                        children: [
                          Text(
                            "₹30.00",
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 14,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            "FREE",
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const Padding(

                    padding:
                    EdgeInsets.symmetric(
                      vertical: 14,
                    ),

                    child: Divider(),
                  ),

                  Row(

                    mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,

                    children: [

                      const Text(

                        "TOTAL",

                        style: TextStyle(

                          fontSize: 18,

                          fontWeight:
                          FontWeight.bold,
                        ),
                      ),

                      Text(

                        "₹${cart.totalAmount.toStringAsFixed(2)}",

                        style: const TextStyle(

                          fontSize: 22,

                          fontWeight:
                          FontWeight.bold,

                          color:
                          Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      // =====================================
      // FIXED PLACE ORDER BUTTON
      // =====================================

      bottomNavigationBar: Container(

        margin: EdgeInsets.only(
          left: 12,
          right: 12,
          bottom: MediaQuery.of(context).padding.bottom + 8,
        ),

        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 8,
        ),

        decoration: BoxDecoration(

          color: const Color(0xFF111827),

          borderRadius: BorderRadius.circular(16),

          border: Border.all(
            color: Colors.white.withOpacity(0.05),
          ),

          boxShadow: [

            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),

        child: SafeArea(

          top: false,

          child: SizedBox(

            height: 42,

            child: ElevatedButton(

              onPressed:
              (_isDeliverable &&
                  !_loading)
                  ? _placeOrder
                  : null,

              style:
              ElevatedButton.styleFrom(

                backgroundColor:
                const Color(0xFF2563EB),

                foregroundColor:
                Colors.white,

                disabledBackgroundColor:
                const Color(0xFF2563EB).withOpacity(0.24),

                disabledForegroundColor:
                Colors.white.withOpacity(0.4),

                shape:
                RoundedRectangleBorder(

                  borderRadius:
                  BorderRadius.circular(
                    12,
                  ),
                ),
              ),

              child: _loading

                  ? const SizedBox(

                height: 22,
                width: 22,

                child:
                CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )

                  : const Row(

                mainAxisAlignment:
                MainAxisAlignment.center,

                children: [

                  Icon(
                    Icons.shopping_bag,
                  ),

                  SizedBox(width: 10),

                  Text(

                    "Place Order",

                    style: TextStyle(

                      fontSize: 16,

                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}