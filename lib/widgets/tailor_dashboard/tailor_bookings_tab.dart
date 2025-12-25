import 'package:flutter/material.dart';
import '../../models/tailor.dart';
import '../../models/booking.dart';
import '../../services/firestore_tailor_service.dart';
import '../../services/firestore_bookings_service.dart';
import 'package:intl/intl.dart';

/// [Purpose]
/// Manages the Booking Calendar tab.
/// Allows the tailor to view, add, edit, and delete bookings.
/// [Feature] Configurable booking window (e.g., 3, 7, 30 days) via Settings.
class TailorBookingsTab extends StatefulWidget {
  final Tailor tailor;
  final List<Booking> bookings;
  final VoidCallback onRefresh;

  const TailorBookingsTab({
    super.key,
    required this.tailor,
    required this.bookings,
    required this.onRefresh,
  });

  @override
  State<TailorBookingsTab> createState() => _TailorBookingsTabState();
}

class _TailorBookingsTabState extends State<TailorBookingsTab> {
  final FirestoreBookingsService _bookingsService = FirestoreBookingsService();
  final FirestoreTailorService _tailorService = FirestoreTailorService();
  
  // Fixed Slots for simplicity (could be made dynamic later)
  final List<String> _timeSlots = [
    '09:00 - 11:00',
    '11:00 - 13:00',
    '14:00 - 16:00',
    '16:00 - 18:00',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 400;
              return Flex(
                direction: isNarrow ? Axis.vertical : Axis.horizontal,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: isNarrow ? CrossAxisAlignment.stretch : CrossAxisAlignment.center,
                children: [
                  Text(
                    'Booking Calendar',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    textAlign: isNarrow ? TextAlign.center : TextAlign.start,
                  ),
                  if (isNarrow) const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: isNarrow ? MainAxisAlignment.center : MainAxisAlignment.end,
                    children: [
                      // Settings Button
                      IconButton(
                        onPressed: _showBookingSettingsDialog,
                        icon: const Icon(Icons.settings),
                        tooltip: 'Configure Booking Window',
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: ElevatedButton.icon(
                          onPressed: () => _showAddBookingDialog(),
                          icon: const Icon(Icons.add),
                          label: const Text(
                            'Add Booking',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
        
        // Calendar
        _buildCalendar(),

        const SizedBox(height: 16),
        // Legend
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLegendItem('Available', Colors.green[100]!, Colors.green),
            const SizedBox(width: 16),
            _buildLegendItem('Pending', Colors.amber[100]!, Colors.amber[800]!),
            const SizedBox(width: 16),
            _buildLegendItem('Booked', Colors.red[100]!, Colors.red),
          ],
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color bg, Color border) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: border),
          ),
        ),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildCalendar() {
    // Generate days based on configurable window
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final upcomingDays = List.generate(
      widget.tailor.bookingWindowDays, 
      (index) => today.add(Duration(days: index))
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        
        // Mobile (< 480px): Stack vertically
        if (width <= 480) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: upcomingDays.map((date) => 
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 24),
                  child: _buildDayColumn(date),
                )
              ).toList(),
            ),
          );
        }
        // Tablet (481-900px): 2 Columns
        else if (width <= 900) {
          final itemWidth = (width - 48) / 2; // -48 for padding/spacing
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 16,
              runSpacing: 24,
              children: upcomingDays.map((date) => 
                SizedBox(
                  width: itemWidth,
                  child: _buildDayColumn(date),
                )
              ).toList(),
            ),
          );
        }
        // Desktop: 4 Columns
        else {
          final itemWidth = (width - 80) / 4; 
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 16,
              runSpacing: 24,
              children: upcomingDays.map((date) => 
                SizedBox(
                  width: itemWidth,
                  child: _buildDayColumn(date),
                )
              ).toList(),
            ),
          );
        }
      },
    );
  }

  Widget _buildDayColumn(DateTime date) {
    final isToday = date.day == DateTime.now().day && 
                    date.month == DateTime.now().month && 
                    date.year == DateTime.now().year;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Date Header
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isToday ? Colors.purple : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Text(
                DateFormat('E').format(date),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isToday ? Colors.white : Colors.black87,
                ),
              ),
              Text(
                date.day.toString(),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isToday ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Slots
        ..._timeSlots.map((slot) => _buildTimeSlotCard(date, slot)),
      ],
    );
  }

  Widget _buildTimeSlotCard(DateTime date, String slotTime) {
    // Find booking
    final booking = widget.bookings.firstWhere(
      (b) => b.bookingDate.year == date.year && 
             b.bookingDate.month == date.month && 
             b.bookingDate.day == date.day &&
             b.timeSlot == slotTime,
      orElse: () => Booking(
        customerName: '', 
        customerEmail: '', 
        customerPhone: '', 
        bookingDate: date, 
        timeSlot: slotTime, 
        suitType: '', 
        isUrgent: false, 
        charges: 0,
        status: 'available',
      ),
    );

    final isAvailable = booking.status == 'available';
    final isPending = booking.status == 'pending';
    final isBooked = ['confirmed', 'approved', 'completed'].contains(booking.status);

    Color bgColor = Colors.green[50]!;
    Color borderColor = Colors.green;
    Color iconColor = Colors.green;

    if (isPending) {
      bgColor = Colors.amber[50]!;
      borderColor = Colors.amber[800]!;
      iconColor = Colors.amber[800]!;
    } else if (isBooked) {
      bgColor = Colors.red[50]!;
      borderColor = Colors.red;
      iconColor = Colors.red;
    }

    return GestureDetector(
      onTap: () {
        if (!isAvailable) {
          _showBookingActionDialog(booking);
        } else {
          _showAddBookingDialog(initialDate: date, initialSlot: slotTime);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(color: borderColor.withOpacity(0.5)),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            if (!isAvailable)
              BoxShadow(
                color: borderColor.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Column(
          children: [
            Text(
              slotTime,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: isAvailable 
                ? Icon(Icons.add, size: 20, color: Colors.green[300])
                : Column(
                    children: [
                      Icon(Icons.person, size: 16, color: iconColor),
                      const SizedBox(height: 2),
                      Text(
                        booking.customerName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        booking.suitType,
                        style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Dialogs ---

  void _showBookingSettingsDialog() {
    int selectedDays = widget.tailor.bookingWindowDays;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Booking Settings'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Available booking period:'),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                value: selectedDays,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Window Duration',
                ),
                items: const [
                  DropdownMenuItem(value: 3, child: Text('3 Days')),
                  DropdownMenuItem(value: 7, child: Text('1 Week')),
                  DropdownMenuItem(value: 14, child: Text('2 Weeks')),
                  DropdownMenuItem(value: 30, child: Text('1 Month')),
                ],
                onChanged: (val) {
                  if (val != null) setDialogState(() => selectedDays = val);
                },
              ),
              const SizedBox(height: 8),
              Text(
                'Customers will only see slots for the next $selectedDays days.',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  final updatedTailor = widget.tailor.copyWith(bookingWindowDays: selectedDays);
                  await _tailorService.insertOrUpdateTailor(updatedTailor);
                  if (context.mounted) Navigator.pop(context);
                  widget.onRefresh(); // Refresh parent to get new tailor data
                } catch (e) {
                  // Handle error
                  print('Error updating settings: $e');
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddBookingDialog({DateTime? initialDate, String? initialSlot}) {
    final nameController = TextEditingController();
    final timeSlotController = TextEditingController(text: initialSlot ?? _timeSlots[0]);
    final suitTypeController = TextEditingController();
    final noteController = TextEditingController();
    DateTime selectedDate = initialDate ?? DateTime.now();
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('New Booking'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Customer Name')),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final d = await showDatePicker(
                      context: context, 
                      initialDate: selectedDate, 
                      firstDate: DateTime.now(), 
                      lastDate: DateTime.now().add(Duration(days: widget.tailor.bookingWindowDays))
                    );
                    if (d != null) setDialogState(() => selectedDate = d);
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Date'),
                    child: Text(DateFormat('yyyy-MM-dd').format(selectedDate)),
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _timeSlots.contains(timeSlotController.text) ? timeSlotController.text : _timeSlots[0],
                  items: _timeSlots.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (v) => timeSlotController.text = v!,
                  decoration: const InputDecoration(labelText: 'Time Slot'),
                ),
                const SizedBox(height: 8),
                TextField(controller: suitTypeController, decoration: const InputDecoration(labelText: 'Suit Type')),
                const SizedBox(height: 8),
                TextField(controller: noteController, decoration: const InputDecoration(labelText: 'Note'), maxLines: 2),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: isSaving ? null : () async {
                if (nameController.text.isNotEmpty) {
                  setDialogState(() => isSaving = true);
                  final booking = Booking(
                    customerName: nameController.text,
                    customerEmail: 'manual', 
                    customerPhone: 'manual',
                    bookingDate: selectedDate,
                    timeSlot: timeSlotController.text,
                    suitType: suitTypeController.text,
                    isUrgent: false,
                    charges: 0,
                    status: 'approved',
                    specialInstructions: noteController.text
                  );
                  await _bookingsService.addBooking(booking);
                  if (context.mounted) Navigator.pop(context);
                  widget.onRefresh();
                }
              },
              child: isSaving ? const CircularProgressIndicator() : const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showBookingActionDialog(Booking booking) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Booking Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Customer: ${booking.customerName}'),
            Text('Type: ${booking.suitType}'),
            Text('Time: ${booking.timeSlot}'),
            if (booking.specialInstructions != null) Text('Note: ${booking.specialInstructions}'),
            const SizedBox(height: 16),
            Chip(label: Text(booking.status.toUpperCase())),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
               if (booking.docId != null) {
                 await _bookingsService.deleteBooking(booking.docId!);
                 if (context.mounted) Navigator.pop(context);
                 widget.onRefresh();
               }
            },
            child: const Text('Delete / Reject', style: TextStyle(color: Colors.red)),
          ),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }
}
