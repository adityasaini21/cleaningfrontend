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

          ? const Center(

        child: Text(

          "Your cart is empty",

          style: TextStyle(
            fontSize: 18,
          ),
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
                left: 8,
                right: 8,

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
                  const EdgeInsets.only(
                    bottom: 16,
                  ),

                  decoration: BoxDecoration(

                    borderRadius:
                    BorderRadius.circular(24),

                    gradient:
                    LinearGradient(

                      colors: [

                        Colors.white
                            .withOpacity(0.06),

                        Colors.white
                            .withOpacity(0.03),
                      ],

                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),

                    border: Border.all(

                      color: Colors.white
                          .withOpacity(0.08),
                    ),

                    boxShadow: [

                      BoxShadow(

                        color: Colors.black
                            .withOpacity(0.25),

                        blurRadius: 20,

                        offset:
                        const Offset(0, 10),
                      ),
                    ],
                  ),

                  child: Padding(

                    padding:
                    const EdgeInsets.all(14),

                    child: Row(

                      children: [

                        // =========================
                        // PRODUCT IMAGE
                        // =========================

                        Hero(

                          tag:
                          product.id,

                          child: Container(

                            width: 90,
                            height: 90,

                            decoration:
                            BoxDecoration(

                              borderRadius:
                              BorderRadius.circular(20),

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
                              BorderRadius.circular(20),

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

                                maxLines: 2,

                                overflow:
                                TextOverflow.ellipsis,

                                style:
                                const TextStyle(

                                  fontSize: 16,

                                  fontWeight:
                                  FontWeight.bold,
                                ),
                              ),

                              const SizedBox(height: 8),

                              Container(

                                padding:
                                const EdgeInsets.symmetric(

                                  horizontal: 10,
                                  vertical: 4,
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

                                    fontWeight:
                                    FontWeight.bold,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 16),

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

                            size: 28,
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



      bottomSheet: Container(

        margin: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: MediaQuery.of(context).padding.bottom + 10,
        ),

        padding: const EdgeInsets.fromLTRB(
          16,
          10,
          16,
          10,
        ),

        decoration: BoxDecoration(

          color: const Color(0xFF111827),

          borderRadius: BorderRadius.circular(24),

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

                      fontSize: 14,

                      color: Colors.grey.shade400,
                    ),
                  ),

                  Text(

                    "₹${cart.totalAmount.toStringAsFixed(2)}",

                    style: const TextStyle(

                      fontSize: 16,

                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              Row(

                mainAxisAlignment:
                MainAxisAlignment.spaceBetween,

                children: [

                  Text(

                    "Delivery",

                    style: TextStyle(

                      fontSize: 14,

                      color: Colors.grey.shade400,
                    ),
                  ),

                  Text(

                    "FREE",

                    style: TextStyle(

                      color: Colors.green.shade400,

                      fontSize: 15,

                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              const Padding(

                padding: EdgeInsets.symmetric(
                  vertical: 8,
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

                      fontSize: 18,

                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  Text(

                    "₹${cart.totalAmount.toStringAsFixed(2)}",

                    style: TextStyle(

                      fontSize: 24,

                      fontWeight: FontWeight.bold,

                      color: Colors.green.shade400,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              SizedBox(

                width: double.infinity,

                height: 50,

                child: ElevatedButton(

                  onPressed: () {

                    Navigator.push(

                      context,

                      MaterialPageRoute(

                        builder: (_) =>
                        const CheckoutScreen(),
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

                    shape:
                    RoundedRectangleBorder(

                      borderRadius:
                      BorderRadius.circular(20),
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
      BorderRadius.circular(12),

      child: Container(

        width: 34,
        height: 34,

        decoration: BoxDecoration(

          color: Colors.white
              .withOpacity(0.08),

          borderRadius:
          BorderRadius.circular(12),
        ),

        child: Icon(
          icon,
          size: 18,
        ),
      ),
    );
  }
}