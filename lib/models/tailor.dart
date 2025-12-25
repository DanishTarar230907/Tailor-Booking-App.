class Tailor {
  final int? id; // legacy local id
  final String? docId; // Firestore doc id
  final String name;
  final String? photo;
  final String description;
  final String? announcement; // New Field
  final String? phone;
  final String? whatsapp;
  final String? email;
  final String? location;
  final String? shopHours;
  final int bookingWindowDays; // New field for customizable booking period

  Tailor({
    this.id,
    this.docId,
    required this.name,
    this.photo,
    required this.description,
    this.announcement,
    this.phone,
    this.whatsapp,
    this.email,
    this.location,
    this.shopHours,
    this.bookingWindowDays = 7, // Default to 1 week
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'docId': docId,
      'name': name,
      'photo': photo,
      'description': description,
      'announcement': announcement,
      'phone': phone,
      'whatsapp': whatsapp,
      'email': email,
      'location': location,
      'shopHours': shopHours,
      'bookingWindowDays': bookingWindowDays,
    };
  }

  factory Tailor.fromMap(Map<String, dynamic> map) {
    return Tailor(
      id: map['id'] as int?,
      docId: map['docId'] as String?,
      name: map['name'] as String,
      photo: map['photo'] as String?,
      description: map['description'] as String,
      announcement: map['announcement'] as String?,
      phone: map['phone'] as String?,
      whatsapp: map['whatsapp'] as String?,
      email: map['email'] as String?,
      location: map['location'] as String?,
      shopHours: map['shopHours'] as String?,
      bookingWindowDays: map['bookingWindowDays'] as int? ?? 7,
    );
  }

  Tailor copyWith({
    int? id,
    String? docId,
    String? name,
    String? photo,
    String? description,
    String? announcement,
    String? phone,
    String? whatsapp,
    String? email,
    String? location,
    String? shopHours,
    int? bookingWindowDays,
  }) {
    return Tailor(
      id: id ?? this.id,
      docId: docId ?? this.docId,
      name: name ?? this.name,
      photo: photo ?? this.photo,
      description: description ?? this.description,
      announcement: announcement ?? this.announcement,
      phone: phone ?? this.phone,
      whatsapp: whatsapp ?? this.whatsapp,
      email: email ?? this.email,
      location: location ?? this.location,
      shopHours: shopHours ?? this.shopHours,
      bookingWindowDays: bookingWindowDays ?? this.bookingWindowDays,
    );
  }
}

