//user_history.dart
import 'package:flutter/material.dart';
import 'package:frontend/pages/admin/admin_home.dart';
import 'package:frontend/pages/admin/admin_nav_bar.dart';
import 'package:frontend/pages/service/admin_user_service.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final AdminUserService _adminUserService = AdminUserService();

  List<UserData> users = [];
  bool _isLoading = true;

  String? selectedUserId;
  String selectedDetailType = 'reservations';
  bool _showAllPayments = false;
  int _totalUsers = 0;

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _fetchTotalUsers();
  }

  Future<void> _fetchTotalUsers() async {
    try {
      final total = await _adminUserService.fetchTotalUsers();
      setState(() {
        _totalUsers = total;
      });
    } catch (e) {
      print("Error fetching total users: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to fetch total users')),
      );
    }
  }

  Future<void> _loadUsers() async {
    try {
      setState(() => _isLoading = true);
      final userList = await _adminUserService.fetchUsers();
      setState(() {
        users =
            userList
                .map(
                  (u) => UserData(
                    id: u['uid'] ?? '',
                    name: u['displayName'] ?? "No Name",
                    email: u['email'] ?? "No Email",
                    isBlacklisted: u['disabled'] ?? false,
                    sessions: [],
                    payments: [],
                    reservations: [],
                    vehicles: [],
                  ),
                )
                .toList();
        _isLoading = false;
      });
    } catch (e) {
      print("Error loading users: $e");
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load users: $e')));
    }
  }

  Future<void> _fetchUserDetails(String userId) async {
    if (users.isEmpty) {
      print("Users list is empty, reloading users first...");
      await _loadUsers();
    }

    try {
      final details = await _adminUserService.fetchUserDetails(userId);
      print("Raw backend details: $details");

      final firestoreData = details['firestoreData'] ?? {};

      // ✅ Fetch payments from backend
      final payments = await _adminUserService.fetchUserPayments(userId);

      setState(() {
        users =
            users.map((user) {
              if (user.id == userId) {
                return user.copyWith(
                  sessions:
                      (firestoreData['Sessions_history'] as List<dynamic>? ??
                              [])
                          .map((e) => Map<String, dynamic>.from(e))
                          .toList(),
                  payments: payments,
                  reservations:
                      (firestoreData['Reservation_history'] as List<dynamic>? ??
                              [])
                          .map((e) => Map<String, dynamic>.from(e))
                          .toList(),
                  vehicles:
                      (firestoreData['vehicles'] as List<dynamic>? ?? [])
                          .map((e) => Map<String, dynamic>.from(e))
                          .toList(),
                );
              }
              return user;
            }).toList();
      });
    } catch (e) {
      print("Error fetching details for user $userId: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load user details: $e')),
      );
    }
  }

  void _toggleAllPayments() {
    setState(() {
      _showAllPayments = !_showAllPayments;
      selectedUserId = null;
    });
  }

  Future<void> _toggleBlacklist(String userId, bool newStatus) async {
    try {
      await _adminUserService.toggleBlacklist(userId, newStatus);

      setState(() {
        users =
            users.map((user) {
              if (user.id == userId) {
                return user.copyWith(isBlacklisted: newStatus);
              }
              return user;
            }).toList();
      });

      final user = users.firstWhere((u) => u.id == userId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newStatus
                ? '${user.name} has been blocked'
                : '${user.name} has been unblocked',
          ),
          backgroundColor: newStatus ? Colors.orange : Colors.green,
        ),
      );
    } catch (e) {
      print("Error toggling blacklist: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to update status: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showUserDetails(String userId, String detailType) async {
    await _fetchUserDetails(userId);
    setState(() {
      selectedUserId = userId;
      selectedDetailType = detailType;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF25303B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF25303B),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const AdminHomePage()),
              (route) => false,
            );
          },
        ),
        title: const Text(
          "User Management",
          style: TextStyle(
            fontSize: 24,
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.payment, color: Colors.white),
            tooltip: "View All Payments",
            onPressed: _toggleAllPayments,
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadUsers,
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Colors.tealAccent),
              )
              : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      "Total Users: $_totalUsers",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        final user = users[index];
                        return _buildUserCard(user);
                      },
                    ),
                  ),
                  if (selectedUserId != null) _buildDetailPanel(),
                  if (_showAllPayments) _buildAllPaymentsPanel(),
                ],
              ),
      bottomNavigationBar: const AdminNavBar(currentPage: 'history'),
    );
  }

  Widget _buildAllPaymentsPanel() {
    List<Map<String, dynamic>> allPayments = [];
    for (var user in users) {
      for (var payment in user.payments) {
        allPayments.add({
          "userId": user.id,
          "userName": user.name,
          "paymentDetails": payment,
        });
      }
    }

    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF25303B),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "All Payments",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white70),
                onPressed: () => setState(() => _showAllPayments = false),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child:
                allPayments.isEmpty
                    ? const Center(
                      child: Text(
                        "No payments found",
                        style: TextStyle(color: Colors.white70),
                      ),
                    )
                    : ListView.builder(
                      itemCount: allPayments.length,
                      itemBuilder: (context, index) {
                        final payment = allPayments[index];
                        final details = payment['paymentDetails'];
                        return Card(
                          color: const Color(0xFF3A4A5A),
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            leading: const Icon(
                              Icons.payment,
                              color: Colors.tealAccent,
                            ),
                            title: Text(
                              "Amount: \$${details['amount']?.toStringAsFixed(2) ?? '0.00'}",
                              style: const TextStyle(color: Colors.white),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "User: ${payment['userName']} (ID: ${payment['userId']})",
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                  ),
                                ),
                                Text(
                                  "Date: ${details['date'] ?? 'Unknown'}",
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                  ),
                                ),
                                Text(
                                  "Method: ${details['method'] ?? 'Unknown'}",
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                  ),
                                ),
                                if (details['status'] != null)
                                  Text(
                                    "Status: ${details['status']}",
                                    style: TextStyle(
                                      color:
                                          details['status'] == 'completed'
                                              ? Colors.green
                                              : Colors.orange,
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
    );
  }

  Widget _buildUserCard(UserData user) {
    final isSelected = selectedUserId == user.id;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: const Color(0xFF3A4A5A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side:
            isSelected
                ? const BorderSide(color: Colors.tealAccent, width: 2)
                : BorderSide.none,
      ),
      elevation: 4,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: CircleAvatar(
          backgroundColor: Colors.tealAccent.withOpacity(0.1),
          child: const Icon(Icons.person, color: Colors.tealAccent),
        ),
        title: Text(
          user.name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          user.email,
          style: TextStyle(color: Colors.white.withOpacity(0.7)),
        ),
        trailing: Wrap(
          spacing: 4,
          children: [
            IconButton(
              icon: Icon(
                user.isBlacklisted ? Icons.block : Icons.check_circle,
                color: user.isBlacklisted ? Colors.red : Colors.green,
              ),
              onPressed: () => _toggleBlacklist(user.id, !user.isBlacklisted),
            ),
            const Icon(Icons.arrow_drop_down, color: Colors.white70),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16).copyWith(top: 0),
            child: Column(
              children: [
                _buildDetailRow(Icons.person, "User ID", user.id),
                _buildDetailRow(
                  Icons.account_circle,
                  "Status",
                  user.isBlacklisted ? "Blacklisted" : "Active",
                  user.isBlacklisted ? Colors.red : Colors.green,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildActionButton(
                      "Reservations",
                      Icons.calendar_today,
                      () => _showUserDetails(user.id, 'reservations'),
                    ),
                    _buildActionButton(
                      "Payments",
                      Icons.payment,
                      () => _showUserDetails(user.id, 'payments'),
                    ),
                    _buildActionButton(
                      "Sessions",
                      Icons.ev_station,
                      () => _showUserDetails(user.id, 'sessions'),
                    ),
                    _buildActionButton(
                      "Vehicles",
                      Icons.directions_car,
                      () => _showUserDetails(user.id, 'vehicles'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailPanel() {
    final user = users.firstWhere((u) => u.id == selectedUserId!);
    List<dynamic> details = [];
    String title = '';
    IconData icon = Icons.info;

    switch (selectedDetailType) {
      case 'reservations':
        details = user.reservations;
        title = 'Reservation History';
        icon = Icons.calendar_today;
        break;
      case 'sessions':
        details = user.sessions;
        title = ' Sessions';
        icon = Icons.ev_station;
        break;
      case 'payments':
        details = user.payments;
        title = 'Payment History';
        icon = Icons.payment;
        break;
      case 'vehicles':
        details = user.vehicles;
        title = 'Registered Vehicles';
        icon = Icons.directions_car;
        break;
    }

    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF25303B),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, color: Colors.tealAccent),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white70),
                onPressed: () => setState(() => selectedUserId = null),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child:
                details.isEmpty
                    ? Center(
                      child: Text(
                        "No $selectedDetailType found",
                        style: const TextStyle(color: Colors.white70),
                      ),
                    )
                    : ListView.builder(
                      itemCount: details.length,
                      itemBuilder: (context, index) {
                        final item = details[index];
                        if (selectedDetailType == 'vehicles') {
                          return ListTile(
                            leading: const Icon(
                              Icons.directions_car,
                              color: Colors.tealAccent,
                            ),
                            title: Text(
                              "${item['name'] ?? 'Vehicle'}",
                              style: const TextStyle(color: Colors.white),
                            ),
                            subtitle: Text(
                              "Plate Number: ${item['plateNumber'] ?? 'N/A'}\n"
                              "Default: ${item['isDefault'] == true ? 'Yes' : 'No'}\n"
                              "Image: ${item['image'] ?? ''}",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                              ),
                            ),
                          );
                        } else {
                          return Card(
                            color: const Color(0xFF3A4A5A),
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: ListTile(
                              leading: Icon(icon, color: Colors.tealAccent),
                              title: Text(
                                _getPrimaryDetail(item),
                                style: const TextStyle(color: Colors.white),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: _getDetailLines(item),
                              ),
                            ),
                          );
                        }
                      },
                    ),
          ),
        ],
      ),
    );
  }

  String _getPrimaryDetail(Map<String, dynamic> item) {
    switch (selectedDetailType) {
      case 'reservations':
        //Protect against missing keys
        return "Reservation Slot: ${item['slotId'] ?? item['floor'] ?? 'N/A'}";

      case 'sessions':
        final slotId = item['slotId'] ?? 'N/A';
        final duration = item['duration'] ?? 'Unknown';
        return "Slot: $slotId | Duration: $duration";

      case 'payments':
        return "Payment: \$${item['amount']?.toStringAsFixed(2) ?? '0.00'}";
      default:
        return item.toString();
    }
  }

  List<Widget> _getDetailLines(Map<String, dynamic> item) {
    return item.entries.map((entry) {
      if (selectedDetailType == 'reservations' &&
          (entry.key == 'slotId' || entry.key == 'floor')) {
        return const SizedBox.shrink();
      }
      if (selectedDetailType == 'sessions' &&
          (entry.key == 'slotId' || entry.key == 'duration')) {
        return const SizedBox.shrink();
      }
      if (selectedDetailType == 'payments' && entry.key == 'amount') {
        return const SizedBox.shrink();
      }
      return Text(
        "${entry.key}: ${entry.value}",
        style: TextStyle(color: Colors.white.withOpacity(0.7)),
      );
    }).toList();
  }

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value, [
    Color? color,
  ]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color ?? Colors.white70, size: 20),
          const SizedBox(width: 12),
          Text("$label: ", style: const TextStyle(color: Colors.white70)),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                color: color ?? Colors.white,
                fontWeight: FontWeight.w500,
              ),
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String text,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return Column(
      children: [
        IconButton(
          icon: Icon(icon, color: Colors.tealAccent),
          onPressed: onPressed,
        ),
        Text(text, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }
}

class UserData {
  final String id;
  final String name;
  final String email;
  final bool isBlacklisted;
  final List<Map<String, dynamic>> sessions;
  final List<Map<String, dynamic>> payments;
  final List<Map<String, dynamic>> reservations;
  final List<Map<String, dynamic>> vehicles;

  UserData({
    required this.id,
    required this.name,
    required this.email,
    required this.isBlacklisted,
    required this.sessions,
    required this.payments,
    required this.reservations,
    required this.vehicles,
  });

  UserData copyWith({
    String? id,
    String? name,
    String? email,
    bool? isBlacklisted,
    List<Map<String, dynamic>>? sessions,
    List<Map<String, dynamic>>? payments,
    List<Map<String, dynamic>>? reservations,
    List<Map<String, dynamic>>? vehicles,
  }) {
    return UserData(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      isBlacklisted: isBlacklisted ?? this.isBlacklisted,
      sessions: sessions ?? this.sessions,
      payments: payments ?? this.payments,
      reservations: reservations ?? this.reservations,
      vehicles: vehicles ?? this.vehicles,
    );
  }
}
