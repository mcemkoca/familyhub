class DriveBackup {
  final String fileId;
  final String name;
  final DateTime createdTime;
  final int? sizeBytes;

  const DriveBackup({
    required this.fileId,
    required this.name,
    required this.createdTime,
    this.sizeBytes,
  });

  String get formattedDate {
    final d = createdTime;
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    final year = d.year;
    final hour = d.hour.toString().padLeft(2, '0');
    final minute = d.minute.toString().padLeft(2, '0');
    return '$day.$month.$year $hour:$minute';
  }

  String get formattedSize {
    if (sizeBytes == null) return 'Bilinmiyor';
    final kb = sizeBytes! / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    final mb = kb / 1024;
    return '${mb.toStringAsFixed(1)} MB';
  }
}
