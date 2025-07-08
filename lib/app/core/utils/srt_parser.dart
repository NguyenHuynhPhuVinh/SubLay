class SrtSubtitle {
  final int index;
  final Duration startTime;
  final Duration endTime;
  final String text;

  SrtSubtitle({
    required this.index,
    required this.startTime,
    required this.endTime,
    required this.text,
  });

  @override
  String toString() {
    return 'SrtSubtitle(index: $index, start: $startTime, end: $endTime, text: $text)';
  }
}

class SrtParser {
  static List<SrtSubtitle> parse(String srtContent) {
    final List<SrtSubtitle> subtitles = [];
    
    if (srtContent.trim().isEmpty) {
      return subtitles;
    }

    // Split by double newlines to separate subtitle blocks
    final blocks = srtContent.split(RegExp(r'\n\s*\n'));
    
    for (final block in blocks) {
      final subtitle = _parseBlock(block.trim());
      if (subtitle != null) {
        subtitles.add(subtitle);
      }
    }
    
    return subtitles;
  }

  static SrtSubtitle? _parseBlock(String block) {
    if (block.isEmpty) return null;
    
    final lines = block.split('\n');
    if (lines.length < 3) return null;

    try {
      // Parse index
      final index = int.parse(lines[0].trim());
      
      // Parse time range
      final timeRange = lines[1].trim();
      final times = _parseTimeRange(timeRange);
      if (times == null) return null;
      
      // Parse text (can be multiple lines)
      final text = lines.skip(2).join('\n').trim();
      
      return SrtSubtitle(
        index: index,
        startTime: times['start']!,
        endTime: times['end']!,
        text: text,
      );
    } catch (e) {
      print('Error parsing SRT block: $e');
      return null;
    }
  }

  static Map<String, Duration>? _parseTimeRange(String timeRange) {
    // Format: 00:00:01,000 --> 00:00:04,000
    final regex = RegExp(r'(\d{2}):(\d{2}):(\d{2}),(\d{3})\s*-->\s*(\d{2}):(\d{2}):(\d{2}),(\d{3})');
    final match = regex.firstMatch(timeRange);
    
    if (match == null) return null;
    
    try {
      final startTime = Duration(
        hours: int.parse(match.group(1)!),
        minutes: int.parse(match.group(2)!),
        seconds: int.parse(match.group(3)!),
        milliseconds: int.parse(match.group(4)!),
      );
      
      final endTime = Duration(
        hours: int.parse(match.group(5)!),
        minutes: int.parse(match.group(6)!),
        seconds: int.parse(match.group(7)!),
        milliseconds: int.parse(match.group(8)!),
      );
      
      return {
        'start': startTime,
        'end': endTime,
      };
    } catch (e) {
      print('Error parsing time range: $e');
      return null;
    }
  }

  static String formatTime(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    final milliseconds = (duration.inMilliseconds % 1000).toString().padLeft(3, '0');
    
    return '$hours:$minutes:$seconds,$milliseconds';
  }

  static String generateSrt(List<SrtSubtitle> subtitles) {
    final buffer = StringBuffer();
    
    for (int i = 0; i < subtitles.length; i++) {
      final subtitle = subtitles[i];
      
      buffer.writeln(subtitle.index);
      buffer.writeln('${formatTime(subtitle.startTime)} --> ${formatTime(subtitle.endTime)}');
      buffer.writeln(subtitle.text);
      
      if (i < subtitles.length - 1) {
        buffer.writeln();
      }
    }
    
    return buffer.toString();
  }

  static String findCurrentSubtitle(List<SrtSubtitle> subtitles, Duration currentTime) {
    for (final subtitle in subtitles) {
      if (currentTime >= subtitle.startTime && currentTime <= subtitle.endTime) {
        return subtitle.text;
      }
    }
    return '';
  }

  static bool isValidSrtContent(String content) {
    if (content.trim().isEmpty) return false;
    
    // Basic validation - check if it contains time format
    final timeRegex = RegExp(r'\d{2}:\d{2}:\d{2},\d{3}\s*-->\s*\d{2}:\d{2}:\d{2},\d{3}');
    return timeRegex.hasMatch(content);
  }

  static String cleanSrtText(String text) {
    // Remove HTML tags and clean up text
    return text
        .replaceAll(RegExp(r'<[^>]*>'), '') // Remove HTML tags
        .replaceAll(RegExp(r'\{[^}]*\}'), '') // Remove formatting tags
        .replaceAll(RegExp(r'\s+'), ' ') // Normalize whitespace
        .trim();
  }
}
