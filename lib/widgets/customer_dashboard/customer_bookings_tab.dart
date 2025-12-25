import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/booking.dart';
import '../../models/tailor.dart';
import '../../services/firestore_bookings_service.dart';

class CustomerBookingsTab extends StatefulWidget {
  final Tailor? tailor;
  final List<Booking> allBookings;
  final List<Booking> myBookings;
  final String? customerName;
  final String? customerEmail;
  final String? customerPhone;
  final Function(Booking) onBookingAdded;
  final Function(Booking) onBookingRemoved;

  const CustomerBookingsTab({
    super.key,
    required this.tailor,
    required this.allBookings,
    required this.myBookings,
    required this.customerName,
    required this.customerEmail,
    required this.customerPhone,
    required this.onBookingAdded,
    required this.onBookingRemoved,
  });

  @override
  State<CustomerBookingsTab> createState() => _CustomerBookingsTabState();
}

class _CustomerBookingsTabState extends State<CustomerBookingsTab> {
  final FirestoreBookingsService _bookingsService = FirestoreBookingsService();
  String _selectedSuitType = 'Formal Suit'; // Default for dialog
  final ScrollController _scrollController = ScrollController();

  final List<String> _suitTypes = [
    'Formal Suit',
    'Casual Blazer',
    'Wedding Suit',
    'Tuxedo',
    'Designer Suit',
    'Custom Tailored',
  ];

  final List<String> _timeSlots = [
    '09:00 - 11:00',
    '11:00 - 13:00',
    '14:00 - 16:00',
    '16:00 - 18:00',
  ];

  @override
  Widget build(BuildContext context) {
    // Generate dates
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final bookingWindow = widget.tailor?.bookingWindowDays ?? 14; // Default 2 weeks view
    final upcomingDays = List.generate(
      bookingWindow, 
      (index) => today.add(Duration(days: index))
    );

    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: upcomingDays.length,
            itemBuilder: (context, index) {
              return _buildDaySection(upcomingDays[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text(
            'Booking Calendar',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center, // Center the button
            children: [
              // No Settings Icon here as per request
              ElevatedButton.icon(
                onPressed: _scrollToFirstAvailable,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Booking'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9333EA), // Purple
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDaySection(DateTime date) {
    return Column(
      children: [
        // Date Header
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 12, top: 8),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF9333EA), // Purple
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Text(
                DateFormat('E').format(date),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                DateFormat('d').format(date),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        
        // Slots
        ..._timeSlots.map((slot) => _buildSlotCard(date, slot)).toList(),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildSlotCard(DateTime date, String slotTime) {
    // Check Status
    final booking = widget.allBookings.firstWhere(
      (b) => b.bookingDate.year == date.year && 
             b.bookingDate.month == date.month && 
             b.bookingDate.day == date.day &&
             b.timeSlot == slotTime &&
             (b.status == 'pending' || b.status == 'approved' || b.status == 'completed'),
      orElse: () => Booking(
        customerName: '', customerEmail: '', customerPhone: '', 
        bookingDate: date, timeSlot: slotTime, suitType: '', 
        isUrgent: false, charges: 0, status: 'available',
      ),
    );

    final isAvailable = booking.status == 'available';
    final isMyBooking = booking.userId == FirebaseAuth.instance.currentUser?.uid;

    if (isAvailable) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: InkWell(
          onTap: () => _showConfirmationDialog(date, slotTime),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7), // Light Green
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(slotTime, style: TextStyle(color: Colors.green.shade800, fontSize: 12)),
                const Icon(Icons.add, color: Colors.green, size: 28),
              ],
            ),
          ),
        ),
      );
    } 
    
    if (isMyBooking) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB), // Cream/Yellowish
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.shade200, width: 1.5),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(slotTime, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  const Icon(Icons.person, color: Colors.orange),
                  const SizedBox(height: 4),
                  Text(
                    booking.customerName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  Text(
                    booking.suitType,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } 
    
    // Other's Booking (Unavailable)
     return Container(
        height: 60,
        margin: const EdgeInsets.only(bottom: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
             Text(slotTime, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
             const Text('RESERVED', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        ),
      );
  }

  void _scrollToFirstAvailable() {
    // Scroll to top or first available logic
    // For now simple scroll to top
     _scrollController.animateTo(0, duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
  }

  void _showConfirmationDialog(DateTime date, String slot) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) { // Use StatefulBuilder to update dropdown
          return AlertDialog(
            title: const Text('Add Booking'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _detailRow('Date', DateFormat('MMM d, yyyy').format(date)),
                _detailRow('Time', slot),
                const SizedBox(height: 16),
                const Text('Select Service:', style: TextStyle(fontWeight: FontWeight.bold)),
                DropdownButton<String>(
                  isExpanded: true,
                  value: _selectedSuitType,
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedSuitType = val);
                  },
                  items: _suitTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _processBooking(date, slot);
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF9333EA)),
                child: const Text('Confirm', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        }
      ),
    );
  }

  Future<void> _processBooking(DateTime date, String slot) async {
      if (widget.customerName == null || widget.customerName!.isEmpty ||
        widget.customerEmail == null || widget.customerEmail!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please update your profile with name and email first.')),
        );
        return;
      }

    final userId = FirebaseAuth.instance.currentUser?.uid;
    final booking = Booking(
      userId: userId,
      customerName: widget.customerName!,
      customerEmail: widget.customerEmail!,
      customerPhone: widget.customerPhone ?? '',
      bookingDate: date,
      timeSlot: slot,
      suitType: _selectedSuitType,
      isUrgent: false, 
      charges: 299.99, 
      status: 'pending',
    );

    widget.onBookingAdded(booking);

    try {
      await _bookingsService.addBooking(booking);
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('Booking Confirmed!'), backgroundColor: Colors.green),
         );
      }
    } catch (e) {
      widget.onBookingRemoved(booking);
      debugPrint('Booking Error (Full): $e');
      if (mounted) {
         String message = 'Could not confirm booking.';
         if (e.toString().contains('FIRESTORE')) {
           message = 'Connection issue. Please refresh the page and try again.';
         }
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text(message), backgroundColor: Colors.red),
         );
      }
    }
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
