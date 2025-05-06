import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:appointment_booking_system/Ex_pages/customerlogin.dart';

class CustomerHome extends StatelessWidget {
  const CustomerHome({super.key});

  Future<void> _logout(BuildContext context) async {
  try {
    final confirmLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmLogout == true) {
      await FirebaseAuth.instance.signOut();
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => LoginPage()),
          (Route<dynamic> route) => false,
        );
      }
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logout failed. Please try again.')),
      );
    }
  }
}


  void _bookAppointment(BuildContext context, DocumentSnapshot service) async {
    final scaffoldContext = context;
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      ScaffoldMessenger.of(scaffoldContext).showSnackBar(
        const SnackBar(content: Text('Please log in to book an appointment.')),
      );
      return;
    }

    final providerId = service.id;
    final providerName = service['Name'];

    DateTime? selectedDate;
    String? selectedTimeSlot;
    TextEditingController dateController = TextEditingController();

    List<String> generateTimeSlots() {
      List<String> slots = [];
      TimeOfDay time = const TimeOfDay(hour: 8, minute: 30);
      while (time.hour < 16 || (time.hour == 16 && time.minute <= 30)) {
        slots.add(time.format(context));
        final totalMinutes = time.hour * 60 + time.minute + 45;
        time = TimeOfDay(hour: totalMinutes ~/ 60, minute: totalMinutes % 60);
      }
      return slots;
    }

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          List<String> allSlots = generateTimeSlots();
          List<String> availableSlots = List.from(allSlots);

          return AlertDialog(
            title: Text("Book with $providerName"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  readOnly: true,
                  controller: dateController,
                  decoration: const InputDecoration(labelText: 'Date'),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      selectedDate = picked;
                      dateController.text = picked.toIso8601String().split('T').first;

                      final formattedDate = dateController.text;

                      // Get existing bookings for the provider on selected date
                      final bookings = await FirebaseFirestore.instance
                          .collection('appointments')
                          .where('ProviderId', isEqualTo: providerId)
                          .where('Date', isEqualTo: formattedDate)
                          .get();

                      final bookedSlots = bookings.docs.map((doc) => doc['Time'] as String).toSet();
                      availableSlots = allSlots.where((slot) => !bookedSlots.contains(slot)).toList();

                      selectedTimeSlot = null;
                      setState(() {});
                    }
                  },
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: selectedTimeSlot,
                  items: availableSlots
                      .map((slot) => DropdownMenuItem(value: slot, child: Text(slot)))
                      .toList(),
                  onChanged: (value) => setState(() => selectedTimeSlot = value),
                  decoration: const InputDecoration(labelText: 'Select Time Slot'),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: selectedDate != null && selectedTimeSlot != null
                    ? () async {
                        final dateStr = selectedDate!.toIso8601String().split('T').first;

                        // Check if time slot already booked for this provider, date, and time
                        final existingSlotBooking = await FirebaseFirestore.instance
                            .collection('appointments')
                            .where('ProviderId', isEqualTo: providerId)
                            .where('Date', isEqualTo: dateStr)
                            .where('Time', isEqualTo: selectedTimeSlot)
                            .get();

                        if (existingSlotBooking.docs.isNotEmpty) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                            const SnackBar(
                                content: Text('This time slot is already booked. Please choose another.')),
                          );
                          return;
                        }

                        // Optional: Check if user already has an appointment on the same date
                        final existingCustomerBooking = await FirebaseFirestore.instance
                            .collection('appointments')
                            .where('CustomerEmail', isEqualTo: currentUser.email)
                            .where('Date', isEqualTo: dateStr)
                            .get();

                        if (existingCustomerBooking.docs.isNotEmpty) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                            const SnackBar(
                                content: Text('You already have an appointment on this date.')),
                          );
                          return;
                        }

                        await FirebaseFirestore.instance.collection('appointments').add({
                          'ProviderId': providerId,
                          'ProviderName': providerName,
                          'CustomerEmail': currentUser.email,
                          'Date': dateStr,
                          'Time': selectedTimeSlot,
                          'status': 'pending',
                        });

                        Navigator.pop(context);
                        ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                          const SnackBar(content: Text('Appointment booked successfully')),
                        );
                      }
                    : null,
                child: const Text('Confirm'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'AppoiMate',
          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black45),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.redAccent, Colors.purpleAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: () => _logout(context)),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.redAccent, Colors.purpleAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('services').snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

            final services = snapshot.data!.docs;

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: services.length,
              itemBuilder: (context, index) {
                final service = services[index];

                return Card(
                  color: const Color(0xFF00BFA5),
                  shadowColor: Colors.purpleAccent.withOpacity(0.3),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    
                    leading: service['logoUrl'] != null
                        ? CircleAvatar(backgroundImage: NetworkImage(service['logoUrl']))
                        : const Icon(Icons.business, color: Colors.purpleAccent),
                    title: Text(
                      service['Name'] ?? 'Unnamed',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    trailing: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onPressed: () => _bookAppointment(context, service),
                      child: const Text('Book'),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
