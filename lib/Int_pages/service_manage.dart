import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'common_layout.dart';

class ServiceScreen extends StatelessWidget {
  const ServiceScreen({super.key});

  void _deleteService(String id) {
    FirebaseFirestore.instance.collection('services').doc(id).delete();
  }

  void _showAddServiceDialog(BuildContext context) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final logoUrlController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text("Add New Service"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                TextField(
                  controller: logoUrlController,
                  decoration: const InputDecoration(labelText: 'Logo Image URL'),
                ),
                const SizedBox(height: 10),
                if (logoUrlController.text.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Image.network(
                      logoUrlController.text,
                      height: 60,
                      errorBuilder: (context, error, stackTrace) {
                        return const Text("Invalid image URL");
                      },
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                FirebaseFirestore.instance.collection('services').add({
                  'Name': nameController.text,
                  'Description': descriptionController.text,
                  'logoUrl': logoUrlController.text.trim(),
                });
                Navigator.pop(context);
              },
              child: const Text("Add"),
            ),
          ],
        ),
      ),
    );
  }

  void _showUpdateServiceDialog(BuildContext context, DocumentSnapshot doc) {
    final nameController = TextEditingController(text: doc['Name']);
    final descriptionController = TextEditingController(text: doc['Description']);
    final logoUrlController = TextEditingController(text: doc['logoUrl'] ?? '');

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text("Update Service"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                TextField(
                  controller: logoUrlController,
                  decoration: const InputDecoration(labelText: 'Logo Image URL'),
                  onChanged: (value) => setState(() {}),
                ),
                const SizedBox(height: 10),
                if (logoUrlController.text.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Image.network(
                      logoUrlController.text,
                      height: 60,
                      errorBuilder: (context, error, stackTrace) {
                        return const Text("Invalid image URL");
                      },
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                FirebaseFirestore.instance.collection('services').doc(doc.id).update({
                  'Name': nameController.text,
                  'Description': descriptionController.text,
                  'logoUrl': logoUrlController.text.trim(),
                });
                Navigator.pop(context);
              },
              child: const Text("Update"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CommonLayout(
      selectedIndex: 3,
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
              stream: FirebaseFirestore.instance.collection('services').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final services = snapshot.data!.docs;
                if (services.isEmpty) {
                  return const Center(child: Text("No services found."));
                }

                return ListView.builder(
                  itemCount: services.length,
                  itemBuilder: (context, index) {
                    final service = services[index];
                    return Card(
                      child: ListTile(
                        leading: service['logoUrl'] != null && service['logoUrl'].toString().isNotEmpty
                            ? CircleAvatar(backgroundImage: NetworkImage(service['logoUrl']))
                            : const CircleAvatar(child: Icon(Icons.image_not_supported)),
                        title: Text(service['Name']),
                        subtitle: Text(service['Description']),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _showUpdateServiceDialog(context, service),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteService(service.id),
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
            onPressed: () => _showAddServiceDialog(context),
            backgroundColor: Colors.green,
            child: const Icon(Icons.add),
          ),
        ),
      ),
    );
  }
}
