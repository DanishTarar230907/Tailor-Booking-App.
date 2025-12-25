import 'package:drift/drift.dart';
// import 'package:drift/web.dart'; // Unused
// import 'package:flutter/foundation.dart' show kIsWeb; // Unused
import 'models/tailor.dart' as models;
import 'models/design.dart' as models;
import 'models/complaint.dart' as models;
import 'models/booking.dart' as models;
import 'models/measurement.dart' as models;
import 'models/pickup_request.dart' as models;

// Conditional imports
import 'database_helper_stub.dart'
    if (dart.library.io) 'database_helper_io.dart'
    if (dart.library.html) 'database_helper_web.dart';

part 'database_helper.g.dart';

class Tailors extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get photo => text().nullable()();
  TextColumn get description => text()();
}

class Designs extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  TextColumn get photo => text().nullable()();
  RealColumn get price => real()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Complaints extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get customerName => text()();
  TextColumn get message => text()();
  TextColumn get reply => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isResolved => boolean().withDefault(const Constant(false))();
}

@DataClassName('BookingRow')
class Bookings extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get customerName => text()();
  TextColumn get customerEmail => text()();
  TextColumn get customerPhone => text()();
  DateTimeColumn get bookingDate => dateTime()();
  TextColumn get timeSlot => text()();
  TextColumn get suitType => text()();
  BoolColumn get isUrgent => boolean().withDefault(const Constant(false))();
  RealColumn get charges => real()();
  TextColumn get specialInstructions => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  TextColumn get tailorNotes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('MeasurementRow')
class Measurements extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get customerName => text()();
  TextColumn get customerEmail => text()();
  TextColumn get customerPhone => text()();
  RealColumn get chest => real().nullable()();
  RealColumn get waist => real().nullable()();
  RealColumn get hips => real().nullable()();
  RealColumn get shoulder => real().nullable()();
  RealColumn get sleeveLength => real().nullable()();
  RealColumn get shirtLength => real().nullable()();
  RealColumn get pantLength => real().nullable()();
  RealColumn get inseam => real().nullable()();
  RealColumn get neck => real().nullable()();
  RealColumn get bicep => real().nullable()();
  RealColumn get wrist => real().nullable()();
  RealColumn get thigh => real().nullable()();
  RealColumn get calf => real().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().nullable()();
}

