class DownloadItem {
  final String id;
  final String url;
  final String filename;
  final String savePath;
  final DateTime createdAt;

  const DownloadItem({
    required this.id,
    required this.url,
    required this.filename,
    required this.savePath,
    required this.createdAt,
  });

  // تحويل البيانات إلى صيغة قابلة للحفظ
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'filename': filename,
      'savePath': savePath,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // استرجاع البيانات من الصيغة المحفوظة
  factory DownloadItem.fromJson(Map<String, dynamic> json) {
    return DownloadItem(
      id: json['id'] as String,
      url: json['url'] as String,
      filename: json['filename'] as String,
      savePath: json['savePath'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
