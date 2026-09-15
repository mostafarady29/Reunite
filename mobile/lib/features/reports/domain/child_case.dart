import '../../../core/services/location_service.dart';
import '../../shared/domain/app_enums.dart';
import '../../auth/domain/user.dart';

part 'child_case_copy.dart';

/// A single child report (missing or found).
class ChildCase {
  const ChildCase({
    required this.id,
    required this.type,
    required this.name,
    required this.age,
    required this.gender,
    required this.status,
    required this.urgency,
    required this.lastKnownLocation,
    required this.city,
    required this.area,
    required this.missingSince,
    required this.lastSeen,
    required this.clothing,
    required this.description,
    this.distinguishingMarks,
    this.photoPath,
    this.locality,
    this.reporter,
    this.verified = false,
    this.coordinates,
    this.createdAt,
  });

  final String id;
  final ReportType type;
  final String name;
  final int age;
  final Gender gender;
  final CaseStatus status;
  final UrgencyLevel urgency;

  /// Human friendly last location label, e.g. "شارع عباس العقاد".
  final String lastKnownLocation;

  final String city;
  final String area;
  final DateTime missingSince;
  final DateTime lastSeen;

  /// Optional geographic coordinates for the map (if shared).
  final LatLng? coordinates;

  final String clothing;
  final String description;
  final String? distinguishingMarks;
  final String? locality;
  final String? photoPath;
  final User? reporter;
  final bool verified;
  final DateTime? createdAt;

  bool get isMissing => type == ReportType.missing;
  bool get isFound => type == ReportType.found;
  bool get isActive => status.isActive;
  bool get isResolved => status.isResolved;

  /// A case is "urgent" when it's missing + active + high urgency.
  bool get isUrgent => isMissing && isActive && urgency == UrgencyLevel.high;

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'name': name,
        'age': age,
        'gender': gender.name,
        'status': status.name,
        'urgency': urgency.name,
        'lastKnownLocation': lastKnownLocation,
        'city': city,
        'area': area,
        'missingSince': missingSince.toIso8601String(),
        'lastSeen': lastSeen.toIso8601String(),
        'clothing': clothing,
        'description': description,
        'distinguishingMarks': distinguishingMarks,
        'photoPath': photoPath,
        'verified': verified,
        'coordinates': coordinates?.toJson(),
        'createdAt': createdAt?.toIso8601String(),
      };

  factory ChildCase.fromJson(Map<String, dynamic> json) => ChildCase(
        id: json['id']?.toString() ?? '',
        type: ReportType.values.firstWhere(
          (e) => e.name.toLowerCase() == (json['type']?.toString().toLowerCase()),
          orElse: () => ReportType.missing,
        ),
        name: json['name']?.toString() ?? 'Unknown',
        age: (json['age'] is num)
            ? (json['age'] as num).toInt()
            : int.tryParse(json['age']?.toString() ?? '') ?? 0,
        gender: Gender.values.firstWhere(
          (e) => e.name.toLowerCase() == (json['gender']?.toString().toLowerCase()),
          orElse: () => Gender.male,
        ),
        status: CaseStatus.values.firstWhere(
          (e) => e.name.toLowerCase() == (json['status']?.toString().toLowerCase()),
          orElse: () => CaseStatus.published,
        ),
        urgency: UrgencyLevel.values.firstWhere(
          (e) => e.name.toLowerCase() == (json['urgency']?.toString().toLowerCase()),
          orElse: () => UrgencyLevel.medium,
        ),
        lastKnownLocation: json['lastKnownLocation']?.toString() ?? '',
        city: json['city']?.toString() ?? '',
        area: json['area']?.toString() ?? '',
        missingSince:
            DateTime.tryParse(json['missingSince']?.toString() ?? '') ?? DateTime.now(),
        lastSeen: DateTime.tryParse(json['lastSeen']?.toString() ?? '') ??
            DateTime.tryParse(json['missingSince']?.toString() ?? '') ??
            DateTime.now(),
        clothing: json['clothing']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        distinguishingMarks: json['distinguishingMarks']?.toString(),
        photoPath: json['photoPath']?.toString(),
        verified: json['verified'] as bool? ?? false,
        coordinates: json['coordinates'] == null
            ? null
            : LatLng.fromJson(json['coordinates'] as Map<String, dynamic>),
        createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
            DateTime.tryParse(json['created_at']?.toString() ?? ''),
      );
}
