import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/complaint.dart';
import 'firebase_storage_service.dart';

class FirestoreComplaintsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorageService _storageService = FirebaseStorageService();

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('complaints');

  Complaint _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Complaint.fromMap({...data, 'docId': doc.id});
  }

  Map<String, dynamic> _toMap(Complaint complaint) {
    return complaint.toMap();
  }

  Stream<List<Complaint>> streamComplaints() {
    return _collection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(_fromDoc).toList());
  }

  Future<List<Complaint>> getAllComplaints() async {
    // Limit to 100 most recent complaints for better performance
    final snap =
        await _collection.orderBy('createdAt', descending: true).limit(100).get();
    return snap.docs.map(_fromDoc).toList();
  }

  Future<List<Complaint>> getComplaintsByStatus(String status) async {
    final snap = await _collection
        .where('status', isEqualTo: status)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .get();
    return snap.docs.map(_fromDoc).toList();
  }

  Future<List<Complaint>> getComplaintsByCategory(String category) async {
    final snap = await _collection
        .where('category', isEqualTo: category)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .get();
    return snap.docs.map(_fromDoc).toList();
  }

  Stream<List<Complaint>> getComplaintsForCustomer(String customerId) {
    return _collection
        .where('customerId', isEqualTo: customerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(_fromDoc).toList());
  }

  // Alias for legacy support if needed, but fileComplaint was requested in error log
  Future<Complaint> fileComplaint(Complaint complaint) async {
      return addComplaint(complaint);
  }

  Future<Complaint> addComplaint(Complaint complaint) async {
    final doc = await _collection.add(_toMap(complaint));
    return complaint.copyWith(docId: doc.id);
  }

  Future<void> updateComplaint(Complaint complaint) async {
    if (complaint.docId == null) {
      throw Exception('Cannot update complaint without Firestore docId');
    }
    await _collection.doc(complaint.docId).update(_toMap(complaint));
  }

  Future<void> addReply(String docId, ComplaintReply reply) async {
    final doc = await _collection.doc(docId).get();
    if (!doc.exists) {
      throw Exception('Complaint not found');
    }

    final complaint = _fromDoc(doc);
    final updatedReplies = [...complaint.replies, reply];
    
    await _collection.doc(docId).update({
      'replies': updatedReplies.map((r) => r.toMap()).toList(),
      'reply': reply.message, // Update legacy reply field for backward compatibility
    });
  }

  Future<void> updateStatus(String docId, String status) async {
    final isResolved = status == 'resolved';
    await _collection.doc(docId).update({
      'status': status,
      'isResolved': isResolved,
    });
  }

  Future<String?> uploadAttachment(String filePath, String complaintId) async {
    try {
      // TODO: Implement file upload using XFile
      // For now, return null as this feature needs XFile integration
      return null;
    } catch (e) {
      print('Error uploading attachment: $e');
      return null;
    }
  }

  Future<void> deleteComplaint(String docId) async {
    await _collection.doc(docId).delete();
  }

  Stream<List<Complaint>> streamComplaintsByStatus(String status) {
    return _collection
        .where('status', isEqualTo: status)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(_fromDoc).toList());
  }
}