@DataClassName('PickupRequestRow')
class PickupRequests extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get customerName => text()();
  TextColumn get customerEmail => text()();
  TextColumn get customerPhone => text()();
  TextColumn get requestType => text()(); // 'sewing_request' or 'manual'
  IntColumn get relatedBookingId => integer().nullable()();
  TextColumn get pickupAddress => text()();
  TextColumn get trackingNumber => text().nullable()();
  TextColumn get courierName => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  RealColumn get charges => real()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get requestedDate => dateTime()();
  DateTimeColumn get completedDate => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DriftDatabase(tables: [Tailors, Designs, Complaints, Bookings, Measurements, PickupRequests])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(createConnection());

  @override
  int get schemaVersion => 4;

  // Tailor CRUD
  Future<models.Tailor?> getTailor() async {
    final result = await select(tailors).getSingleOrNull();
    if (result == null) return null;
    return models.Tailor(
      id: result.id,
      name: result.name,
      photo: result.photo,
      description: result.description,
    );
  }

  Future<models.Tailor> insertOrUpdateTailor(models.Tailor tailor) async {
    final existing = await getTailor();
    if (existing != null && existing.id != null) {
      final companion = TailorsCompanion(
        id: Value(existing.id!),
        name: Value(tailor.name),
        photo: tailor.photo != null ? Value(tailor.photo) : const Value.absent(),
        description: Value(tailor.description),
      );
      await update(tailors).replace(companion);
      return tailor.copyWith(id: existing.id);
    } else {
      final companion = TailorsCompanion(
        name: Value(tailor.name),
        photo: tailor.photo != null ? Value(tailor.photo) : const Value.absent(),
        description: Value(tailor.description),
      );
      final id = await into(tailors).insert(companion);
      return tailor.copyWith(id: id);
    }
  }

  // Design CRUD
  Future<List<models.Design>> getAllDesigns() async {
    final results = await (select(designs)..orderBy([(d) => OrderingTerm.desc(d.createdAt)])).get();
    return results.map((row) => models.Design(
      id: row.id,
      title: row.title,
      photo: row.photo,
      price: row.price,
      createdAt: row.createdAt,
    )).toList();
  }

  Future<models.Design> insertDesign(models.Design design) async {
    final companion = DesignsCompanion(
      title: Value(design.title),
      photo: design.photo != null ? Value(design.photo) : const Value.absent(),
      price: Value(design.price),
    );
    final id = await into(designs).insert(companion);
    return design.copyWith(id: id);
  }

  Future<bool> updateDesign(models.Design design) async {
    final companion = DesignsCompanion(
      id: Value(design.id!),
      title: Value(design.title),
      photo: design.photo != null ? Value(design.photo) : const Value.absent(),
      price: Value(design.price),
    );
    return await update(designs).replace(companion);
  }

  Future<int> deleteDesign(int id) async {
    return await (delete(designs)..where((d) => d.id.equals(id))).go();
  }

  // Complaint CRUD
  Future<List<models.Complaint>> getAllComplaints() async {
    final results = await (select(complaints)..orderBy([(c) => OrderingTerm.desc(c.createdAt)])).get();
    return results.map((row) => models.Complaint(
      id: row.id,
      customerId: '', // Legacy/Local complaint
      customerName: row.customerName,
      customerEmail: '', // Default empty for legacy local DB data
      message: row.message,
      reply: row.reply,
      createdAt: row.createdAt,
      isResolved: row.isResolved,
    )).toList();
  }

  Future<models.Complaint> insertComplaint(models.Complaint complaint) async {
    final companion = ComplaintsCompanion(
      customerName: Value(complaint.customerName),
      message: Value(complaint.message),
      reply: const Value.absent(),
      isResolved: const Value.absent(),
    );
    final id = await into(complaints).insert(companion);
    return complaint.copyWith(id: id);
  }

  Future<bool> updateComplaint(models.Complaint complaint) async {
    final companion = ComplaintsCompanion(
      id: Value(complaint.id!),
      customerName: Value(complaint.customerName),
      message: Value(complaint.message),
      reply: complaint.reply != null ? Value(complaint.reply) : const Value.absent(),
      isResolved: Value(complaint.isResolved),
    );
    return await update(complaints).replace(companion);
  }

  Future<int> deleteComplaint(int id) async {
    return await (delete(complaints)..where((c) => c.id.equals(id))).go();
  }

  // Booking CRUD
  Future<List<models.Booking>> getAllBookings() async {
    final results = await (select(bookings)..orderBy([(b) => OrderingTerm.desc(b.createdAt)])).get();
    return results.map((row) => models.Booking(
      id: row.id,
      customerName: row.customerName,
      customerEmail: row.customerEmail,
      customerPhone: row.customerPhone,
      bookingDate: row.bookingDate,
      timeSlot: row.timeSlot,
      suitType: row.suitType,
      isUrgent: row.isUrgent,
      charges: row.charges,
      specialInstructions: row.specialInstructions,
      status: row.status,
      tailorNotes: row.tailorNotes,
      createdAt: row.createdAt,
    )).toList();
  }

  Future<List<models.Booking>> getBookingsByDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
    final results = await (select(bookings)
          ..where((b) => b.bookingDate.isBiggerOrEqualValue(startOfDay) &
              b.bookingDate.isSmallerOrEqualValue(endOfDay))
          ..orderBy([(b) => OrderingTerm.asc(b.timeSlot)]))
        .get();
    return results.map((row) => models.Booking(
      id: row.id,
      customerName: row.customerName,
      customerEmail: row.customerEmail,
      customerPhone: row.customerPhone,
      bookingDate: row.bookingDate,
      timeSlot: row.timeSlot,
      suitType: row.suitType,
      isUrgent: row.isUrgent,
      charges: row.charges,
      specialInstructions: row.specialInstructions,
      status: row.status,
      tailorNotes: row.tailorNotes,
      createdAt: row.createdAt,
    )).toList();
  }

  Future<int> getBookingsCountForDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
    final results = await (select(bookings)
          ..where((b) => b.bookingDate.isBiggerOrEqualValue(startOfDay) &
              b.bookingDate.isSmallerOrEqualValue(endOfDay) &
              (b.status.equals('pending') | b.status.equals('approved'))))
        .get();
    return results.length;
  }

  Future<models.Booking> insertBooking(models.Booking booking) async {
    final companion = BookingsCompanion(
      customerName: Value(booking.customerName),
      customerEmail: Value(booking.customerEmail),
      customerPhone: Value(booking.customerPhone),
      bookingDate: Value(booking.bookingDate),
      timeSlot: Value(booking.timeSlot),
      suitType: Value(booking.suitType),
      isUrgent: Value(booking.isUrgent),
      charges: Value(booking.charges),
      specialInstructions: booking.specialInstructions != null
          ? Value(booking.specialInstructions)
          : const Value.absent(),
      status: Value(booking.status),
      tailorNotes: booking.tailorNotes != null
          ? Value(booking.tailorNotes)
          : const Value.absent(),
    );
    final id = await into(bookings).insert(companion);
    return booking.copyWith(id: id);
  }

  Future<bool> updateBooking(models.Booking booking) async {
    final companion = BookingsCompanion(
      id: Value(booking.id!),
      customerName: Value(booking.customerName),
      customerEmail: Value(booking.customerEmail),
      customerPhone: Value(booking.customerPhone),
      bookingDate: Value(booking.bookingDate),
      timeSlot: Value(booking.timeSlot),
      suitType: Value(booking.suitType),
      isUrgent: Value(booking.isUrgent),
      charges: Value(booking.charges),
      specialInstructions: booking.specialInstructions != null
          ? Value(booking.specialInstructions)
          : const Value.absent(),
      status: Value(booking.status),
      tailorNotes: booking.tailorNotes != null
          ? Value(booking.tailorNotes)
          : const Value.absent(),
    );
    return await update(bookings).replace(companion);
  }

  Future<int> deleteBooking(int id) async {
    return await (delete(bookings)..where((b) => b.id.equals(id))).go();
  }

  // Measurement CRUD
  Future<List<models.Measurement>> getAllMeasurements() async {
    final results = await (select(measurements)..orderBy([(m) => OrderingTerm.desc(m.createdAt)])).get();
    return results.map((row) {
        final map = <String, double>{};
        if (row.chest != null) map['Chest'] = row.chest!;
        if (row.waist != null) map['Waist'] = row.waist!;
        if (row.hips != null) map['Hips'] = row.hips!;
        if (row.shoulder != null) map['Shoulder'] = row.shoulder!;
        if (row.sleeveLength != null) map['Sleeve Length'] = row.sleeveLength!;
        if (row.shirtLength != null) map['Shirt Length'] = row.shirtLength!;
        if (row.pantLength != null) map['Trouser Length'] = row.pantLength!;
        if (row.inseam != null) map['Inseam'] = row.inseam!;
        if (row.neck != null) map['Neck'] = row.neck!;
        if (row.bicep != null) map['Bicep'] = row.bicep!;
        if (row.wrist != null) map['Wrist'] = row.wrist!;
        if (row.thigh != null) map['Thigh'] = row.thigh!;
        if (row.calf != null) map['Calf'] = row.calf!;

       return models.Measurement(
          id: row.id,
          customerId: '', // Local DB might not have this, default empty or add migration? defaulting empty is fine provided we don't sync back blindly without ID
          customerName: row.customerName,
          customerEmail: row.customerEmail,
          customerPhone: row.customerPhone,
          measurements: map,
          notes: row.notes,
          createdAt: row.createdAt,
          updatedAt: row.updatedAt,
          status: 'Pending',
          stitchingStarted: false,
       );
    }).toList();
  }

  Future<models.Measurement?> getMeasurementByCustomer(String customerEmail) async {
    final result = await (select(measurements)..where((m) => m.customerEmail.equals(customerEmail))).getSingleOrNull();
    if (result == null) return null;
    
    // Map flat columns to dynamic map
    final map = <String, double>{};
    if (result.chest != null) map['Chest'] = result.chest!;
    if (result.waist != null) map['Waist'] = result.waist!;
    if (result.hips != null) map['Hips'] = result.hips!;
    if (result.shoulder != null) map['Shoulder'] = result.shoulder!;
    if (result.sleeveLength != null) map['Sleeve Length'] = result.sleeveLength!;
    if (result.shirtLength != null) map['Shirt Length'] = result.shirtLength!;
    if (result.pantLength != null) map['Trouser Length'] = result.pantLength!;
    if (result.inseam != null) map['Inseam'] = result.inseam!;
    if (result.neck != null) map['Neck'] = result.neck!;
    if (result.bicep != null) map['Bicep'] = result.bicep!;
    if (result.wrist != null) map['Wrist'] = result.wrist!;
    if (result.thigh != null) map['Thigh'] = result.thigh!;
    if (result.calf != null) map['Calf'] = result.calf!;

    return models.Measurement(
      id: result.id,
      customerId: '', // Default empty
      customerName: result.customerName,
      customerEmail: result.customerEmail,
      customerPhone: result.customerPhone,
      measurements: map,
      notes: result.notes,
      createdAt: result.createdAt,
      updatedAt: result.updatedAt,
      // Default new fields as they don't exist in local DB
      status: 'Pending', 
      stitchingStarted: false,
    );
  }

  Future<models.Measurement> insertOrUpdateMeasurement(models.Measurement measurement) async {
    final existing = await getMeasurementByCustomer(measurement.customerEmail);
    
    // Extract flat values from map for local storage
    final m = measurement.measurements;
    
    if (existing != null && existing.id != null) {
      final companion = MeasurementsCompanion(
        id: Value(existing.id!),
        customerName: Value(measurement.customerName),
        customerEmail: Value(measurement.customerEmail),
        customerPhone: Value(measurement.customerPhone),
         chest: m['Chest'] != null ? Value(m['Chest']) : const Value.absent(),
        waist: m['Waist'] != null ? Value(m['Waist']) : const Value.absent(),
        hips: m['Hips'] != null ? Value(m['Hips']) : const Value.absent(),
        shoulder: m['Shoulder'] != null ? Value(m['Shoulder']) : const Value.absent(),
        sleeveLength: m['Sleeve Length'] != null ? Value(m['Sleeve Length']) : const Value.absent(),
        shirtLength: m['Shirt Length'] != null ? Value(m['Shirt Length']) : const Value.absent(),
        pantLength: m['Trouser Length'] != null ? Value(m['Trouser Length']) : const Value.absent(),
        inseam: m['Inseam'] != null ? Value(m['Inseam']) : const Value.absent(),
        neck: m['Neck'] != null ? Value(m['Neck']) : const Value.absent(),
        bicep: m['Bicep'] != null ? Value(m['Bicep']) : const Value.absent(),
        wrist: m['Wrist'] != null ? Value(m['Wrist']) : const Value.absent(),
        thigh: m['Thigh'] != null ? Value(m['Thigh']) : const Value.absent(),
        calf: m['Calf'] != null ? Value(m['Calf']) : const Value.absent(),
        notes: measurement.notes != null ? Value(measurement.notes) : const Value.absent(),
        updatedAt: Value(DateTime.now()),
      );
      await update(measurements).replace(companion);
      return measurement.copyWith(id: existing.id, updatedAt: DateTime.now());
    } else {
      final companion = MeasurementsCompanion(
        customerName: Value(measurement.customerName),
        customerEmail: Value(measurement.customerEmail),
        customerPhone: Value(measurement.customerPhone),
        chest: m['Chest'] != null ? Value(m['Chest']) : const Value.absent(),
        waist: m['Waist'] != null ? Value(m['Waist']) : const Value.absent(),
        hips: m['Hips'] != null ? Value(m['Hips']) : const Value.absent(),
        shoulder: m['Shoulder'] != null ? Value(m['Shoulder']) : const Value.absent(),
        sleeveLength: m['Sleeve Length'] != null ? Value(m['Sleeve Length']) : const Value.absent(),
        shirtLength: m['Shirt Length'] != null ? Value(m['Shirt Length']) : const Value.absent(),
        pantLength: m['Trouser Length'] != null ? Value(m['Trouser Length']) : const Value.absent(),
        inseam: m['Inseam'] != null ? Value(m['Inseam']) : const Value.absent(),
        neck: m['Neck'] != null ? Value(m['Neck']) : const Value.absent(),
        bicep: m['Bicep'] != null ? Value(m['Bicep']) : const Value.absent(),
        wrist: m['Wrist'] != null ? Value(m['Wrist']) : const Value.absent(),
        thigh: m['Thigh'] != null ? Value(m['Thigh']) : const Value.absent(),
        calf: m['Calf'] != null ? Value(m['Calf']) : const Value.absent(),
        notes: measurement.notes != null ? Value(measurement.notes) : const Value.absent(),
      );
      final id = await into(measurements).insert(companion);
      return measurement.copyWith(id: id);
    }
  }

  Future<int> deleteMeasurement(int id) async {
    return await (delete(measurements)..where((m) => m.id.equals(id))).go();
  }

  // Pickup Request CRUD
  Future<List<models.PickupRequest>> getAllPickupRequests() async {
    final results = await (select(pickupRequests)..orderBy([(p) => OrderingTerm.desc(p.createdAt)])).get();
    return results.map((row) => models.PickupRequest(
      id: row.id,
      customerName: row.customerName,
      customerEmail: row.customerEmail,
      customerPhone: row.customerPhone,
      requestType: row.requestType,
      relatedBookingId: row.relatedBookingId,
      pickupAddress: row.pickupAddress,
      trackingNumber: row.trackingNumber,
      courierName: row.courierName,
      status: row.status,
      charges: row.charges,
      notes: row.notes,
      requestedDate: row.requestedDate,
      completedDate: row.completedDate,
      createdAt: row.createdAt,
    )).toList();
  }

  Future<models.PickupRequest> insertPickupRequest(models.PickupRequest request) async {
    final companion = PickupRequestsCompanion(
      customerName: Value(request.customerName),
      customerEmail: Value(request.customerEmail),
      customerPhone: Value(request.customerPhone),
      requestType: Value(request.requestType),
      relatedBookingId: request.relatedBookingId != null ? Value(request.relatedBookingId) : const Value.absent(),
      pickupAddress: Value(request.pickupAddress),
      trackingNumber: request.trackingNumber != null ? Value(request.trackingNumber) : const Value.absent(),
      courierName: request.courierName != null ? Value(request.courierName) : const Value.absent(),
      status: Value(request.status),
      charges: Value(request.charges),
      notes: request.notes != null ? Value(request.notes) : const Value.absent(),
      requestedDate: Value(request.requestedDate),
      completedDate: request.completedDate != null ? Value(request.completedDate) : const Value.absent(),
    );
    final id = await into(pickupRequests).insert(companion);
    return request.copyWith(id: id);
  }

  Future<bool> updatePickupRequest(models.PickupRequest request) async {
    final companion = PickupRequestsCompanion(
      id: Value(request.id!),
      customerName: Value(request.customerName),
      customerEmail: Value(request.customerEmail),
      customerPhone: Value(request.customerPhone),
      requestType: Value(request.requestType),
      relatedBookingId: request.relatedBookingId != null ? Value(request.relatedBookingId) : const Value.absent(),
      pickupAddress: Value(request.pickupAddress),
      trackingNumber: request.trackingNumber != null ? Value(request.trackingNumber) : const Value.absent(),
      courierName: request.courierName != null ? Value(request.courierName) : const Value.absent(),
      status: Value(request.status),
      charges: Value(request.charges),
      notes: request.notes != null ? Value(request.notes) : const Value.absent(),
      requestedDate: Value(request.requestedDate),
      completedDate: request.completedDate != null ? Value(request.completedDate) : const Value.absent(),
    );
    return await update(pickupRequests).replace(companion);
  }

  Future<int> deletePickupRequest(int id) async {
    return await (delete(pickupRequests)..where((p) => p.id.equals(id))).go();
  }
}

// Singleton pattern for easy access
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  AppDatabase? _database;

  DatabaseHelper._init();

  AppDatabase get database {
    _database ??= AppDatabase();
    return _database!;
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}
