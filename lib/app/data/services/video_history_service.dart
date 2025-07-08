import 'package:get/get.dart';
import 'package:hive/hive.dart';
import '../models/video_with_subtitle.dart';

class VideoHistoryService extends GetxService {
  static const String _boxName = 'video_history';
  late Box<VideoWithSubtitle> _box;

  // Observable list of videos
  final videos = <VideoWithSubtitle>[].obs;

  @override
  Future<void> onInit() async {
    super.onInit();
    await _initHive();
    _loadVideos();
  }

  Future<void> _initHive() async {
    try {
      _box = await Hive.openBox<VideoWithSubtitle>(_boxName);
    } catch (e) {
      print('Error opening Hive box: $e');
      // If there's an error, try to delete and recreate the box
      await Hive.deleteBoxFromDisk(_boxName);
      _box = await Hive.openBox<VideoWithSubtitle>(_boxName);
    }
  }

  void _loadVideos() {
    videos.value = _box.values.toList();
    // Sort by last watched (most recent first)
    videos.sort((a, b) => b.lastWatched.compareTo(a.lastWatched));
  }

  // Add or update video in history (only save original data, no auto-update)
  Future<void> addOrUpdateVideo(VideoWithSubtitle video) async {
    try {
      // Check if video already exists
      final existingIndex = videos.indexWhere((v) => v.videoId == video.videoId);

      if (existingIndex != -1) {
        // Update existing video only if SRT content is different
        final existingVideo = videos[existingIndex];
        if (existingVideo.srtContent != video.srtContent ||
            existingVideo.srtFileName != video.srtFileName) {
          existingVideo.lastWatched = video.lastWatched;
          existingVideo.srtContent = video.srtContent;
          existingVideo.srtFileName = video.srtFileName;
          // Don't update position/duration - keep original data

          await existingVideo.save();
        }
      } else {
        // Add new video
        await _box.add(video);
        videos.add(video);
      }

      _loadVideos(); // Refresh and sort
    } catch (e) {
      print('Error adding/updating video: $e');
    }
  }

  // Remove video from history
  Future<void> removeVideo(String videoId) async {
    try {
      final video = videos.firstWhereOrNull((v) => v.videoId == videoId);
      if (video != null) {
        await video.delete();
        videos.remove(video);
      }
    } catch (e) {
      print('Error removing video: $e');
    }
  }

  // Clear all history
  Future<void> clearHistory() async {
    try {
      await _box.clear();
      videos.clear();
    } catch (e) {
      print('Error clearing history: $e');
    }
  }

  // Get video by ID
  VideoWithSubtitle? getVideo(String videoId) {
    return videos.firstWhereOrNull((v) => v.videoId == videoId);
  }

  // Get recent videos (within 7 days)
  List<VideoWithSubtitle> get recentVideos {
    return videos.where((v) => v.isRecentlyWatched).toList();
  }

  // Get videos with progress > 0
  List<VideoWithSubtitle> get videosWithProgress {
    return videos.where((v) => v.progressPercentage > 0).toList();
  }

  // Search videos by title or filename
  List<VideoWithSubtitle> searchVideos(String query) {
    if (query.isEmpty) return videos;
    
    final lowerQuery = query.toLowerCase();
    return videos.where((v) => 
      v.title.toLowerCase().contains(lowerQuery) ||
      v.srtFileName.toLowerCase().contains(lowerQuery)
    ).toList();
  }

  // Get statistics
  Map<String, dynamic> get statistics {
    return {
      'totalVideos': videos.length,
      'recentVideos': recentVideos.length,
      'videosWithProgress': videosWithProgress.length,
      'totalWatchTime': videos.fold<Duration>(
        Duration.zero,
        (total, video) => total + video.lastPosition,
      ),
    };
  }

  @override
  void onClose() {
    _box.close();
    super.onClose();
  }
}
