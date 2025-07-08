import 'package:hive/hive.dart';

part 'video_with_subtitle.g.dart';

@HiveType(typeId: 0)
class VideoWithSubtitle extends HiveObject {
  @HiveField(0)
  String videoId;

  @HiveField(1)
  String youtubeUrl;

  @HiveField(2)
  String title;

  @HiveField(3)
  String thumbnail;

  @HiveField(4)
  String srtContent;

  @HiveField(5)
  String srtFileName;

  @HiveField(6)
  DateTime lastWatched;

  @HiveField(7)
  int lastPositionMs;

  @HiveField(8)
  int totalDurationMs;

  @HiveField(9)
  int subtitleCount;

  VideoWithSubtitle({
    required this.videoId,
    required this.youtubeUrl,
    required this.title,
    required this.thumbnail,
    required this.srtContent,
    required this.srtFileName,
    required this.lastWatched,
    this.lastPositionMs = 0,
    this.totalDurationMs = 0,
    this.subtitleCount = 0,
  });

  // Create from video input data
  factory VideoWithSubtitle.fromInput({
    required String videoId,
    required String youtubeUrl,
    required String srtContent,
    required String srtFileName,
    String? title,
    String? thumbnail,
  }) {
    return VideoWithSubtitle(
      videoId: videoId,
      youtubeUrl: youtubeUrl,
      title: title ?? 'YouTube Video',
      thumbnail: thumbnail ?? 'https://img.youtube.com/vi/$videoId/maxresdefault.jpg',
      srtContent: srtContent,
      srtFileName: srtFileName,
      lastWatched: DateTime.now(),
    );
  }

  // Duration getters/setters
  Duration get lastPosition => Duration(milliseconds: lastPositionMs);
  set lastPosition(Duration duration) => lastPositionMs = duration.inMilliseconds;

  Duration get totalDuration => Duration(milliseconds: totalDurationMs);
  set totalDuration(Duration duration) => totalDurationMs = duration.inMilliseconds;

  // Get progress percentage
  double get progressPercentage {
    if (totalDurationMs == 0) return 0.0;
    return (lastPositionMs / totalDurationMs).clamp(0.0, 1.0);
  }

  // Check if video was recently watched (within 7 days)
  bool get isRecentlyWatched {
    final now = DateTime.now();
    final difference = now.difference(lastWatched);
    return difference.inDays <= 7;
  }

  // Format last watched time
  String get formattedLastWatched {
    final now = DateTime.now();
    final difference = now.difference(lastWatched);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} ngày trước';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} phút trước';
    } else {
      return 'Vừa xem';
    }
  }

  // Format duration
  String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }

  // Update watch progress
  void updateProgress(Duration position, Duration total) {
    lastPosition = position;
    totalDuration = total;
    lastWatched = DateTime.now();
    save(); // Save to Hive
  }

  @override
  String toString() {
    return 'VideoWithSubtitle(videoId: $videoId, title: $title, srtFileName: $srtFileName)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VideoWithSubtitle && other.videoId == videoId;
  }

  @override
  int get hashCode => videoId.hashCode;
}
