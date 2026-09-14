import '../../../../core/services/location_service.dart';
import 'child_case_repository.dart';

/// Request-payload builders for the remote repository, extracted so the
/// remote class file stays under the 150-line budget. No logic changes.
Map<String, dynamic> missingQueryParams(CasesQuery query) => {
      if (query.search?.isNotEmpty ?? false) 'search': query.search,
      if (query.city != null) 'city': query.city,
      if (query.area != null) 'area': query.area,
      if (query.gender != null) 'gender': query.gender!.name,
      if (query.minAge != null) 'minAge': query.minAge,
      if (query.maxAge != null) 'maxAge': query.maxAge,
      if (query.activeOnly) 'activeOnly': true,
      if (query.foundOnly) 'foundOnly': true,
      'sort': query.sortNewest ? 'newest' : 'oldest',
    };

Map<String, dynamic> sightingPayload(SightingInput input) => {
      'caseId': input.caseId,
      'latitude': input.latitude,
      'longitude': input.longitude,
      'lat': input.latitude,
      'lng': input.longitude,
      'occurredAt': input.occurredAt.toIso8601String(),
      'description': input.description,
      if (input.notes != null) 'notes': input.notes,
    };

Map<String, dynamic> missingPayload(MissingReportInput input) => {
      'name': input.name,
      'age': input.age,
      'gender': input.gender.name,
      'missingSince': input.missingSince.toIso8601String(),
      'lastKnownLocation': input.lastKnownLocation,
      'city': input.city,
      'area': input.area,
      'clothing': input.clothing,
      'description': input.description,
      if (input.distinguishingMarks != null) 'distinguishingMarks': input.distinguishingMarks,
      if (input.phone != null) 'phone': input.phone,
      if (input.email != null) 'email': input.email,
      if (input.coordinates != null) 'coordinates': input.coordinates!.toJson(),
      if (input.photoSeed != null) 'photo': input.photoSeed,
      if (input.photoSeed != null) 'photoSeed': input.photoSeed,
    };

Map<String, dynamic> foundPayload(FoundReportInput input) => {
      'estimatedAge': input.estimatedAge,
      'age': input.estimatedAge,
      'gender': input.gender.name,
      'foundSince': input.foundSince.toIso8601String(),
      'foundLocation': input.foundLocation,
      'city': input.city,
      'area': input.area,
      'clothing': input.clothing,
      'description': input.description,
      if (input.extraInfo != null) 'extraInfo': input.extraInfo,
      if (input.coordinates != null) 'coordinates': input.coordinates!.toJson(),
      if (input.photoSeed != null) 'photo': input.photoSeed,
      if (input.photoSeed != null) 'photoSeed': input.photoSeed,
    };

Map<String, dynamic> nearbyParams(LatLng location, int radiusMeters) => {
      'lat': location.latitude,
      'lng': location.longitude,
      'radius': radiusMeters,
    };
