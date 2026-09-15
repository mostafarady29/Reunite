import '../../domain/child_case.dart';
import 'models.dart';

/// JSON helpers extracted from the remote repository so the remote
/// class file stays under the 150-line budget. No logic changes.
List<ChildCase> parseCaseList(dynamic data) {
  final List items;
  if (data is List) {
    items = data;
  } else if (data is Map<String, dynamic>) {
    final inner = data['data'];
    if (inner is List) {
      items = inner;
    } else if (inner is Map && inner['cases'] is List) {
      items = inner['cases'] as List;
    } else if (data['cases'] is List) {
      items = data['cases'] as List;
    } else {
      items = const [];
    }
  } else {
    items = const [];
  }
  return items.whereType<Map<String, dynamic>>().map((json) {
    try {
      return ChildCase.fromJson(normalizeCaseJson(json));
    } catch (_) {
      return null;
    }
  }).whereType<ChildCase>().toList();
}

/// Single-case envelope (`{data: {...}}` or raw map).
Map<String, dynamic> parseSingleCaseMap(dynamic data) {
  if (data is Map<String, dynamic> && data['data'] is Map) {
    return (data['data'] as Map).map((k, v) => MapEntry(k.toString(), v));
  } else if (data is Map<String, dynamic>) {
    return data;
  }
  return const {};
}

/// Match-list envelope (`[...]`, `{data: [...]}`, `{matches: [...]}`).
List<Map<String, dynamic>> parseMatchEnvelopes(dynamic data) {
  final List items;
  if (data is List) {
    items = data;
  } else if (data is Map && data['data'] is List) {
    items = data['data'] as List;
  } else if (data is Map && data['matches'] is List) {
    items = data['matches'] as List;
  } else {
    items = const [];
  }
  return items
      .whereType<Map<String, dynamic>>()
      .map((e) => e.map((k, v) => MapEntry(k.toString(), v)))
      .toList();
}

/// Builds a [PossibleMatch] from one raw match envelope entry.
PossibleMatch parsePossibleMatch(Map<String, dynamic> m) {
  final caseMap = m['case'] is Map
      ? (m['case'] as Map).map((k, v) => MapEntry(k.toString(), v))
      : m['foundCase'] is Map
          ? (m['foundCase'] as Map).map((k, v) => MapEntry(k.toString(), v))
          : m;
  return PossibleMatch(
    foundCase: ChildCase.fromJson(normalizeCaseJson(caseMap)),
    matchPercent: ((m['matchPercent'] ?? m['score'] ?? 0) as num).toDouble(),
    distanceMeters: ((m['distanceMeters'] ?? m['distance'] ?? 0) as num).toDouble(),
    timeGap: Duration(hours: ((m['timeGapHours'] ?? 0) as num).toInt()),
  );
}

int statsIntOf(Map m, String k, [int fallback = 0]) {
  final v = m[k];
  if (v is num) return v.toInt();
  return fallback;
}

/// Normalizes backend naming differences (snake_case vs camelCase,
/// `lat/lng` vs `latitude/longitude`, etc.) into [ChildCase.fromJson] shape.
Map<String, dynamic> normalizeCaseJson(Map<String, dynamic> json) {
  T pick<T>(List<String> keys, [T? fallback]) {
    for (final k in keys) {
      if (json[k] != null) return json[k] as T;
      final snake = camelToSnake(k);
      if (json[snake] != null) return json[snake] as T;
    }
    return fallback as T;
  }

  final coordsRaw = pick<Map?>(['coordinates', 'location', 'geo'], null);
  Map<String, dynamic>? coords;
  if (coordsRaw is Map) {
    final m = coordsRaw.map((k, v) => MapEntry(k.toString(), v));
    final lat = m['lat'] ?? m['latitude'];
    final lng = m['lng'] ?? m['longitude'] ?? m['lon'];
    if (lat is num && lng is num) coords = {'lat': lat.toDouble(), 'lng': lng.toDouble()};
  } else {
    final lat = json['lat'] ?? json['latitude'];
    final lng = json['lng'] ?? json['longitude'] ?? json['lon'];
    if (lat is num && lng is num) coords = {'lat': lat.toDouble(), 'lng': lng.toDouble()};
  }

  String str(List<String> keys, [String fallback = '']) =>
      (pick<dynamic>(keys, fallback) ?? fallback).toString();

  dynamic extractPhotoPath() {
    if (json['photoPath'] != null) return json['photoPath'];
    if (json['photo'] != null) return json['photo'];
    if (json['imageUrl'] != null) return json['imageUrl'];
    if (json['photos'] is List && (json['photos'] as List).isNotEmpty) {
      final first = (json['photos'] as List)[0];
      if (first is Map) return first['url'] ?? first['path'];
    }
    return null;
  }

  String mapStatus(String raw) {
    final s = raw.toLowerCase();
    if (s == 'open') return 'published';
    if (s == 'closed') return 'caseClosed';
    if (s == 'under_review' || s == 'underreview') return 'underReview';
    if (s == 'possiblesighting' || s == 'possible_sighting') return 'possibleSighting';
    if (s == 'childfound' || s == 'child_found') return 'childFound';
    if (s == 'caseclosed' || s == 'case_closed') return 'caseClosed';
    if (s == 'reported') return 'reported';
    return 'published';
  }

  String mapGender(String raw) {
    final g = raw.toLowerCase();
    if (g == 'female' || g == 'f') return 'female';
    return 'male';
  }

  String mapType(String raw) {
    final t = raw.toLowerCase();
    if (t == 'found') return 'found';
    return 'missing';
  }

  return {
    'id': str(['id', '_id', 'report_id']),
    'type': mapType(str(['type', 'kind'], 'missing')),
    'name': str(['name', 'childName'], 'Unknown'),
    'age': pick<num>(['age', 'estimatedAge'], 0).toInt(),
    'gender': mapGender(str(['gender'], 'male')),
    'status': mapStatus(str(['status'], 'published')),
    'urgency': str(['urgency', 'priority'], 'medium').toLowerCase(),
    'lastKnownLocation': str(['lastKnownLocation', 'lastLocation', 'address']),
    'city': str(['city']),
    'area': str(['area', 'district']),
    'missingSince':
        str(['missingSince', 'missingAt', 'occurrence_date', 'createdAt'], DateTime.now().toIso8601String()),
    'lastSeen': str(['lastSeen', 'lastSeenAt', 'occurrence_date', 'updatedAt', 'missingSince'],
        DateTime.now().toIso8601String()),
    'clothing': str(['clothing']),
    'description': str(['description', 'details']),
    'distinguishingMarks': json['distinguishingMarks'] ?? json['marks'],
    'photoPath': extractPhotoPath(),
    'verified': json['verified'] ?? json['isVerified'] ?? false,
    'coordinates': coords ?? json['coordinates'],
    'createdAt': str(['created_at', 'createdAt']),
  };
}

String camelToSnake(String s) =>
    s.replaceAllMapped(RegExp('[A-Z]'), (m) => '_${m.group(0)!.toLowerCase()}');
