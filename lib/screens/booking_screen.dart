import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/booking.dart' as models;
import '../services/firestore_bookings_service.dart';

class BookingScreen extends StatefulWidget {
  final String? customerName;
  final String? customerEmail;
  final String? customerPhone;

  const BookingScreen({
    super.key,
    this.customerName,
    this.customerEmail,
    this.customerPhone,
  });

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final FirestoreBookingsService _bookingsService = FirestoreBookingsService();
  DateTime _selectedDate = DateTime.now();
  String? _selectedTimeSlot;
  String? _selectedSuitType;
  bool _isUrgent = false;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _instructionsController = TextEditingController();
  bool _isLoading = false;
  List<models.Booking> _existingBookings = [];
  Map<DateTime, int> _bookingCounts = {};

  final List<String> _timeSlots = [
    '09:00-11:00',
    '11:00-13:00',
    '13:00-15:00',
    '15:00-17:00',
  ];

  final List<String> _suitTypes = [
    'Formal Suit',
    'Casual Blazer',
    'Wedding Suit',
    'Tuxedo',
    'Designer Suit',
    'Custom Tailored',
  ];

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.customerName ?? '';
    _emailController.text = widget.customerEmail ?? '';
    _phoneController.text = widget.customerPhone ?? '';
    _loadBookingsForMonth();
  }

  Future<void> _loadBookingsForMonth() async {
    final startDate = DateTime(_selectedDate.year, _selectedDate.month, 1);
    final endDate = DateTime(_selectedDate.year, _selectedDate.month + 1, 0);
    
    final allBookings = await _bookingsService.getAllBookings();
    final monthBookings = allBookings.where((b) {
      final bookingDate = DateTime(b.bookingDate.year, b.bookingDate.month, b.bookingDate.day);
      return bookingDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
          bookingDate.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();

    setState(() {
      _existingBookings = monthBookings;
      _bookingCounts = {};
      for (var booking in monthBookings) {
        final date = DateTime(booking.bookingDate.year, booking.bookingDate.month, booking.bookingDate.day);
        if (booking.status == 'pending' || booking.status == 'approved') {
          _bookingCounts[date] = (_bookingCounts[date] ?? 0) + 1;
        }
      }
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      selectableDayPredicate: (DateTime date) {
        // Allow selection of dates with less than 4 bookings
        final count = _bookingCounts[date] ?? 0;
        return count < 4;
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _selectedTimeSlot = null;
      });
      await _loadBookingsForMonth();
    }
  }

  bool _isTimeSlotAvailable(String timeSlot) {
    final bookingsForDate = _existingBookings.where((b) {
      final bookingDate = DateTime(b.bookingDate.year, b.bookingDate.month, b.bookingDate.day);
      final selectedDate = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
      return bookingDate.isAtSameMomentAs(selectedDate) &&
          b.timeSlot == timeSlot &&
          (b.status == 'pending' || b.status == 'approved');
    }).toList();
    return bookingsForDate.isEmpty;
  }

  double _calculateCharges() {
    double basePrice = 299.99; // Base price for normal booking
    if (_isUrgent) {
      basePrice += 150.00; // Additional charge for urgent
    }
    return basePrice;
  }

  Future<void> _submitBooking() async {
    if (_nameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty ||
        _selectedTimeSlot == null ||
        _selectedSuitType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Check if date has less than 4 bookings
    final bookingsCount =
        await _bookingsService.getBookingsCountForDate(_selectedDate);
    if (bookingsCount >= 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This date is fully booked. Maximum 4 suits per day.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check if time slot is available
    if (!_isTimeSlotAvailable(_selectedTimeSlot!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This time slot is already booked. Please select another.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final booking = models.Booking(
        customerName: _nameController.text.trim(),
        customerEmail: _emailController.text.trim(),
        customerPhone: _phoneController.text.trim(),
        bookingDate: _selectedDate,
        timeSlot: _selectedTimeSlot!,
        suitType: _selectedSuitType!,
        isUrgent: _isUrgent,
        charges: _calculateCharges(),
        specialInstructions: _instructionsController.text.trim().isEmpty
            ? null
            : _instructionsController.text.trim(),
        status: 'pending',
      );

      await _bookingsService.addBooking(booking);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking request submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      debugPrint('Booking Submit Error: $e');
      if (mounted) {
        String message = 'Error submitting booking.';
        if (e.toString().contains('FIRESTORE')) {
          message = 'Network connection issue. Please check your internet and try again.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
 finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Online Booking'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Calendar Section
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          DateFormat('MMMM yyyy').format(_selectedDate),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.calendar_today),
                          onPressed: () => _selectDate(context),
                          tooltip: 'Select Date',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: Colors.blue),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Selected: ${DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate)}\nBookings today: ${_bookingCounts[_selectedDate] ?? 0}/4',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Time Slots
            const Text(
              'Select Time Slot',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 2.5,
              ),
              itemCount: _timeSlots.length,
              itemBuilder: (context, index) {
                final slot = _timeSlots[index];
                final isAvailable = _isTimeSlotAvailable(slot);
                final isSelected = _selectedTimeSlot == slot;
                return InkWell(
                  onTap: isAvailable
                      ? () => setState(() => _selectedTimeSlot = slot)
                      : null,
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.blue
                          : isAvailable
                              ? Colors.grey[200]
                              : Colors.red[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? Colors.blue : Colors.grey[300]!,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            slot,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? Colors.white
                                  : isAvailable
                                      ? Colors.black
                                      : Colors.grey,
                            ),
                          ),
                          if (!isAvailable)
                            const Text(
                              'Booked',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.red,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // Suit Type
            const Text(
              'Select Suit Type',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _suitTypes.map((type) {
                final isSelected = _selectedSuitType == type;
                return ChoiceChip(
                  label: Text(type),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() => _selectedSuitType = selected ? type : null);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Customer Information
            const Text(
              'Your Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 24),

            // Urgency Toggle
            Card(
              color: _isUrgent ? Colors.orange[50] : Colors.grey[50],
              child: SwitchListTile(
                title: const Text('Urgent Booking'),
                subtitle: Text(_isUrgent
                    ? 'Additional \$150 charge for urgent processing'
                    : 'Standard booking (3-5 days)'),
                value: _isUrgent,
                onChanged: (value) => setState(() => _isUrgent = value),
                secondary: Icon(
                  _isUrgent ? Icons.flash_on : Icons.schedule,
                  color: _isUrgent ? Colors.orange : Colors.grey,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Special Instructions
            TextField(
              controller: _instructionsController,
              decoration: const InputDecoration(
                labelText: 'Special Instructions (Optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            // Charges Summary
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Booking Summary',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Base Price:'),
                        Text('\$${299.99.toStringAsFixed(2)}'),
                      ],
                    ),
                    if (_isUrgent) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Urgent Charge:'),
                          Text(
                            '\$${150.00.toStringAsFixed(2)}',
                            style: const TextStyle(color: Colors.orange),
                          ),
                        ],
                      ),
                    ],
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Charges:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '\$${_calculateCharges().toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _submitBooking,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check),
                label: Text(_isLoading ? 'Submitting...' : 'Submit Booking Request'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }
}

