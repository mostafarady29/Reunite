import '../../shared/domain/app_enums.dart';

class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.titleKey,
    required this.bodyKey,
    required this.createdAt,
    this.caseId,
    this.namedArgs = const {},
    this.read = false,
  });

  final String id;
  final AppNotificationType type;
  final String titleKey;
  final String bodyKey;
  final DateTime createdAt;
  final String? caseId;
  final Map<String, String> namedArgs;
  final bool read;

  bool get isEmergency => type == AppNotificationType.emergency;

  AppNotification copyWith({bool? read}) => AppNotification(
        id: id,
        type: type,
        titleKey: titleKey,
        bodyKey: bodyKey,
        createdAt: createdAt,
        caseId: caseId,
        namedArgs: namedArgs,
        read: read ?? this.read,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'titleKey': titleKey,
        'title': titleKey,
        'bodyKey': bodyKey,
        'body': bodyKey,
        'createdAt': createdAt.toIso8601String(),
        'caseId': caseId,
        'namedArgs': namedArgs,
        'read': read,
      };

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    AppNotificationType type;
    final rawType = json['type'] as String?;
    if (rawType == 'emergency' || rawType == 'missing_report_nearby') {
      type = AppNotificationType.emergency;
    } else if (rawType == 'possibleMatch' || rawType == 'possible_match') {
      type = AppNotificationType.possibleMatch;
    } else if (rawType == 'success') {
      type = AppNotificationType.success;
    } else {
      type = AppNotificationType.caseUpdate;
    }
    return AppNotification(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      type: type,
      titleKey: (json['titleKey'] ?? json['title'] ?? '') as String,
      bodyKey: (json['bodyKey'] ?? json['body'] ?? '') as String,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      caseId: json['caseId'] as String?,
      namedArgs: (json['namedArgs'] as Map?)?.map(
            (k, v) => MapEntry(k.toString(), v.toString()),
          ) ??
          const {},
      read: (json['read'] ?? json['isRead'] ?? false) as bool,
    );
  }
}