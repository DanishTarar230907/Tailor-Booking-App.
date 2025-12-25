import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/tailor.dart';

class FirestoreTailorService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('tailors');

  Tailor _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Tailor(
      docId: doc.id,
      id: data['id'],
      name: data['name'] ?? '',
      photo: data['photo'],
      description: data['description'] ?? '',
      announcement: data['announcement'], // Added mapping
      phone: data['phone'],
      whatsapp: data['whatsapp'],
      email: data['email'],
      location: data['location'],
      shopHours: data['shopHours'],
      bookingWindowDays: (data['bookingWindowDays'] as int?) ?? 7,
    );
  }

  Map<String, dynamic> _toMap(Tailor t) {
    return {
      'name': t.name,
      'photo': t.photo,
      'description': t.description,
      'announcement': t.announcement, // Added mapping
      'phone': t.phone,
      'whatsapp': t.whatsapp,
      'email': t.email,
      'location': t.location,
      'shopHours': t.shopHours,
      'bookingWindowDays': t.bookingWindowDays,
    };
  }

  Future<Tailor?> getTailor() async {
    final snap = await _collection.limit(1).get();
    if (snap.docs.isEmpty) return null;
    return _fromDoc(snap.docs.first);
  }

  Future<Tailor> insertOrUpdateTailor(Tailor tailor) async {
    final existing = await getTailor();
    if (existing != null && existing.docId != null) {
      final updated = tailor.copyWith(docId: existing.docId);
      await _collection.doc(existing.docId).set(_toMap(updated));
      return updated;
    }
    final doc = await _collection.add(_toMap(tailor));
    return tailor.copyWith(docId: doc.id);
  }
}

