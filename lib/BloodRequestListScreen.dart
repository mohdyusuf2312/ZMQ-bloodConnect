import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BloodRequestListScreen extends StatefulWidget {
  const BloodRequestListScreen({Key? key}) : super(key: key);

  @override
  State<BloodRequestListScreen> createState() => _BloodRequestListScreenState();
}

class _BloodRequestListScreenState extends State<BloodRequestListScreen> {
  String _selectedBloodGroup = 'All';
  String _selectedStatus = 'All';
  String _searchKeyword = '';

  final List<String> _bloodGroups = [
    'All',
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-',
  ];

  final List<String> _statusOptions = [
    'All',
    'Pending',
    'Expired',
    'Fulfilled',
  ];

  String _getStatus(Map<String, dynamic> data) {
    if (data['status'] == 'Fulfilled') return 'Fulfilled';
    if (data['timestamp'] == null) return 'Pending';
    final createdAt = (data['timestamp'] as Timestamp).toDate();
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    return difference.inHours >= 48 ? 'Expired' : 'Pending';
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Fulfilled':
        return Colors.green;
      case 'Expired':
        return Colors.red;
      case 'Pending':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  Color _urgencyColor(String urgency) {
    switch (urgency.toLowerCase()) {
      case 'low':
        return Colors.green.shade300;
      case 'medium':
        return Colors.orange.shade400;
      case 'high':
        return Colors.deepOrange;
      case 'critical':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<void> _markAsFulfilled(DocumentReference docRef) async {
    await docRef.update({'status': 'Fulfilled'});
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Marked as Fulfilled')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Blood Requests'),
        backgroundColor: Colors.redAccent,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Search by City or Hospital',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _searchKeyword = value.toLowerCase();
                });
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedBloodGroup,
                    decoration: const InputDecoration(
                      labelText: 'Blood Group',
                      border: OutlineInputBorder(),
                    ),
                    items: _bloodGroups.map((group) {
                      return DropdownMenuItem(value: group, child: Text(group));
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedBloodGroup = value!;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedStatus,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                    ),
                    items: _statusOptions.map((status) {
                      return DropdownMenuItem(
                        value: status,
                        child: Text(status),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedStatus = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('blood_requests')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No blood requests found.'));
                }

                final filteredDocs = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final status = _getStatus(data);
                  final groupMatch =
                      _selectedBloodGroup == 'All' ||
                      data['bloodGroup'] == _selectedBloodGroup;
                  final statusMatch =
                      _selectedStatus == 'All' || status == _selectedStatus;
                  final searchMatch =
                      _searchKeyword.isEmpty ||
                      (data['city']?.toString().toLowerCase().contains(
                            _searchKeyword,
                          ) ??
                          false) ||
                      (data['hospital']?.toString().toLowerCase().contains(
                            _searchKeyword,
                          ) ??
                          false);
                  return groupMatch && statusMatch && searchMatch;
                }).toList();

                return ListView.separated(
                  padding: const EdgeInsets.all(12.0),
                  itemCount: filteredDocs.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 8.0),
                  itemBuilder: (context, index) {
                    final doc = filteredDocs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final status = _getStatus(data);

                    return Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "${data['name']}  •  ${data['bloodGroup']}",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _statusColor(status),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    status,
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text("Hospital: ${data['hospital']}"),
                            Text("City: ${data['city']}"),
                            Text("Contact: ${data['contact']}"),
                            const SizedBox(height: 6),

                            // 👇 Urgency shown below contact
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _urgencyColor(data['urgency'] ?? ''),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                data['urgency'] ?? '',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),

                            const SizedBox(height: 8),
                            if (status != 'Fulfilled')
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton.icon(
                                  onPressed: () =>
                                      _markAsFulfilled(doc.reference),
                                  icon: const Icon(Icons.check_circle_outline),
                                  label: const Text('Mark as Fulfilled'),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
