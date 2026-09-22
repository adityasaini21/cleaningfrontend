import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../models/product.dart';
import '../models/category.dart';

import '../services/product_service.dart';
import '../services/cart_provider.dart';
import '../services/auth_service.dart';

import 'login_screen.dart';
import 'product_detail_screen.dart';
import 'deleted_products_screen.dart';

class ProductListScreen extends StatefulWidget {

  final VoidCallback onCartTap;
  final bool isOpenedFromAdminDashboard;

  const ProductListScreen({
    super.key,
    required this.onCartTap,
    this.isOpenedFromAdminDashboard = false,
  });

  @override
  State<ProductListScreen> createState() =>
      _ProductListScreenState();
}

class _ProductListScreenState
    extends State<ProductListScreen> {

  final ProductService _service =
  ProductService();

  final TextEditingController _searchController = TextEditingController();

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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applySearchFilter() {
    final query = _searchController.text.trim().toLowerCase();
    List<Product> list;
    if (query.isEmpty) {
      list = List.from(_allProducts);
    } else {
      list = _allProducts.where((p) {
        final nameMatch = p.name.toLowerCase().contains(query);
        final descMatch = p.description.toLowerCase().contains(query);
        final categoryMatch = p.categoryName.toLowerCase().contains(query);
        return nameMatch || descMatch || categoryMatch;
      }).toList();
    }
    list.sort((a, b) {
      if (a.isLive && !b.isLive) return -1;
      if (!a.isLive && b.isLive) return 1;
      return 0;
    });
    _products = list;
  }

  void _onSearchChanged(String query) {
    setState(() {
      _applySearchFilter();
    });
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

      final List<Product> products;
      if (_selectedCategoryName == null) {
        products = await _service.fetchProducts(0);
      } else {
        products = await _service.fetchProductsByCategory(_selectedCategoryName!);
      }

      if (!mounted) return;

      for (final product in products) {
        precacheImage(
          CachedNetworkImageProvider(product.imageUrl),
          context,
        );
      }

      setState(() {
        _allProducts = products;
        _applySearchFilter();
        _isLoading = false;
      });

    } catch (e) {
      debugPrint("LOAD PRODUCT ERROR: $e");

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
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
      final categories = await _service.fetchCategories();

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

  Future<void> _filterProducts(String? category) async {
    _selectedCategoryName = category;
    await _loadProducts();
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
  // HELPER METHODS FOR PREMIUM MOCKUP UI
  // =========================================

  String _getProductVolume(Product p) {
    final nameLower = p.name.toLowerCase();
    final descLower = p.description.toLowerCase();
    
    // Look for patterns like "55 gal", "10l", "5g", "5 gal", "10 liters" in name or description
    RegExp regExp = RegExp(r'\b(\d+(?:\.\d+)?\s*(?:gal|g|l|liters|can|drum|jug))\b', caseSensitive: false);
    
    var match = regExp.firstMatch(p.name);
    if (match != null) return match.group(1)!;
    
    match = regExp.firstMatch(p.description);
    if (match != null) return match.group(1)!;
    
    // Fallback defaults based on keywords
    if (nameLower.contains('drum') || descLower.contains('drum') || nameLower.contains('solv')) return "55 Gal";
    if (nameLower.contains('jug') || descLower.contains('jug') || nameLower.contains('power')) return "5 Gal";
    if (nameLower.contains('can') || descLower.contains('can') || nameLower.contains('shine')) return "10 Liters";
    
    return "1 Unit";
  }

  String _getProductUnitSuffix(Product p) {
    final nameLower = p.name.toLowerCase();
    final descLower = p.description.toLowerCase();
    if (nameLower.contains('drum') || descLower.contains('drum') || nameLower.contains('55 gal') || nameLower.contains('solv')) return "Drum";
    if (nameLower.contains('jug') || descLower.contains('jug') || nameLower.contains('5 gal') || nameLower.contains('5g') || nameLower.contains('power')) return "Jug";
    if (nameLower.contains('can') || descLower.contains('can') || nameLower.contains('10l') || nameLower.contains('10 l') || nameLower.contains('shine')) return "Can";
    return "Unit";
  }

  Widget _buildProductCard(Product p, int index) {
    final cart = context.watch<CartProvider>();
    final quantity = cart.getProductQuantity(p.id);
    final volume = _getProductVolume(p);
    final unitSuffix = _getProductUnitSuffix(p);
    
    // Split name for two-tone color display
    String namePart1 = p.name;
    String namePart2 = p.categoryName;
    final words = p.name.split(' ');
    if (words.length > 2) {
      namePart1 = words.sublist(0, words.length - 1).join(' ');
      namePart2 = words.last;
    } else if (words.length == 2) {
      namePart1 = words.first;
      namePart2 = words.last;
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF2C2C2E),
          width: 0.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Container with light gray platform/background
            Expanded(
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2C2C2E),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Opacity(
                        opacity: p.isComingSoon ? 0.65 : 1.0,
                        child: CachedNetworkImage(
                          imageUrl: p.imageUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          memCacheWidth: 500,
                          memCacheHeight: 500,
                          fadeInDuration: Duration.zero,
                          fadeOutDuration: Duration.zero,
                          errorWidget: (context, url, error) => const Icon(
                            Icons.broken_image,
                            color: Color(0xFF8E8E93),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (p.isComingSoon)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B),
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.4),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.schedule, color: Colors.black, size: 10),
                            SizedBox(width: 3),
                            Text(
                              "COMING SOON",
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w900,
                                fontSize: 8.5,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            
            // Two-tone Title
            Text(
              namePart1,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: p.isComingSoon ? const Color(0xFF8E8E93) : const Color(0xFF0A84FF),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            Text(
              namePart2,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: p.isComingSoon ? const Color(0xFFB0B0B5) : Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            
            // Subtitle / Description (gray, small)
            Text(
              p.description,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF8E8E93),
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 8),
            
            // Info Row (Volume & Rating)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  volume,
                  style: const TextStyle(
                    color: Color(0xFF8E8E93),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      p.averageRating.toStringAsFixed(1),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(
                      Icons.star,
                      color: Colors.amber,
                      size: 12,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Price (Green or Gray if coming soon)
            Text(
              p.isComingSoon
                  ? "₹${p.price.toStringAsFixed(2)} / $unitSuffix"
                  : "₹${p.price.toStringAsFixed(2)} / $unitSuffix",
              style: TextStyle(
                color: p.isComingSoon ? const Color(0xFF8E8E93) : const Color(0xFF30D158),
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 10),
            
            // Action Buttons
            if (_isAdmin)
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 36,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ProductDetailScreen(product: p),
                            ),
                          );
                        },
                        child: const Icon(Icons.edit, color: Colors.white, size: 18),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SizedBox(
                      height: 36,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () => _deleteProduct(p),
                        child: const Icon(Icons.delete, color: Colors.white, size: 18),
                      ),
                    ),
                  ),
                ],
              )
            else if (p.isComingSoon)
              SizedBox(
                width: double.infinity,
                height: 36,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF2C2C2E),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFF3A3A3C),
                      width: 0.8,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.lock_clock_outlined, size: 13, color: Color(0xFF8E8E93)),
                      SizedBox(width: 5),
                      Text(
                        "COMING SOON",
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF8E8E93),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else if (quantity > 0)
              Container(
                width: double.infinity,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF0A84FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: const BorderRadius.horizontal(left: Radius.circular(10)),
                        onTap: () => cart.decreaseQuantity(p.id),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          child: Icon(Icons.remove, color: Colors.white, size: 16),
                        ),
                      ),
                    ),
                    Text(
                      "$quantity",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: const BorderRadius.horizontal(right: Radius.circular(10)),
                        onTap: () => cart.increaseQuantity(p.id),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          child: Icon(Icons.add, color: Colors.white, size: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                height: 36,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0A84FF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: EdgeInsets.zero,
                  ),
                  onPressed: () {
                    cart.addToCart(p);
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.shopping_cart_outlined, size: 14),
                      SizedBox(width: 4),
                      Text(
                        "ADD TO CART",
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryList() {
    final allCategories = [
      Category(id: -1, name: "All Chemicals"),
      ..._categories,
    ];
    
    return Container(
      height: 76,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: allCategories.length,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemBuilder: (context, index) {
          final cat = allCategories[index];
          final isSelected = (index == 0 && _selectedCategoryName == null) || 
                             (index > 0 && _selectedCategoryName == cat.name);
          
          IconData iconData;
          final catLower = cat.name.toLowerCase();
          if (cat.id == -1) {
            iconData = Icons.grid_view_rounded;
          } else if (catLower.contains('liquid') || catLower.contains('cleaner') || catLower.contains('soap')) {
            iconData = Icons.water_drop_outlined;
          } else if (catLower.contains('solvent')) {
            iconData = Icons.science_outlined;
          } else if (catLower.contains('degreaser')) {
            iconData = Icons.cleaning_services_outlined;
          } else if (catLower.contains('disinfectant') || catLower.contains('surface')) {
            iconData = Icons.sanitizer_outlined;
          } else {
            iconData = Icons.science_outlined;
          }
          
          return GestureDetector(
            onTap: () {
              if (index == 0) {
                _filterProducts(null);
              } else {
                _filterProducts(cat.name);
              }
            },
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              child: Column(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C1C1E),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF30D158) : const Color(0xFF2C2C2E),
                        width: isSelected ? 1.5 : 0.5,
                      ),
                    ),
                    child: Icon(
                      iconData,
                      color: isSelected ? const Color(0xFF30D158) : Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    cat.name.replaceAll(' ', '\n'),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? const Color(0xFF30D158) : const Color(0xFF8E8E93),
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),
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
    final cart = context.watch<CartProvider>();

    return Scaffold(
      floatingActionButton: _isAdmin
          ? FloatingActionButton(
              onPressed: _showAddProductDialog,
              child: const Icon(Icons.add),
            )
          : null,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                onPressed: () {
                  if (widget.isOpenedFromAdminDashboard) {
                    Navigator.pop(context);
                  } else {
                    _showLogoutConfirmation(context);
                  }
                },
              )
            : null,
        title: Image.asset(
          'assets/images/lll.png',
          height: 16,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => const Text(
            "NuKlean",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        actions: [
          if (_isAdmin)
            IconButton(
              icon: const Icon(Icons.settings_backup_restore, color: Colors.white),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const DeletedProductsScreen(),
                  ),
                );
                _loadProducts();
              },
              tooltip: "Restore Deleted Products",
            ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined),
                onPressed: widget.onCartTap,
              ),
              if (cart.totalItemCount > 0)
                Positioned(
                  right: 4,
                  top: 4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      cart.totalItemCount > 99
                          ? "99+"
                          : cart.totalItemCount.toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF2C2C2E),
                  width: 0.5,
                ),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF8E8E93), size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Color(0xFF8E8E93), size: 18),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged("");
                          },
                        )
                      : null,
                  hintText: "Search chemicals, cleaners...",
                  hintStyle: const TextStyle(color: Color(0xFF8E8E93), fontSize: 14),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          
          // Horizontal category list
          _buildCategoryList(),
          
          // Product Grid
          Expanded(
            child: Builder(
              builder: (context) {
                final screenWidth = MediaQuery.of(context).size.width;
                final int crossAxisCount;
                final double childAspectRatio;

                if (screenWidth >= 1200) {
                  crossAxisCount = 5;
                  childAspectRatio = _isAdmin ? 0.44 : 0.52;
                } else if (screenWidth >= 900) {
                  crossAxisCount = 4;
                  childAspectRatio = _isAdmin ? 0.42 : 0.50;
                } else if (screenWidth >= 600) {
                  crossAxisCount = 3;
                  childAspectRatio = _isAdmin ? 0.40 : 0.48;
                } else {
                  crossAxisCount = 2;
                  childAspectRatio = _isAdmin ? 0.40 : 0.48;
                }

                if (_isLoading) {
                  return GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: childAspectRatio,
                    ),
                    itemCount: crossAxisCount * 3,
                    itemBuilder: (context, index) => const ProductCardSkeleton(),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _loadProducts,
                  color: const Color(0xFF0A84FF),
                  backgroundColor: const Color(0xFF1C1C1E),
                  child: _products.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const [
                            SizedBox(height: 120),
                            Center(
                              child: Text(
                                "No Products Found",
                                style: TextStyle(color: Color(0xFF8E8E93)),
                              ),
                            ),
                          ],
                        )
                      : GridView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          cacheExtent: 1200,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            childAspectRatio: childAspectRatio,
                          ),
                          itemCount: _products.length,
                          itemBuilder: (context, index) {
                            final p = _products[index];
                            final isClickable = _isAdmin || p.isLive;
                            return GestureDetector(
                              onTap: isClickable
                                  ? () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => ProductDetailScreen(
                                            product: p,
                                          ),
                                        ),
                                      );
                                    }
                                  : null,
                              child: _buildProductCard(p, index),
                            );
                          },
                        ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showLogoutConfirmation(BuildContext context) async {
    final authService = AuthService();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1C1C1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF2C2C2E), width: 0.5),
          ),
          title: const Text(
            "Logout",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: const Text(
            "Do you really want to logout?",
            style: TextStyle(color: Color(0xFF8E8E93)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                "Cancel",
                style: TextStyle(color: Color(0xFF0A84FF)),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                "Logout",
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await authService.logout();
      if (!context.mounted) return;
      Provider.of<CartProvider>(context, listen: false).clearCart();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        ),
        (route) => false,
      );
    }
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
          title: Text(
            p.name,
            style: TextStyle(
              color: p.isComingSoon ? Colors.white70 : Colors.white,
            ),
          ),
          subtitle: Text(
            p.isComingSoon ? "₹${p.price} • Coming Soon" : "₹${p.price}",
            style: TextStyle(
              color: p.isComingSoon ? const Color(0xFFF59E0B) : const Color(0xFF30D158),
              fontWeight: p.isComingSoon ? FontWeight.w600 : FontWeight.bold,
            ),
          ),
          trailing: p.isComingSoon
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2C2C2E),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFF59E0B), width: 0.8),
                  ),
                  child: const Text(
                    "COMING SOON",
                    style: TextStyle(
                      color: Color(0xFFF59E0B),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              : const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFF8E8E93)),
          onTap: p.isLive
              ? () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          ProductDetailScreen(
                            product: p,
                          ),
                    ),
                  );
                }
              : null,
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

// =========================================
// SKELETON LOADER FOR PREMIUM EXPERIENCE
// =========================================
class ProductCardSkeleton extends StatefulWidget {
  const ProductCardSkeleton({super.key});

  @override
  State<ProductCardSkeleton> createState() => _ProductCardSkeletonState();
}

class _ProductCardSkeletonState extends State<ProductCardSkeleton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _opacityAnimation = Tween<double>(begin: 0.35, end: 0.75).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacityAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C1E),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF2C2C2E),
                width: 0.5,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image Placeholder
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2C2C2E),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Title Line 1
                  Container(
                    width: 100,
                    height: 12,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2C2C2E),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Title Line 2
                  Container(
                    width: 70,
                    height: 12,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2C2C2E),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Subtitle description placeholder
                  Container(
                    width: double.infinity,
                    height: 9,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2C2C2E),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Info row placeholder
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 40,
                        height: 9,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2C2C2E),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      Container(
                        width: 30,
                        height: 9,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2C2C2E),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Price placeholder
                  Container(
                    width: 60,
                    height: 11,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2C2C2E),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Button placeholder
                  Container(
                    width: double.infinity,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2C2C2E),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}