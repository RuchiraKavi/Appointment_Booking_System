import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'common_layout.dart';

class CustomerScreen extends StatelessWidget {
  const CustomerScreen({super.key});

  void _deleteCustomer(String id) {
    FirebaseFirestore.instance.collection('customer').doc(id).delete();
  }

  Future<void> _showUpdateDialog(BuildContext context, DocumentSnapshot customerDoc) async {
    final nameController = TextEditingController(text: customerDoc['full_name']);
    final emailController = TextEditingController(text: customerDoc['email']);
    final phoneController = TextEditingController(text: customerDoc['phone']);
    final nicController = TextEditingController(text: customerDoc['nic']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Update Customer"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Full Name')),
              TextField(controller: emailController, decoration: const InputDecoration(labelText: 'E-mail')),
              TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Phone')),
              TextField(controller: nicController, decoration: const InputDecoration(labelText: 'NIC')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              String newNic = nicController.text;
              // Check for NIC uniqueness (excluding current document)
              final existing = await FirebaseFirestore.instance
                  .collection('customer')
                  .where('nic', isEqualTo: newNic)
                  .get();

              bool nicExists = existing.docs.any((doc) => doc.id != customerDoc.id);

              if (nicExists) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('NIC already exists. Please use a different one.')),
                );
              } else {
                await FirebaseFirestore.instance.collection('customer').doc(customerDoc.id).update({
                  'full_name': nameController.text,
                  'email': emailController.text,
                  'phone': phoneController.text,
                  'nic': newNic,
                });
                Navigator.pop(context);
              }
            },
            child: const Text("Update"),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddCustomerDialog(BuildContext context) async {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final nicController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add New Customer"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Full Name')),
              TextField(controller: emailController, decoration: const InputDecoration(labelText: 'E-mail')),
              TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Phone')),
              TextField(controller: nicController, decoration: const InputDecoration(labelText: 'NIC')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              String nic = nicController.text;

              final existing = await FirebaseFirestore.instance
                  .collection('customer')
                  .where('nic', isEqualTo: nic)
                  .get();

              if (existing.docs.isNotEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('NIC already exists. Please use a different one.')),
                );
              } else {
                await FirebaseFirestore.instance.collection('customer').add({
                  'full_name': nameController.text,
                  'email': emailController.text,
                  'phone': phoneController.text,
                  'nic': nic,
                });
                Navigator.pop(context);
              }
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CommonLayout(
      selectedIndex: 2,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.greenAccent, Colors.blueAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Container(
            padding: const EdgeInsets.all(16),
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('customer').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final customers = snapshot.data!.docs;
                if (customers.isEmpty) {
                  return const Center(child: Text("No customers found."));
                }

                return ListView.builder(
                  itemCount: customers.length,
                  itemBuilder: (context, index) {
                    final customer = customers[index];
                    return Card(
                      child: ListTile(
                        title: Text(customer['full_name']),
                        subtitle: Text(
                          '${customer['email']} | ${customer['phone']} | NIC: ${customer['nic']}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _showUpdateDialog(context, customer),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteCustomer(customer.id),
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
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showAddCustomerDialog(context),
            backgroundColor: Colors.green,
            child: const Icon(Icons.add),
          ),
        ),
      ),
    );
  }
}

