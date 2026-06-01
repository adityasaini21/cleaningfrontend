import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/order.dart';
import '../services/order_history_service.dart';

import 'deleted_products_screen.dart';

class AdminOrdersScreen extends StatefulWidget {

  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() =>
      _AdminOrdersScreenState();
}

class _AdminOrdersScreenState
    extends State<AdminOrdersScreen> {

  final OrderHistoryService _service =
  OrderHistoryService();

  late Future<List<OrderModel>> _orders;

  @override
  void initState() {

    super.initState();

    _loadOrders();
  }

  // =====================================
  // LOAD ORDERS
  // =====================================

  void _loadOrders() {

    _orders = _service.fetchAllOrders();
  }

  // =====================================
  // UPDATE STATUS
  // =====================================

  Future<void> _updateStatus({

    required int orderId,

    required String status,

  }) async {

    try {

      await _service.updateOrderStatus(
        orderId: orderId,
        status: status,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(

        SnackBar(
          content:
          Text("Order updated to $status"),
        ),
      );

      setState(() {
        _loadOrders();
      });

    } catch (e) {

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(

        const SnackBar(
          content:
          Text("Failed to update status"),
        ),
      );
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

    return
      "${date.day}/${date.month}/${date.year}";
  }

  bool _isToday(DateTime date) {

    final now = DateTime.now();

    return date.day == now.day &&
        date.month == now.month &&
        date.year == now.year;
  }

  bool _isThisWeek(DateTime date) {

    final now = DateTime.now();

    final difference =
        now.difference(date).inDays;

    return difference >= 0 &&
        difference < 7;
  }

  bool _isThisMonth(DateTime date) {

    final now = DateTime.now();

    return date.month == now.month &&
        date.year == now.year;
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(

        title:
        const Text("Admin Dashboard"),

        actions: [

          IconButton(

            icon: const Icon(Icons.delete),

            onPressed: () {

              Navigator.push(

                context,

                MaterialPageRoute(
                  builder: (_) =>
                  const DeletedProductsScreen(),
                ),
              );
            },
          ),
        ],
      ),

      body: FutureBuilder<List<OrderModel>>(

        future: _orders,

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

          final orders =
          snapshot.data!.reversed.toList();

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

          return RefreshIndicator(

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
                  final deliveryNameController =
                  TextEditingController(
                    text: order.deliveryBoyName,
                  );

                  final deliveryPhoneController =
                  TextEditingController(
                    text: order.deliveryBoyPhone,
                  );

                  return Card(

                    margin:
                    const EdgeInsets.only(
                      bottom: 16,
                    ),

                    shape:
                    RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(
                        16,
                      ),
                    ),

                    child: ExpansionTile(

                      title: Text(
                        "Order #${order.orderId}",

                        style: const TextStyle(
                          fontWeight:
                          FontWeight.bold,
                        ),
                      ),

                      subtitle: Column(

                        crossAxisAlignment:
                        CrossAxisAlignment.start,

                        children: [

                          const SizedBox(height: 6),

                          Text(
                            _formatDate(
                              order.createdAt,
                            ),
                          ),

                          const SizedBox(height: 6),

                          Text(
                            "₹${order.totalAmount}",

                            style:
                            const TextStyle(
                              fontWeight:
                              FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 6),

                          Container(

                            padding:
                            const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),

                            decoration:
                            BoxDecoration(

                              color:
                              _statusColor(
                                order.orderStatus,
                              ).withOpacity(0.15),

                              borderRadius:
                              BorderRadius.circular(20),
                            ),

                            child: Text(
                              order.orderStatus,

                              style: TextStyle(
                                color:
                                _statusColor(
                                  order.orderStatus,
                                ),

                                fontWeight:
                                FontWeight.bold,
                              ),
                            ),
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
                            ],
                          ),
                        ),

                        const Padding(

                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                          ),

                          child: Align(

                            alignment: Alignment.centerLeft,

                            child: Text(

                              "Ordered Products",

                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
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

                        const Divider(),

                        Padding(

                          padding: const EdgeInsets.all(16),

                          child: Column(

                            children: [

                              TextField(

                                controller: deliveryNameController,

                                decoration: const InputDecoration(

                                  labelText: "Delivery Boy Name",

                                  border: OutlineInputBorder(),
                                ),
                              ),

                              const SizedBox(height: 12),

                              TextField(

                                controller: deliveryPhoneController,

                                keyboardType: TextInputType.phone,

                                decoration: const InputDecoration(

                                  labelText: "Delivery Boy Phone",

                                  border: OutlineInputBorder(),
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

                                    try {

                                      await _service.assignDeliveryBoy(

                                        orderId: order.orderId,

                                        deliveryBoyName:
                                        deliveryNameController.text,

                                        deliveryBoyPhone:
                                        deliveryPhoneController.text,
                                      );

                                      if (!mounted) return;

                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(

                                        const SnackBar(

                                          content: Text(
                                            "Delivery boy assigned",
                                          ),
                                        ),
                                      );

                                      setState(() {
                                        _loadOrders();
                                      });

                                    } catch (e) {

                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(

                                        const SnackBar(

                                          content: Text(
                                            "Assignment failed",
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),

                        const Divider(),

                        Padding(

                          padding:
                          const EdgeInsets.all(16),

                          child:
                          DropdownButtonFormField<String>(

                            value:
                            order.orderStatus,

                            decoration:
                            const InputDecoration(
                              labelText:
                              "Update Status",

                              border:
                              OutlineInputBorder(),
                            ),

                            items: [

                              "CREATED",

                              "CONFIRMED",

                              "OUT_FOR_DELIVERY",

                              "DELIVERED",

                              "CANCELLED"

                            ].map((status) {

                              return DropdownMenuItem(

                                value: status,

                                child: Text(status),
                              );

                            }).toList(),

                            onChanged: (value) {

                              if (value == null)
                                return;

                              _updateStatus(
                                orderId:
                                order.orderId,

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

        color:
        color.withOpacity(0.12),

        borderRadius:
        BorderRadius.circular(18),
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