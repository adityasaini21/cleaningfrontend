import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../services/cart_provider.dart';
import 'checkout_screen.dart';

class CartScreen extends StatelessWidget {

  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {

    final cart = context.watch<CartProvider>();

    return Scaffold(

      appBar: AppBar(

        title: const Text(
          "Your Cart",
        ),

        centerTitle: true,
      ),

      body: cart.items.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 64,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Your cart is empty",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            )

          : Column(

        children: [

          // =====================================
          // CART ITEMS
          // =====================================

          Expanded(

            child: ListView.builder(

              padding: EdgeInsets.only(

                top: 12,
                left: 0,
                right: 0,

                // IMPORTANT FIX
                bottom:
                MediaQuery.of(context).padding.bottom +
                    180,
              ),

              itemCount: cart.items.length,

              itemBuilder: (context, index) {

                final item =
                cart.items[index];

                final product =
                    item.product;

                return Container(

                  margin:
                  const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),

                  decoration: BoxDecoration(

                    color: const Color(0xFF1C1C1E),
                    borderRadius:
                    BorderRadius.circular(12),

                    border: Border.all(

                      color: const Color(0xFF2C2C2E),
                      width: 0.5,
                    ),
                  ),

                  child: Padding(

                    padding:
                    const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),

                    child: Row(

                      children: [

                        // =========================
                        // PRODUCT IMAGE
                        // =========================

                        Hero(

                          tag:
                          product.id,

                          child: Container(

                            width: 60,
                            height: 60,

                            decoration:
                            BoxDecoration(

                              borderRadius:
                              BorderRadius.circular(10),

                              gradient:
                              LinearGradient(

                                colors: [

                                  Colors.blue
                                      .withOpacity(0.25),

                                  Colors.purple
                                      .withOpacity(0.20),
                                ],
                              ),
                            ),

                            child: ClipRRect(

                              borderRadius:
                              BorderRadius.circular(10),

                              child:
                              CachedNetworkImage(

                                imageUrl:
                                product.imageUrl,

                                fit: BoxFit.cover,

                                placeholder:
                                    (
                                    context,
                                    url,
                                    ) => const Center(

                                  child:
                                  CircularProgressIndicator(),
                                ),

                                errorWidget:
                                    (
                                    context,
                                    url,
                                    error,
                                    ) => const Icon(
                                  Icons.image,
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 14),

                        // =========================
                        // PRODUCT DETAILS
                        // =========================

                        Expanded(

                          child: Column(

                            crossAxisAlignment:
                            CrossAxisAlignment.start,

                            children: [

                              Text(

                                product.name,

                                maxLines: 1,

                                overflow:
                                TextOverflow.ellipsis,

                                style:
                                const TextStyle(

                                  fontSize: 14,

                                  fontWeight:
                                  FontWeight.bold,
                                ),
                              ),

                              const SizedBox(height: 4),

                              Container(

                                padding:
                                const EdgeInsets.symmetric(

                                  horizontal: 8,
                                  vertical: 2,
                                ),

                                decoration:
                                BoxDecoration(

                                  color: Colors.green
                                      .withOpacity(0.15),

                                  borderRadius:
                                  BorderRadius.circular(30),
                                ),

                                child: Text(

                                  "₹${product.price}",

                                  style:
                                  const TextStyle(

                                    color: Colors.green,
                                    fontSize: 13,

                                    fontWeight:
                                    FontWeight.bold,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 8),

                              Row(

                                children: [

                                  _quantityButton(

                                    icon:
                                    Icons.remove,

                                    onTap: () {

                                      cart.decreaseQuantity(
                                        product.id,
                                      );
                                    },
                                  ),

                                  Padding(

                                    padding:
                                    const EdgeInsets.symmetric(
                                      horizontal: 14,
                                    ),

                                    child: Text(

                                      item.quantity
                                          .toString(),

                                      style:
                                      const TextStyle(

                                        fontSize: 16,

                                        fontWeight:
                                        FontWeight.bold,
                                      ),
                                    ),
                                  ),

                                  _quantityButton(

                                    icon:
                                    Icons.add,

                                    onTap: () {

                                      cart.increaseQuantity(
                                        product.id,
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // =========================
                        // DELETE
                        // =========================

                        IconButton(

                          onPressed: () {

                            cart.removeFromCart(
                              product.id,
                            );
                          },

                          icon: const Icon(

                            Icons.delete_outline,

                            color: Colors.redAccent,

                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),

      // =====================================
      // BOTTOM CHECKOUT SECTION
      // =====================================



      bottomSheet: cart.items.isEmpty
          ? null
          : Container(
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

          child: Column(

            mainAxisSize: MainAxisSize.min,

            children: [

              Row(

                mainAxisAlignment:
                MainAxisAlignment.spaceBetween,

                children: [

                  Text(

                    "Subtotal",

                    style: TextStyle(

                      fontSize: 13,

                      color: Colors.grey.shade400,
                    ),
                  ),

                  Text(

                    "₹${cart.totalAmount.toStringAsFixed(2)}",

                    style: const TextStyle(

                      fontSize: 14,

                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 6),

              Row(

                mainAxisAlignment:
                MainAxisAlignment.spaceBetween,

                children: [

                  Text(

                    "Delivery",

                    style: TextStyle(

                      fontSize: 13,

                      color: Colors.grey.shade400,
                    ),
                  ),

                  Row(
                    children: [
                      Text(
                        "₹30.00",
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 13,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "FREE",
                        style: TextStyle(
                          color: Colors.green.shade400,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const Padding(

                padding: EdgeInsets.symmetric(
                  vertical: 4,
                ),

                child: Divider(
                  thickness: 0.8,
                ),
              ),

              Row(

                mainAxisAlignment:
                MainAxisAlignment.spaceBetween,

                children: [

                  const Text(

                    "Total",

                    style: TextStyle(

                      fontSize: 15,

                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  Text(

                    "₹${cart.totalAmount.toStringAsFixed(2)}",

                    style: TextStyle(

                      fontSize: 18,

                      fontWeight: FontWeight.bold,

                      color: Colors.green.shade400,
                    ),
                  ),
                ],
              ),

              if (cart.totalAmount < 200.0) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF453A).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFFFF453A).withOpacity(0.3),
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Color(0xFFFF453A), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Add items worth ₹${(200.0 - cart.totalAmount).toStringAsFixed(2)} more to checkout (Min order ₹200).",
                          style: const TextStyle(
                            color: Color(0xFFFF453A),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 12),

              SizedBox(

                width: double.infinity,

                height: 50,

                child: ElevatedButton(

                  onPressed: cart.items.isEmpty || cart.totalAmount < 200.0
                      ? null
                      : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CheckoutScreen(),
                      ),
                    );
                  },

                  style:
                  ElevatedButton.styleFrom(

                    elevation: 0,

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
                      BorderRadius.circular(12),
                    ),
                  ),

                  child: const Row(

                    mainAxisAlignment:
                    MainAxisAlignment.center,

                    children: [

                      Icon(
                        Icons.shopping_bag_outlined,
                        size: 20,
                      ),

                      SizedBox(width: 10),

                      Text(

                        "Proceed to Checkout",

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
            ],
          ),
        ),
      ),
    );
  }

  // =========================================
  // QUANTITY BUTTON
  // =========================================

  Widget _quantityButton({

    required IconData icon,

    required VoidCallback onTap,
  }) {

    return InkWell(

      onTap: onTap,

      borderRadius:
      BorderRadius.circular(8),

      child: Container(

        width: 32,
        height: 32,

        decoration: BoxDecoration(

          color: Colors.white
              .withOpacity(0.08),

          borderRadius:
          BorderRadius.circular(8),
        ),

        child: Icon(
          icon,
          size: 16,
        ),
      ),
    );
  }
}