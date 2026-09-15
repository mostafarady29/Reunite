part of 'child_case.dart';

/// Copy helper for [ChildCase], kept in a separate part file
/// so `child_case.dart` stays under the 150-line budget.
extension ChildCaseCopy on ChildCase {
  ChildCase copyWith({
    String? id,
    ReportType? type,
    String? name,
    int? age,
    Gender? gender,
    CaseStatus? status,
    UrgencyLevel? urgency,
    String? lastKnownLocation,
    String? city,
    String? area,
    DateTime? missingSince,
    DateTime? lastSeen,
    String? clothing,
    String? description,
    String? Function()? distinguishingMarks,
    String? Function()? locality,
    String? Function()? photoPath,
    User? Function()? reporter,
    bool? verified,
    LatLng? coordinates,
    DateTime? createdAt,
  }) {
    return ChildCase(
      id: id ?? this.id,
      type: type ?? this.type,
      name: name ?? this.name,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      status: status ?? this.status,
      urgency: urgency ?? this.urgency,
      lastKnownLocation: lastKnownLocation ?? this.lastKnownLocation,
      city: city ?? this.city,
      area: area ?? this.area,
      missingSince: missingSince ?? this.missingSince,
      lastSeen: lastSeen ?? this.lastSeen,
      clothing: clothing ?? this.clothing,
      description: description ?? this.description,
      distinguishingMarks:
          distinguishingMarks != null ? distinguishingMarks() : this.distinguishingMarks,
      locality: locality != null ? locality() : this.locality,
      photoPath: photoPath != null ? photoPath() : this.photoPath,
      reporter: reporter != null ? reporter() : this.reporter,
      verified: verified ?? this.verified,
      coordinates: coordinates ?? this.coordinates,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
