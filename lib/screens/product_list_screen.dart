import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../models/product.dart';
import '../models/category.dart';

import '../services/product_service.dart';
import '../services/cart_provider.dart';
import '../services/auth_service.dart';

import 'product_detail_screen.dart';

class ProductListScreen extends StatefulWidget {

  final VoidCallback onCartTap;

  const ProductListScreen({
    super.key,
    required this.onCartTap,
  });

  @override
  State<ProductListScreen> createState() =>
      _ProductListScreenState();
}

class _ProductListScreenState
    extends State<ProductListScreen> {

  final ProductService _service =
  ProductService();

  List<Product> _products = [];

  List<Product> _allProducts = [];

  List<Category> _categories = [];

  String? _selectedCategoryName;

  bool _isLoading = true;

  bool _isAdmin = false;

  @override
  void initState() {

    super.initState();

    _checkAdmin();

    _initializeData();
  }

  // =========================================
  // INITIAL LOAD
  // =========================================

  Future<void> _initializeData() async {

    await Future.wait([
      _loadCategories(),
      _loadProducts(),
    ]);
  }

  // =========================================
  // CHECK ADMIN
  // =========================================

  void _checkAdmin() {

    final token = AuthService.token;

    if (token == null) return;

    try {

      final parts = token.split('.');

      if (parts.length != 3) return;

      final payload = utf8.decode(
        base64Url.decode(
          base64Url.normalize(parts[1]),
        ),
      );

      final data = jsonDecode(payload);

      final role = data['role'];

      if (role == "ROLE_ADMIN" ||
          role == "ADMIN") {

        setState(() {
          _isAdmin = true;
        });
      }

    } catch (e) {

      debugPrint("JWT Parse Error: $e");
    }
  }

  // =========================================
  // LOAD PRODUCTS
  // =========================================

  Future<void> _loadProducts() async {

    try {

      setState(() {
        _isLoading = true;
      });

      final products =
      await _service.fetchProducts(0);

      if (!mounted) return;

      setState(() {

        _products = products;

        _allProducts = products;

        _isLoading = false;
      });

    } catch (e) {

      debugPrint("LOAD PRODUCT ERROR: $e");

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(

        SnackBar(
          content: Text(
            "Failed to load products\n$e",
          ),
        ),
      );
    }
  }

  // =========================================
  // LOAD CATEGORIES
  // =========================================

  Future<void> _loadCategories() async {

    try {

      final categories =
      await _service.fetchCategories();

      if (!mounted) return;

      setState(() {
        _categories = categories;
      });

    } catch (e) {

      debugPrint("CATEGORY ERROR: $e");
    }
  }

  // =========================================
  // FILTER PRODUCTS
  // =========================================

  Future<void> _filterProducts(
      String? category) async {

    setState(() {

      _selectedCategoryName = category;

      _isLoading = true;
    });

    try {

      if (category == null) {

        final products =
        await _service.fetchProducts(0);

        if (!mounted) return;

        setState(() {

          _products = products;

          _allProducts = products;

          _isLoading = false;
        });

      } else {

        final filtered =
        await _service
            .fetchProductsByCategory(
            category);

        if (!mounted) return;

        setState(() {

          _products = filtered;

          _allProducts = filtered;

          _isLoading = false;
        });
      }

    } catch (e) {

      debugPrint("FILTER ERROR: $e");

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    }
  }

  // =========================================
  // DELETE PRODUCT
  // =========================================

  Future<void> _deleteProduct(
      Product product) async {

    try {

      await _service.deleteProduct(
          product.id);

      await _loadProducts();

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(

        SnackBar(
          content: Text(
            "${product.name} deleted",
          ),
        ),
      );

    } catch (e) {

      ScaffoldMessenger.of(context)
          .showSnackBar(

        SnackBar(
          content: Text(
            "Delete Failed\n$e",
          ),
        ),
      );
    }
  }

  // =========================================
  // ADD PRODUCT
  // =========================================

  void _showAddProductDialog() {

    final nameController =
    TextEditingController();

    final descController =
    TextEditingController();

    final priceController =
    TextEditingController();

    final stockController =
    TextEditingController();

    final imageController =
    TextEditingController();

    Category? selectedCategory;

    showDialog(

      context: context,

      builder: (_) => StatefulBuilder(

        builder: (context, setDialogState) {

          return AlertDialog(

            title: const Text("Add Product"),

            content: SingleChildScrollView(

              child: Column(

                mainAxisSize: MainAxisSize.min,

                children: [

                  TextField(
                    controller: nameController,

                    decoration:
                    const InputDecoration(
                      labelText: "Name",
                    ),
                  ),

                  const SizedBox(height: 12),

                  TextField(
                    controller: descController,

                    decoration:
                    const InputDecoration(
                      labelText: "Description",
                    ),
                  ),

                  const SizedBox(height: 12),

                  TextField(
                    controller: priceController,

                    keyboardType:
                    TextInputType.number,

                    decoration:
                    const InputDecoration(
                      labelText: "Price",
                    ),
                  ),

                  const SizedBox(height: 12),

                  TextField(
                    controller: stockController,

                    keyboardType:
                    TextInputType.number,

                    decoration:
                    const InputDecoration(
                      labelText: "Stock",
                    ),
                  ),

                  const SizedBox(height: 12),

                  TextField(
                    controller: imageController,

                    decoration:
                    const InputDecoration(
                      labelText: "Image URL",
                    ),
                  ),

                  const SizedBox(height: 12),

                  DropdownButtonFormField<Category>(

                    value: selectedCategory,

                    decoration:
                    const InputDecoration(
                      labelText: "Category",

                      border:
                      OutlineInputBorder(),
                    ),

                    items: _categories.map((cat) {

                      return DropdownMenuItem(
                        value: cat,
                        child: Text(cat.name),
                      );

                    }).toList(),

                    onChanged: (value) {

                      setDialogState(() {

                        selectedCategory = value;
                      });
                    },
                  ),
                ],
              ),
            ),

            actions: [

              TextButton(

                onPressed: () =>
                    Navigator.pop(context),

                child: const Text("Cancel"),
              ),

              ElevatedButton(

                onPressed: () async {

                  try {

                    await _service.createProduct(

                      name:
                      nameController.text,

                      description:
                      descController.text,

                      price: double.parse(
                          priceController.text),

                      stock: int.parse(
                          stockController.text),

                      imageUrl:
                      imageController.text,

                      categoryId:
                      selectedCategory!.id,
                    );

                    if (!mounted) return;

                    Navigator.pop(context);

                    await _loadProducts();

                    ScaffoldMessenger.of(context)
                        .showSnackBar(

                      const SnackBar(
                        content:
                        Text("Product Added"),
                      ),
                    );

                  } catch (e) {

                    ScaffoldMessenger.of(context)
                        .showSnackBar(

                      SnackBar(
                        content:
                        Text("Error: $e"),
                      ),
                    );
                  }
                },

                child: const Text("Add"),
              ),
            ],
          );
        },
      ),
    );
  }

  // =========================================
  // UI
  // =========================================

  @override
  Widget build(BuildContext context) {

    final cart =
    context.watch<CartProvider>();

    return Scaffold(

      floatingActionButton: _isAdmin
          ? FloatingActionButton(
        onPressed:
        _showAddProductDialog,

        child: const Icon(Icons.add),
      )
          : null,

      appBar: AppBar(

        title: const Text("Products"),

        actions: [

          IconButton(
            icon: const Icon(Icons.search),

            onPressed: () {

              showSearch(

                context: context,

                delegate:
                ProductSearchDelegate(
                  products: _allProducts,
                ),
              );
            },
          ),

          Stack(

            children: [

              IconButton(
                icon:
                const Icon(Icons.shopping_cart),

                onPressed:
                widget.onCartTap,
              ),

              if (cart.items.isNotEmpty)

                Positioned(

                  right: 2,
                  top: 2,

                  child: Container(

                    padding:
                    const EdgeInsets.all(5),

                    decoration:
                    const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),

                    child: Text(

                      cart.items.length
                          .toString(),

                      style:
                      const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),

      body: Column(

        children: [

          Padding(

            padding:
            const EdgeInsets.all(12),

            child:
            DropdownButtonFormField<String?>(

              value:
              _selectedCategoryName,

              decoration:
              const InputDecoration(
                labelText:
                "Filter by Category",

                border:
                OutlineInputBorder(),
              ),

              items: [

                const DropdownMenuItem(
                  value: null,
                  child:
                  Text("All Products"),
                ),

                ..._categories.map(
                      (cat) =>
                      DropdownMenuItem(
                        value: cat.name,
                        child: Text(cat.name),
                      ),
                ),
              ],

              onChanged:
              _filterProducts,
            ),
          ),

          Expanded(

            child: _isLoading

                ? const Center(
              child:
              CircularProgressIndicator(),
            )

                : _products.isEmpty

                ? const Center(
              child:
              Text("No Products Found"),
            )

                : GridView.builder(

              padding:
              const EdgeInsets.all(12),

              gridDelegate:
              SliverGridDelegateWithFixedCrossAxisCount(

                crossAxisCount: 2,

                mainAxisSpacing: 12,

                crossAxisSpacing: 12,

                childAspectRatio:
                _isAdmin ? 0.50 : 0.62,
              ),

              itemCount:
              _products.length,

              itemBuilder:
                  (context, index) {

                final p =
                _products[index];

                return GestureDetector(

                  onTap: () {

                    Navigator.push(

                      context,

                      MaterialPageRoute(
                        builder: (_) =>
                            ProductDetailScreen(
                              product: p,
                            ),
                      ),
                    );
                  },

                  child: Card(

                    shape:
                    RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(
                          16),
                    ),

                    child: Padding(

                      padding:
                      const EdgeInsets.all(10),

                      child: Column(

                        crossAxisAlignment:
                        CrossAxisAlignment
                            .start,

                        children: [

                          Expanded(

                            child: ClipRRect(

                              borderRadius:
                              BorderRadius.circular(
                                  12),

                              child:
                              CachedNetworkImage(

                                imageUrl:
                                p.imageUrl,

                                width:
                                double.infinity,

                                fit: BoxFit.cover,

                                errorWidget:
                                    (
                                    context,
                                    url,
                                    error,
                                    ) =>
                                const Icon(
                                  Icons.broken_image,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 8),

                          Text(

                            p.name,

                            maxLines: 1,

                            overflow:
                            TextOverflow
                                .ellipsis,

                            style:
                            const TextStyle(
                              fontWeight:
                              FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 4),

                          Row(

                            children: [

                              const Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: 16,
                              ),

                              const SizedBox(width: 4),

                              Text(

                                p.averageRating
                                    .toStringAsFixed(1),

                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),

                              const SizedBox(width: 4),

                              Text(

                                "(${p.reviewCount})",

                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),


                          const SizedBox(height: 4),

                          Text(
                            "₹${p.price}",

                            style:
                            const TextStyle(
                              color:
                              Colors.green,

                              fontWeight:
                              FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 8),

                          if (_isAdmin)

                            Row(

                              children: [

                                Expanded(

                                  child:
                                  ElevatedButton(

                                    style:
                                    ElevatedButton.styleFrom(
                                      backgroundColor:
                                      Colors.blue,
                                    ),

                                    onPressed: () {

                                      Navigator.push(

                                        context,

                                        MaterialPageRoute(
                                          builder: (_) =>
                                              ProductDetailScreen(
                                                product: p,
                                              ),
                                        ),
                                      );
                                    },

                                    child:
                                    const Icon(
                                      Icons.edit,
                                      color:
                                      Colors.white,
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 8),

                                Expanded(

                                  child:
                                  ElevatedButton(

                                    style:
                                    ElevatedButton.styleFrom(
                                      backgroundColor:
                                      Colors.red,
                                    ),

                                    onPressed:
                                        () =>
                                        _deleteProduct(
                                            p),

                                    child:
                                    const Icon(
                                      Icons.delete,
                                      color:
                                      Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            )

                          else

                            SizedBox(

                              width:
                              double.infinity,

                              child:
                              ElevatedButton(

                                onPressed: () {

                                  context
                                      .read<
                                      CartProvider>()
                                      .addToCart(p);

                                  ScaffoldMessenger.of(
                                      context)
                                      .showSnackBar(

                                    SnackBar(
                                      content: Text(
                                        "${p.name} added to cart",
                                      ),
                                    ),
                                  );
                                },

                                child:
                                const Text("Add"),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// =========================================
// SEARCH
// =========================================

class ProductSearchDelegate
    extends SearchDelegate {

  final List<Product> products;

  ProductSearchDelegate({
    required this.products,
  });

  @override
  List<Widget>? buildActions(
      BuildContext context) {

    return [

      IconButton(
        icon: const Icon(Icons.clear),

        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget? buildLeading(
      BuildContext context) {

    return IconButton(

      icon: const Icon(Icons.arrow_back),

      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(
      BuildContext context) {

    final filtered = products.where((p) {

      return p.name
          .toLowerCase()
          .contains(query.toLowerCase());

    }).toList();

    return ListView.builder(

      itemCount: filtered.length,

      itemBuilder: (context, index) {

        final p = filtered[index];

        return ListTile(

          title: Text(p.name),

          subtitle: Text("₹${p.price}"),

          onTap: () {

            Navigator.push(

              context,

              MaterialPageRoute(
                builder: (_) =>
                    ProductDetailScreen(
                      product: p,
                    ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(
      BuildContext context) {

    return buildResults(context);
  }
}