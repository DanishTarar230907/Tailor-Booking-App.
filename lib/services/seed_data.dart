import '../database_helper.dart';
import '../models/tailor.dart' as models;
import '../models/design.dart' as models;
import '../models/complaint.dart' as models;
import '../models/booking.dart' as models;
import 'firestore_tailor_service.dart';
import 'firestore_designs_service.dart';
// import 'firestore_complaints_service.dart'; // Optional

class SeedDataService {
  static Future<void> seedData() async {
    final db = DatabaseHelper.instance.database;
    
    // --- Firestore Seeding ---
    // Always check/seed Firestore regardless of local DB state
    await _seedFirestoreData();

    final existingTailor = await db.getTailor();
    if (existingTailor != null) {
      // Local Data already seeded
      return;
    }

    // Seed Tailor
    final tailor = models.Tailor(
      name: 'John Tailor',
      photo: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400',
      description: 'Professional tailor with 10+ years of experience. Specializing in custom suits, dresses, and alterations.',
    );
    await db.insertOrUpdateTailor(tailor);

    // Seed Designs
    final designs = [
      models.Design(
        title: 'Classic Business Suit',
        photo: 'https://images.unsplash.com/photo-1594938291221-94f18cbb7080?w=400',
        price: 299.99,
      ),
      models.Design(
        title: 'Elegant Evening Dress',
        photo: 'https://images.unsplash.com/photo-1595777457583-95e059d581b8?w=400',
        price: 399.99,
      ),
      models.Design(
        title: 'Casual Blazer',
        photo: 'https://images.unsplash.com/photo-1551028719-00167b16eac5?w=400',
        price: 199.99,
      ),
      models.Design(
        title: 'Wedding Gown',
        photo: 'https://images.unsplash.com/photo-1515377905703-c4788e51af15?w=400',
        price: 599.99,
      ),
      models.Design(
        title: 'Formal Tuxedo',
        photo: 'https://images.unsplash.com/photo-1624378515193-8e47799b0d3a?w=400',
        price: 349.99,
      ),
    ];

    for (final design in designs) {
      await db.insertDesign(design);
    }

    // Seed Complaints with replies
    final complaints = [
      models.Complaint(
        customerId: 'customer_1',
        tailorId: 'tailor_1',
        customerName: 'Alice Smith',
        customerEmail: 'alice@example.com',
        message: 'The suit I ordered arrived with a small tear. Can this be fixed?',
        reply: 'We apologize for the inconvenience. Please bring it to our shop and we will fix it free of charge.',
        isResolved: true,
      ),
      models.Complaint(
        customerId: 'customer_2',
        tailorId: 'tailor_1',
        customerName: 'Bob Johnson',
        customerEmail: 'bob@example.com',
        message: 'The dress size was slightly off. Can I get it adjusted?',
        reply: 'Absolutely! We offer free alterations within 30 days of purchase. Please visit us at your convenience.',
        isResolved: true,
      ),
      models.Complaint(
        customerId: 'customer_3',
        tailorId: 'tailor_1',
        customerName: 'Charlie Brown',
        customerEmail: 'charlie@example.com',
        message: 'When will my custom suit be ready?',
        reply: null,
        isResolved: false,
      ),
    ];

    for (final complaint in complaints) {
      await db.insertComplaint(complaint);
    }

    // Seed Bookings
    final bookings = [
      models.Booking(
        customerName: 'Alice Smith',
        customerEmail: 'alice@example.com',
        customerPhone: '+1234567890',
        bookingDate: DateTime.now().add(const Duration(days: 3)),
        timeSlot: '09:00-11:00',
        suitType: 'Formal Suit',
        isUrgent: false,
        charges: 299.99,
        status: 'approved',
        tailorNotes: 'Ready for fitting',
      ),
      models.Booking(
        customerName: 'Bob Johnson',
        customerEmail: 'bob@example.com',
        customerPhone: '+1234567891',
        bookingDate: DateTime.now().add(const Duration(days: 5)),
        timeSlot: '11:00-13:00',
        suitType: 'Wedding Suit',
        isUrgent: true,
        charges: 449.99,
        status: 'pending',
        specialInstructions: 'Need it before wedding on Saturday',
      ),
      models.Booking(
        customerName: 'Charlie Brown',
        customerEmail: 'charlie@example.com',
        customerPhone: '+1234567892',
        bookingDate: DateTime.now().add(const Duration(days: 7)),
        timeSlot: '13:00-15:00',
        suitType: 'Tuxedo',
        isUrgent: false,
        charges: 299.99,
        status: 'pending',
      ),
    ];

    for (final booking in bookings) {
      await db.insertBooking(booking);
    }
    // --- Firestore Seeding ---
    await _seedFirestoreData();
  }



  static Future<void> _seedFirestoreData() async {
    print('Checking Firestore data...');
    try {
      // 1. Seed Tailor
      final tailorService = FirestoreTailorService();
      final existingTailor = await tailorService.getTailor();
      
      if (existingTailor == null) {
        print('Seeding Firestore Tailor...');
        final tailor = models.Tailor(
          name: 'Grace Tailor Studio', 
          photo: 'https://images.unsplash.com/photo-1520223297774-899238b2c899?w=400',
          description: 'Expert bespoke tailoring for ladies and gents. Quality craftsmanship guaranteed.',
          phone: '+1 555 000 0000',
          email: 'support@gracetailor.com',
          location: '123 Fashion Street, Design City',
          shopHours: 'Mon-Sun: 9:00 AM - 9:00 PM',
          bookingWindowDays: 14,
        );
        await tailorService.insertOrUpdateTailor(tailor);
      } else {
        print('Firestore Tailor already exists.');
      }

      // 2. Seed Designs
      final designsService = FirestoreDesignsService();
      final existingDesigns = await designsService.getAllDesigns();
      
      if (existingDesigns.isEmpty) {
         print('Seeding Firestore Designs...');
         final designs = [
            models.Design(
              title: 'Summer Floral Dress',
              photo: 'https://images.unsplash.com/photo-1572804013309-59a88b7e92f1?w=400',
              price: 120.00,
            ),
            models.Design(
              title: 'Classic Wool Coat',
              photo: 'https://images.unsplash.com/photo-1539533018447-63fcce2678e3?w=400',
              price: 350.00,
            ),
            models.Design(
              title: 'Silk Evening Gown',
              photo: 'https://images.unsplash.com/photo-1566174053879-31528523f8ae?w=400',
              price: 450.00,
            ),
             models.Design(
              title: 'Modern Business Suit',
              photo: 'https://images.unsplash.com/photo-1594938298603-c8148c4dae35?w=400',
              price: 280.00,
            ),
         ];
         
         for (final design in designs) {
           await designsService.addDesign(design);
         }
      } else {
         print('Firestore Designs already exist.');
      }

    } catch (e) {
      print('Error seeding Firestore: $e');
    }
  }
}

