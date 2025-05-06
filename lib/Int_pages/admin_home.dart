import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'common_layout.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Appointment> _appointments = [];
  final Map<String, Map<String, dynamic>> _appointmentDetailsMap = {};

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    FirebaseFirestore.instance.collection('appointments').snapshots().listen((snapshot) {
      List<Appointment> loadedAppointments = [];
      Map<String, Map<String, dynamic>> detailsMap = {};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final docId = doc.id;

        if (data['Date'] == null || data['ProviderName'] == null || data['Time'] == null || data['CustomerEmail'] == null) {
          continue;
        }

        final DateTime startTime = (data['Date'] as Timestamp).toDate();
        final DateTime endTime = startTime.add(const Duration(minutes: 45));

        final appointment = Appointment(
          startTime: startTime,
          endTime: endTime,
          subject: ' ',
          color: Colors.blue,
          notes: docId,
        );

        loadedAppointments.add(appointment);

        detailsMap[docId] = {
          'providerName': data['ProviderName'] ?? 'Unknown',
          'customerEmail': data['CustomerEmail'] ?? 'N/A',
          'date': startTime,
          'time': data['Time'] ?? 'N/A',
          'status': data['status'] ?? 'Pending',
        };
      }

      setState(() {
        _appointments = loadedAppointments;
        _appointmentDetailsMap.clear();
        _appointmentDetailsMap.addAll(detailsMap);
      });
    });
  }

  void _onAppointmentTap(CalendarTapDetails details) {
    if (details.targetElement != CalendarElement.calendarCell || details.date == null) return;

    final DateTime tappedDate = details.date!;
    final appointmentsForDate = _appointments.where((a) =>
        a.startTime.year == tappedDate.year &&
        a.startTime.month == tappedDate.month &&
        a.startTime.day == tappedDate.day).toList();

    if (appointmentsForDate.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No appointments for this date.")),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: appointmentsForDate.length,
          separatorBuilder: (_, __) => const Divider(),
          itemBuilder: (context, index) {
            final appointment = appointmentsForDate[index];
            final docId = appointment.notes;
            final details = _appointmentDetailsMap[docId];

            if (details == null) return const SizedBox();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Provider: ${details['providerName']}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Customer Email: ${details['customerEmail']}'),
                Text('Time: ${details['time']}'),
                Text('Status: ${details['status']}'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () => _updateAppointmentStatus(docId!, 'approved', details['customerEmail']),
                      child: const Text('Approve'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => _updateAppointmentStatus(docId!, 'rescheduled', details['customerEmail']),
                      child: const Text('Reschedule'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => _updateAppointmentStatus(docId!, 'cancelled', details['customerEmail']),
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _updateAppointmentStatus(String docId, String newStatus, String customerEmail) async {
    try {
      await FirebaseFirestore.instance.collection('appointments').doc(docId).update({
        'status': newStatus,
      });

      await FirebaseFirestore.instance.collection('mail').add({
        'to': customerEmail,
        'message': {
          'subject': 'Appointment $newStatus',
          'html': '<p>Your appointment has been <strong>$newStatus</strong>.</p>',
        },
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Appointment $newStatus and email sent to $customerEmail')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update appointment status.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return CommonLayout(
      selectedIndex: 0,
      body: Container(
        width: double.infinity,
        height: MediaQuery.of(context).size.height,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.greenAccent, Colors.blueAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SfCalendar(
          view: CalendarView.month,
          dataSource: AppointmentDataSource(_appointments),
          onTap: _onAppointmentTap,
          monthViewSettings: const MonthViewSettings(
            appointmentDisplayMode: MonthAppointmentDisplayMode.indicator,
            showAgenda: false,
          ),
        ),
      ),
    );
  }
}

class AppointmentDataSource extends CalendarDataSource {
  AppointmentDataSource(List<Appointment> appointments) {
    this.appointments = appointments;
  }
}
