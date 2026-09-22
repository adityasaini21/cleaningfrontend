class NotificationModel {

  final int id;

  final String title;

  final String message;

  bool isRead;

  final String createdAt;

  NotificationModel({

    required this.id,

    required this.title,

    required this.message,

    required this.isRead,

    required this.createdAt,
  });

  factory NotificationModel.fromJson(
      Map<String, dynamic> json) {

    return NotificationModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? "",
      message: json['message'] ?? "",
      isRead: json['read'] ?? false,
      createdAt: json['createdAt'] ?? "",
    );
  }

  String get formattedTitle => _formatOrderCode(title);
  String get formattedMessage => _formatOrderCode(message);

  static String _formatOrderCode(String text) {
    return text.replaceAllMapped(RegExp(r'Order\s*#(?!\s*NUK)(\d+)', caseSensitive: false), (match) {
      return 'Order #NUK${match.group(1)}';
    });
  }
}