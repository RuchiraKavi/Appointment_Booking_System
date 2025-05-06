import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'common_layout.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  void _deleteAdmin(String id) {
    FirebaseFirestore.instance.collection('admin').doc(id).delete();
  }

  void _showUpdateDialog(BuildContext context, DocumentSnapshot adminDoc) {
    final nameController = TextEditingController(text: adminDoc['Name']);
    final emailController = TextEditingController(text: adminDoc['E-mail']);
    final passwordController = TextEditingController(text: adminDoc['Password']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Update Admin"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
            TextField(controller: emailController, decoration: const InputDecoration(labelText: 'E-mail')),
            TextField(controller: passwordController, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              FirebaseFirestore.instance.collection('admin').doc(adminDoc.id).update({
                'Name': nameController.text,
                'E-mail': emailController.text,
                'Password': passwordController.text,
              });
              Navigator.pop(context);
            },
            child: const Text("Update"),
          ),
        ],
      ),
    );
  }

  void _showAddAdminDialog(BuildContext context) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add New Admin"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
            TextField(controller: emailController, decoration: const InputDecoration(labelText: 'E-mail')),
            TextField(controller: passwordController, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              FirebaseFirestore.instance.collection('admin').add({
                'Name': nameController.text,
                'E-mail': emailController.text,
                'Password': passwordController.text,
              });
              Navigator.pop(context);
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
      selectedIndex: 1,
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
              stream: FirebaseFirestore.instance.collection('admin').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final admins = snapshot.data!.docs;
                if (admins.isEmpty) {
                  return const Center(child: Text("No admins found."));
                }

                return ListView.builder(
                  itemCount: admins.length,
                  itemBuilder: (context, index) {
                    final admin = admins[index];
                    return Card(
                      child: ListTile(
                        title: Text(admin['Name']),
                        subtitle: Text(admin['E-mail']),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _showUpdateDialog(context, admin),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteAdmin(admin.id),
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
            onPressed: () => _showAddAdminDialog(context),
            backgroundColor: Colors.green,
            child: const Icon(Icons.add),
          ),
        ),
      ),
    );
  }

}
