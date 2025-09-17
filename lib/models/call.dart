// lib/models/call.dart
class Call {
  final String callId;
  final String transcript;
  final String summary;
  final List<String> participants;
  final int durationSecs;
  final DateTime timestamp;
  final String processedBy;
  final List<String> actionIds;
  final String? audioStoragePath;
  final CallType callType;
  final String? contactName;
  final CallPriority priority;
  final String sentiment;
  final String category;
  final List<String> keyPoints;
  final CallStatus status;
  final Map<String, dynamic> metadata;

  Call({
    required this.callId,
    required this.transcript,
    required this.summary,
    required this.participants,
    required this.durationSecs,
    required this.timestamp,
    required this.processedBy,
    required this.actionIds,
    this.audioStoragePath,
    required this.callType,
    this.contactName,
    required this.priority,
    required this.sentiment,
    required this.category,
    required this.keyPoints,
    required this.status,
    this.metadata = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'callId': callId,
      'transcript': transcript,
      'summary': summary,
      'participants': participants,
      'durationSecs': durationSecs,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'processedBy': processedBy,
      'actions': actionIds,
      'audioStoragePath': audioStoragePath,
      'callType': callType.toString(),
      'contactName': contactName,
      'priority': priority.toString(),
      'sentiment': sentiment,
      'category': category,
      'keyPoints': keyPoints,
      'status': status.toString(),
      'metadata': metadata,
    };
  }

  factory Call.fromMap(Map<String, dynamic> map, String documentId) {
    return Call(
      callId: documentId,
      transcript: map['transcript'] ?? '',
      summary: map['summary'] ?? '',
      participants: List<String>.from(map['participants'] ?? []),
      durationSecs: map['durationSecs'] ?? 0,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] ?? 0),
      processedBy: map['processedBy'] ?? 'n8n',
      actionIds: List<String>.from(map['actions'] ?? []),
      audioStoragePath: map['audioStoragePath'],
      callType: CallType.values.firstWhere(
        (e) => e.toString() == map['callType'],
        orElse: () => CallType.incoming,
      ),
      contactName: map['contactName'],
      priority: CallPriority.values.firstWhere(
        (e) => e.toString() == map['priority'],
        orElse: () => CallPriority.medium,
      ),
      sentiment: map['sentiment'] ?? 'neutral',
      category: map['category'] ?? 'general',
      keyPoints: List<String>.from(map['keyPoints'] ?? []),
      status: CallStatus.values.firstWhere(
        (e) => e.toString() == map['status'],
        orElse: () => CallStatus.processed,
      ),
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
    );
  }

  Call copyWith({
    String? transcript,
    String? summary,
    List<String>? actionIds,
    CallPriority? priority,
    String? sentiment,
    String? category,
    List<String>? keyPoints,
    CallStatus? status,
    Map<String, dynamic>? metadata,
  }) {
    return Call(
      callId: callId,
      transcript: transcript ?? this.transcript,
      summary: summary ?? this.summary,
      participants: participants,
      durationSecs: durationSecs,
      timestamp: timestamp,
      processedBy: processedBy,
      actionIds: actionIds ?? this.actionIds,
      audioStoragePath: audioStoragePath,
      callType: callType,
      contactName: contactName,
      priority: priority ?? this.priority,
      sentiment: sentiment ?? this.sentiment,
      category: category ?? this.category,
      keyPoints: keyPoints ?? this.keyPoints,
      status: status ?? this.status,
      metadata: metadata ?? this.metadata,
    );
  }
}

enum CallType {
  incoming,
  outgoing,
  missed,
}

enum CallPriority {
  low,
  medium,
  high,
  urgent,
}

enum CallStatus {
  processing,
  processed,
  failed,
  archived,
}
