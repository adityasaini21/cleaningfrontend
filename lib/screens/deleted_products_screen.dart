import 'package:flutter/material.dart';

import '../models/product.dart';

import '../services/product_service.dart';

class DeletedProductsScreen
    extends StatefulWidget {

  const DeletedProductsScreen({
    super.key,
  });

  @override
  State<DeletedProductsScreen>
  createState() =>
      _DeletedProductsScreenState();
}

class _DeletedProductsScreenState
    extends State<DeletedProductsScreen> {

  final ProductService _service =
  ProductService();

  late Future<List<Product>> _products;

  @override
  void initState() {

    super.initState();

    _loadProducts();
  }

  // =====================================
  // LOAD PRODUCTS
  // =====================================
  void _loadProducts() {

    _products =
        _service.fetchDeletedProducts();
  }

  // =====================================
  // RESTORE PRODUCT
  // =====================================
  Future<void> _restoreProduct(
      Product product) async {

    try {

      await _service.restoreProduct(
          product.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(

        SnackBar(
          content: Text(
            "${product.name} restored",
          ),
        ),
      );

      setState(() {
        _loadProducts();
      });

    } catch (e) {

      ScaffoldMessenger.of(context)
          .showSnackBar(

        const SnackBar(
          content: Text(
            "Restore failed",
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title:
        const Text("Deleted Products"),
      ),

      body: FutureBuilder<List<Product>>(

        future: _products,

        builder: (context, snapshot) {

          if (snapshot.connectionState ==
              ConnectionState.waiting) {

            return const Center(
              child:
              CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {

            return Center(
              child: Text(
                "Error: ${snapshot.error}",
              ),
            );
          }

          final products =
              snapshot.data ?? [];

          if (products.isEmpty) {

            return const Center(

              child: Text(
                "No deleted products",
              ),
            );
          }

          return ListView.builder(

            padding:
            const EdgeInsets.all(12),

            itemCount: products.length,

            itemBuilder:
                (context, index) {

              final p = products[index];

              return Card(

                margin:
                const EdgeInsets.only(
                  bottom: 14,
                ),

                child: ListTile(

                  leading: CircleAvatar(

                    backgroundImage:
                    NetworkImage(
                      p.imageUrl,
                    ),
                  ),

                  title: Text(p.name),

                  subtitle: Text(
                    "₹${p.price}",
                  ),

                  trailing:
                  ElevatedButton.icon(

                    onPressed: () =>
                        _restoreProduct(p),

                    icon:
                    const Icon(Icons.restore),

                    label:
                    const Text("Restore"),
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