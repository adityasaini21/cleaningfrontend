import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/cart_provider.dart';
import '../services/order_service.dart';
import 'order_success_screen.dart';

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

  String _paymentMethod = "COD";

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

    final orderId =
    await _orderService.placeOrder(

      shippingAddress:
      _addressController.text,

      phoneNumber:
      _phoneController.text,

      pincode:
      _pincodeController.text,

      paymentMethod:
      _paymentMethod,

      items: cart.items,
    );

    setState(() {
      _loading = false;
    });

    if (orderId == null) {

      ScaffoldMessenger.of(context)
          .showSnackBar(

        const SnackBar(
          content:
          Text("Order failed"),
        ),
      );

      return;
    }

    cart.clearCart();

    if (!mounted) return;

    Navigator.pushReplacement(

      context,

      MaterialPageRoute(

        builder: (_) =>
        const OrderSuccessScreen(),
      ),
    );
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
      const EdgeInsets.all(18),

      decoration: BoxDecoration(

        color:
        const Color(0xFF111827),

        borderRadius:
        BorderRadius.circular(22),

        border: Border.all(

          color:
          Colors.white.withOpacity(0.05),
        ),

        boxShadow: [

          BoxShadow(

            color: Colors.black
                .withOpacity(0.18),

            blurRadius: 18,

            offset:
            const Offset(0, 8),
          ),
        ],
      ),

      child: child,
    );
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

                  Container(

                    padding:
                    const EdgeInsets.all(
                      14,
                    ),

                    decoration:
                    BoxDecoration(

                      color: Colors.green
                          .withOpacity(
                          0.10),

                      borderRadius:
                      BorderRadius.circular(
                        14,
                      ),

                      border: Border.all(
                        color:
                        Colors.green,
                      ),
                    ),

                    child: const Row(

                      children: [

                        Icon(
                          Icons.payments,
                          color:
                          Colors.green,
                        ),

                        SizedBox(width: 10),

                        Expanded(

                          child: Text(

                            "Cash on Delivery (COD)",

                            style:
                            TextStyle(

                              fontWeight:
                              FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
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

                  const Row(

                    mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,

                    children: [

                      Text("Delivery"),

                      Text(

                        "FREE",

                        style: TextStyle(
                          color:
                          Colors.green,
                        ),
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

        padding:
        const EdgeInsets.fromLTRB(
          16,
          12,
          16,
          16,
        ),

        decoration: BoxDecoration(

          color:
          const Color(0xFF111827),

          border: Border(

            top: BorderSide(

              color: Colors.white
                  .withOpacity(0.05),
            ),
          ),
        ),

        child: SafeArea(

          top: false,

          child: SizedBox(

            height: 56,

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

                shape:
                RoundedRectangleBorder(

                  borderRadius:
                  BorderRadius.circular(
                    18,
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