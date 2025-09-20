/// Common enums used across the application

enum PriorityLevel {
  low('Low'),
  medium('Medium'),
  high('High'),
  urgent('Urgent');

  const PriorityLevel(this.label);
  final String label;
}

enum SummaryType {
  call('Call'),
  notification('Notification'),
  task('Task'),
  note('Note');

  const SummaryType(this.label);
  final String label;
}

enum CallType {
  incoming('Incoming'),
  outgoing('Outgoing'),
  missed('Missed');

  const CallType(this.label);
  final String label;
}

enum NotificationType {
  financial('Financial'),
  social('Social'),
  shopping('Shopping'),
  entertainment('Entertainment'),
  news('News'),
  productivity('Productivity'),
  health('Health'),
  travel('Travel'),
  other('Other');

  const NotificationType(this.label);
  final String label;
}

enum DeviceConnectionStatus {
  connected('Connected'),
  connecting('Connecting'),
  disconnected('Disconnected'),
  error('Error');

  const DeviceConnectionStatus(this.label);
  final String label;
}

enum AIProcessingStatus {
  processing('Processing'),
  completed('Completed'),
  failed('Failed'),
  pending('Pending');

  const AIProcessingStatus(this.label);
  final String label;
}

enum SentimentType {
  positive('Positive'),
  negative('Negative'),
  neutral('Neutral'),
  mixed('Mixed');

  const SentimentType(this.label);
  final String label;
}

enum UrgencyLevel {
  low('Low'),
  medium('Medium'),
  high('High'),
  critical('Critical');

  const UrgencyLevel(this.label);
  final String label;
}

class SummaryItem {
  final String title;
  final String summary;
  final String subtitle;
  final SummaryType type;
  final PriorityLevel priority;

  const SummaryItem({
    required this.title,
    required this.summary,
    required this.subtitle,
    required this.type,
    required this.priority,
  });
}
