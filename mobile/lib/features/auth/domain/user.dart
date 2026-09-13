import 'package:characters/characters.dart';

/// Authenticated / profile user snapshot.
class User {
  const User({
    required this.id,
    this.fullName = '',
    this.email,
    this.phone,
    this.photoPath,
    this.hasVerified = false,
    this.city,
  });

  final String id;
  final String fullName;
  final String? email;
  final String? phone;
  final String? photoPath;
  final bool hasVerified;

  /// User city (sent on register, shown on profile). Nullable for old sessions.
  final String? city;

  String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '؟';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first).toUpperCase();
  }

  User copyWith({
    String? id,
    String? fullName,
    String? Function()? email,
    String? Function()? phone,
    String? Function()? photoPath,
    bool? hasVerified,
    String? Function()? city,
  }) {
    return User(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email != null ? email() : this.email,
      phone: phone != null ? phone() : this.phone,
      photoPath: photoPath != null ? photoPath() : this.photoPath,
      hasVerified: hasVerified ?? this.hasVerified,
      city: city != null ? city() : this.city,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'fullName': fullName,
        'name': fullName,
        'email': email,
        'phone': phone,
        'photoPath': photoPath,
        'photo': photoPath,
        'hasVerified': hasVerified,
        'city': city,
      };

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: (json['id'] ?? json['_id'] ?? json['user_id'] ?? '').toString(),
        fullName: (json['fullName'] ?? json['name'] ?? '') as String,
        email: json['email'] as String?,
        phone: json['phone'] as String?,
        photoPath: (json['photoPath'] ?? json['photo'] ?? json['avatar'])
            as String?,
        hasVerified: (json['hasVerified'] ??
                json['verified'] ??
                json['isVerified'] ??
                false) as bool,
        city: (json['city'] ?? json['cityName'] ?? json['governorate']) as String?,
      );
}