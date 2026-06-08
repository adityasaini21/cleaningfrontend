import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloudinary_public/cloudinary_public.dart';

import '../models/product.dart';
import '../models/category.dart';

import '../services/cart_provider.dart';
import '../services/product_service.dart';
import '../services/auth_service.dart';
import '../models/review.dart';
import '../services/review_service.dart';

class ProductDetailScreen extends StatefulWidget {

  final Product product;

  const ProductDetailScreen({
    super.key,
    required this.product,
  });

  @override
  State<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState
    extends State<ProductDetailScreen> {

  // =========================================
  // SERVICES
  // =========================================

  final ProductService _service =
  ProductService();

  final ReviewService _reviewService =
  ReviewService();

  final ImagePicker _picker =
  ImagePicker();

  // =========================================
  // CLOUDINARY
  // =========================================

  final cloudinary = CloudinaryPublic(

    "dabc123xyz",

    "prem_chemicals",

    cache: false,
  );

  // =========================================
  // STATES
  // =========================================

  bool _isAdmin = false;

  bool _isEditing = false;

  bool _isUploadingImage = false;
  List<Review> _reviews = [];

  bool _loadingReviews = true;

  List<Category> _categories = [];

  Category? _selectedCategory;

  // =========================================
  // CONTROLLERS
  // =========================================

  late TextEditingController
  _nameController;

  late TextEditingController
  _descriptionController;

  late TextEditingController
  _priceController;

  late TextEditingController
  _stockController;

  late TextEditingController
  _imageController;

  // =========================================
  // INIT
  // =========================================

  @override
  void initState() {

    super.initState();

    _checkAdmin();

    _loadCategories();
    _loadReviews();


    _nameController =
        TextEditingController(
            text: widget.product.name);

    _descriptionController =
        TextEditingController(
            text: widget.product.description);

    _priceController =
        TextEditingController(
            text:
            widget.product.price.toString());

    _stockController =
        TextEditingController(
            text:
            widget.product.stock.toString());

    _imageController =
        TextEditingController(
            text:
            widget.product.imageUrl);
  }

  // =========================================
  // DISPOSE
  // =========================================

  @override
  void dispose() {

    _nameController.dispose();

    _descriptionController.dispose();

    _priceController.dispose();

    _stockController.dispose();

    _imageController.dispose();

    super.dispose();
  }

  // =========================================
  // LOAD CATEGORIES
  // =========================================

  void _loadCategories() async {

    try {

      final categories =
      await _service.fetchCategories();

      if (!mounted) return;

      setState(() {

        _categories = categories;

        _selectedCategory =
            categories.firstWhere(
                  (c) =>
              c.id ==
                  widget.product.categoryId,
            );
      });

    } catch (e) {

      debugPrint(
          "Category load error: $e");
    }
  }
  // =========================================
// LOAD REVIEWS
// =========================================

  Future<void> _loadReviews() async {

    try {

      final reviews =
      await _reviewService
          .getProductReviews(
        widget.product.id,
      );

      if (!mounted) return;

      setState(() {

        _reviews = reviews;

        _loadingReviews = false;
      });

    } catch (e) {

      if (!mounted) return;

      setState(() {

        _loadingReviews = false;
      });

      debugPrint(
        "REVIEW ERROR => $e",
      );
    }
  }

  Future<void> _showAddReviewDialog() async {

    int rating = 5;

    final commentController =
    TextEditingController();

    await showDialog(

      context: context,

      builder: (context) {

        return StatefulBuilder(

          builder: (context, setDialogState) {

            return AlertDialog(

              title: const Text(
                "Write Review",
              ),

              content: Column(

                mainAxisSize: MainAxisSize.min,

                children: [

                  Row(

                    mainAxisAlignment:
                    MainAxisAlignment.center,

                    children: List.generate(

                      5,

                          (index) {

                        return IconButton(

                          onPressed: () {

                            setDialogState(() {

                              rating = index + 1;
                            });
                          },

                          icon: Icon(

                            Icons.star,

                            color: index < rating
                                ? Colors.amber
                                : Colors.grey,
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 16),

                  TextField(

                    controller:
                    commentController,

                    maxLines: 4,

                    decoration:
                    const InputDecoration(

                      labelText: "Comment",

                      border:
                      OutlineInputBorder(),
                    ),
                  ),
                ],
              ),

              actions: [

                TextButton(

                  onPressed: () {

                    Navigator.pop(context);
                  },

                  child: const Text(
                    "Cancel",
                  ),
                ),

                ElevatedButton(

                  onPressed: () async {

                    try {

                      await _reviewService
                          .addReview(

                        productId:
                        widget.product.id,

                        rating: rating,

                        comment:
                        commentController.text
                            .trim(),
                      );

                      if (!mounted) return;

                      Navigator.pop(context);

                      await _loadReviews();

                      ScaffoldMessenger.of(
                          context)
                          .showSnackBar(

                        const SnackBar(

                          content: Text(
                            "Review added successfully",
                          ),
                        ),
                      );

                    } catch (e) {

                      ScaffoldMessenger.of(
                          context)
                          .showSnackBar(

                        SnackBar(

                          content: Text(
                            e.toString(),
                          ),
                        ),
                      );
                    }
                  },

                  child: const Text(
                    "Submit",
                  ),
                ),
              ],
            );
          },
        );
      },
    );
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

      final payload =
      utf8.decode(
        base64Url.decode(
          base64Url.normalize(parts[1]),
        ),
      );

      final data = jsonDecode(payload);

      final role = data['role'];

      if (role == "ADMIN" ||
          role == "ROLE_ADMIN") {

        setState(() {
          _isAdmin = true;
        });
      }

    } catch (e) {

      debugPrint(
          "JWT parse error: $e");
    }
  }

  // =========================================
  // PICK & UPLOAD IMAGE
  // =========================================

  Future<void> _pickAndUploadImage() async {

    try {

      final XFile? file =
      await _picker.pickImage(

        source:
        ImageSource.gallery,

        imageQuality: 70,
      );

      if (file == null) return;

      setState(() {
        _isUploadingImage = true;
      });

      final response =
      await cloudinary.uploadFile(

        CloudinaryFile.fromFile(
          file.path,

          folder: "products",
        ),
      );

      _imageController.text =
          response.secureUrl;

      setState(() {});

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(

        const SnackBar(
          content:
          Text("Image uploaded"),
        ),
      );

    } catch (e) {

      ScaffoldMessenger.of(context)
          .showSnackBar(

        SnackBar(
          content:
          Text("Upload failed: $e"),
        ),
      );
    }

    if (!mounted) return;

    setState(() {
      _isUploadingImage = false;
    });
  }

  // =========================================
  // UPDATE PRODUCT
  // =========================================

  Future<void> _updateProduct() async {

    if (_selectedCategory == null) {

      ScaffoldMessenger.of(context)
          .showSnackBar(

        const SnackBar(
          content:
          Text("Select category"),
        ),
      );

      return;
    }

    setState(() {
      _isEditing = true;
    });

    try {

      await _service.updateProduct(

        productId:
        widget.product.id,

        name:
        _nameController.text.trim(),

        description:
        _descriptionController.text.trim(),

        price:
        double.parse(
            _priceController.text),

        stock:
        int.parse(
            _stockController.text),

        imageUrl:
        _imageController.text.trim(),

        categoryId:
        _selectedCategory!.id,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(

        const SnackBar(
          content:
          Text("Product updated"),
        ),
      );

      Navigator.pop(context, true);

    } catch (e) {

      ScaffoldMessenger.of(context)
          .showSnackBar(

        SnackBar(
          content:
          Text("Update failed: $e"),
        ),
      );
    }

    if (!mounted) return;

    setState(() {
      _isEditing = false;
    });
  }

  // =========================================
  // BUILD
  // =========================================

  @override
  Widget build(BuildContext context) {

    final cart =
    context.watch<CartProvider>();

    return Scaffold(

      appBar: AppBar(

        title: Text(
            widget.product.name),

        actions: [

          if (_isAdmin)

            Padding(

              padding:
              const EdgeInsets.only(
                  right: 10),

              child:
              ElevatedButton.icon(

                onPressed:
                _isEditing
                    ? null
                    : _updateProduct,

                icon:
                const Icon(Icons.save),

                label:
                const Text("Save"),
              ),
            ),
        ],
      ),

      // =====================================
      // USER BUTTON
      // =====================================

      bottomNavigationBar:

      !_isAdmin

          ? Padding(

        padding:
        const EdgeInsets.all(16),

        child: SizedBox(

          height: 50,

          child: ElevatedButton(

            onPressed: () {

              context
                  .read<CartProvider>()
                  .addToCart(
                  widget.product);

              ScaffoldMessenger.of(
                  context)
                  .showSnackBar(

                SnackBar(
                  content: Text(
                    "${widget.product.name} added to cart",
                  ),
                ),
              );
            },

            child: const Text(

              "Add to Cart",

              style: TextStyle(
                  fontSize: 16),
            ),
          ),
        ),
      )

          : null,

      // =====================================
      // BODY
      // =====================================

      body: SingleChildScrollView(

        child: Column(

          crossAxisAlignment:
          CrossAxisAlignment.start,

          children: [

            // =====================================
            // IMAGE
            // =====================================

            Container(

              width: double.infinity,

              height: 300,

              color: Colors.grey[200],

              child:
              CachedNetworkImage(

                imageUrl:
                _imageController.text,

                fit: BoxFit.cover,

                placeholder:
                    (context, url) =>
                const Center(
                  child:
                  CircularProgressIndicator(),
                ),

                errorWidget:
                    (
                    context,
                    url,
                    error,
                    ) =>
                const Icon(

                  Icons
                      .image_not_supported,

                  size: 60,
                ),
              ),
            ),

            const SizedBox(height: 20),

            Padding(

              padding:
              const EdgeInsets.symmetric(
                  horizontal: 16),

              child: Column(

                crossAxisAlignment:
                CrossAxisAlignment.start,

                children: [

                  // =====================================
                  // PRODUCT NAME
                  // =====================================

                  _isAdmin

                      ? TextField(

                    controller:
                    _nameController,

                    decoration:
                    const InputDecoration(
                      labelText:
                      "Product Name",
                    ),
                  )

                      : Text(

                    widget.product.name,

                    style:
                    const TextStyle(
                      fontSize: 24,
                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // =====================================
                  // CATEGORY
                  // =====================================

                  _isAdmin

                      ? DropdownButtonFormField<Category>(

                    value:
                    _selectedCategory,

                    decoration:
                    const InputDecoration(

                      labelText:
                      "Category",

                      border:
                      OutlineInputBorder(),
                    ),

                    items:
                    _categories.map((cat) {

                      return DropdownMenuItem<Category>(

                        value: cat,

                        child:
                        Text(cat.name),
                      );

                    }).toList(),

                    onChanged: (value) {

                      setState(() {

                        _selectedCategory =
                            value;
                      });
                    },
                  )

                      : Container(

                    padding:
                    const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4),

                    decoration:
                    BoxDecoration(

                      color:
                      Colors.blue.shade50,

                      borderRadius:
                      BorderRadius.circular(
                          20),
                    ),

                    child: Text(

                      widget.product.categoryName,

                      style:
                      const TextStyle(
                        color:
                        Colors.blue,
                        fontSize: 12,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // =====================================
                  // PRICE
                  // =====================================

                  _isAdmin

                      ? TextField(

                    controller:
                    _priceController,

                    keyboardType:
                    TextInputType.number,

                    decoration:
                    const InputDecoration(
                      labelText:
                      "Price",
                    ),
                  )

                      : Text(

                    "₹${widget.product.price}",

                    style:
                    const TextStyle(

                      fontSize: 26,

                      fontWeight:
                      FontWeight.bold,

                      color:
                      Colors.green,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // =====================================
                  // STOCK
                  // =====================================

                  _isAdmin

                      ? TextField(

                    controller:
                    _stockController,

                    keyboardType:
                    TextInputType.number,

                    decoration:
                    const InputDecoration(
                      labelText:
                      "Stock",
                    ),
                  )

                      : Text(

                    widget.product.stock > 0

                        ? "In Stock (${widget.product.stock})"

                        : "Out of Stock",

                    style: TextStyle(

                      fontSize: 14,

                      color:
                      widget.product.stock > 0
                          ? Colors.green
                          : Colors.red,

                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // =====================================
                  // IMAGE URL + UPLOAD
                  // =====================================

                  if (_isAdmin)

                    Column(

                      crossAxisAlignment:
                      CrossAxisAlignment.start,

                      children: [

                        TextField(

                          controller:
                          _imageController,

                          decoration:
                          const InputDecoration(
                            labelText:
                            "Image URL",
                          ),

                          onChanged: (_) {

                            setState(() {});
                          },
                        ),

                        const SizedBox(height: 12),

                        SizedBox(

                          width:
                          double.infinity,

                          child:
                          ElevatedButton.icon(

                            onPressed:
                            _isUploadingImage
                                ? null
                                : _pickAndUploadImage,

                            icon:
                            _isUploadingImage

                                ? const SizedBox(

                              width: 18,
                              height: 18,

                              child:
                              CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )

                                : const Icon(
                              Icons.upload,
                            ),

                            label: Text(

                              _isUploadingImage

                                  ? "Uploading..."

                                  : "Upload Image",
                            ),
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: 20),

                  // =====================================
                  // DESCRIPTION
                  // =====================================

                  const Text(

                    "Product Description",

                    style: TextStyle(

                      fontSize: 18,

                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  _isAdmin

                      ? TextField(

                    controller:
                    _descriptionController,

                    maxLines: 5,

                    decoration:
                    const InputDecoration(
                      border:
                      OutlineInputBorder(),
                    ),
                  )

                      : Text(

                    widget.product.description
                        .isNotEmpty

                        ? widget.product.description

                        : "No description available.",

                    style:
                    const TextStyle(
                        fontSize: 15),
                  ),

                  const SizedBox(height: 30),

                  const Divider(),

                  const SizedBox(height: 20),

                  Row(

                    children: [

                      const Expanded(

                        child: Text(

                          "Customer Reviews",

                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      if (!_isAdmin)

                        ElevatedButton.icon(

                          onPressed:
                          _showAddReviewDialog,

                          icon: const Icon(
                            Icons.rate_review,
                          ),

                          label: const Text(
                            "Review",
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  if (_loadingReviews)

                    const Center(
                      child: CircularProgressIndicator(),
                    )

                  else if (_reviews.isEmpty)

                    const Text(
                      "No reviews yet",
                    )

                  else

                    Column(

                      children: _reviews.map((review) {

                        return Card(

                          margin: const EdgeInsets.only(
                            bottom: 12,
                          ),

                          child: Padding(

                            padding: const EdgeInsets.all(12),

                            child: Column(

                              crossAxisAlignment:
                              CrossAxisAlignment.start,

                              children: [

                                Row(

                                  children: [

                                    Text(
                                      review.username,
                                      style: const TextStyle(
                                        fontWeight:
                                        FontWeight.bold,
                                      ),
                                    ),

                                    const Spacer(),

                                    Row(

                                      children: List.generate(

                                        review.rating,

                                            (index) => const Icon(
                                          Icons.star,
                                          color: Colors.amber,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 8),

                                Text(
                                  review.comment,
                                ),
                              ],
                            ),
                          ),
                        );

                      }).toList(),
                    ),

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}