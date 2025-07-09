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

class SrtValidationResult {
  final bool isValid;
  final List<String> formatErrors;
  final List<String> timelineErrors;
  final List<String> silenceGaps;
  final String? fixedContent;
  final int formatFixesCount;

  SrtValidationResult({
    required this.isValid,
    required this.formatErrors,
    required this.timelineErrors,
    required this.silenceGaps,
    this.fixedContent,
    this.formatFixesCount = 0,
  });
}

class SilenceGap {
  final double gapSeconds;
  final int currentSubIndex;
  final int nextSubIndex;
  final String endTime;
  final String startTime;

  SilenceGap({
    required this.gapSeconds,
    required this.currentSubIndex,
    required this.nextSubIndex,
    required this.endTime,
    required this.startTime,
  });
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

  // Generate SRT with smart line breaking
  static String generateSrtWithSmartLineBreaking(List<SrtSubtitle> subtitles, {int maxLineLength = 35}) {
    final buffer = StringBuffer();

    for (int i = 0; i < subtitles.length; i++) {
      final subtitle = subtitles[i];
      final smartText = _applySmartLineBreaking(subtitle.text, maxLineLength);

      buffer.writeln(subtitle.index);
      buffer.writeln('${formatTime(subtitle.startTime)} --> ${formatTime(subtitle.endTime)}');
      buffer.writeln(smartText);

      if (i < subtitles.length - 1) {
        buffer.writeln();
      }
    }

    return buffer.toString();
  }

  // Apply smart line breaking to subtitle text
  static String _applySmartLineBreaking(String text, int maxLineLength) {
    // Tách các dòng hiện có (do SRT định dạng)
    final existingLines = text.split('\n');
    final processedLines = <String>[];

    for (final line in existingLines) {
      if (line.trim().isEmpty) {
        processedLines.add('');
        continue;
      }

      // Nếu dòng ngắn hơn maxLineLength, giữ nguyên
      if (line.length <= maxLineLength) {
        processedLines.add(line);
        continue;
      }

      // Ngắt dòng thông minh
      final brokenLines = _breakLongLine(line, maxLineLength);
      processedLines.addAll(brokenLines);
    }

    return processedLines.join('\n');
  }

  // Break long line into multiple lines intelligently
  static List<String> _breakLongLine(String line, int maxLineLength) {
    final words = line.split(' ');
    final lines = <String>[];
    String currentLine = '';

    for (final word in words) {
      // Nếu từ đơn lẻ quá dài, cắt cứng
      if (word.length > maxLineLength) {
        if (currentLine.isNotEmpty) {
          lines.add(currentLine.trim());
          currentLine = '';
        }

        // Cắt từ dài thành nhiều phần
        final chunks = _breakLongWord(word, maxLineLength);
        lines.addAll(chunks.take(chunks.length - 1));
        currentLine = chunks.last;
        continue;
      }

      // Kiểm tra nếu thêm từ này có vượt quá độ dài
      final testLine = currentLine.isEmpty ? word : '$currentLine $word';

      if (testLine.length <= maxLineLength) {
        currentLine = testLine;
      } else {
        // Xuống dòng
        if (currentLine.isNotEmpty) {
          lines.add(currentLine.trim());
        }
        currentLine = word;
      }
    }

    // Thêm dòng cuối
    if (currentLine.isNotEmpty) {
      lines.add(currentLine.trim());
    }

    return lines.isEmpty ? [''] : lines;
  }

  // Break very long word into chunks
  static List<String> _breakLongWord(String word, int maxLength) {
    final chunks = <String>[];
    for (int i = 0; i < word.length; i += maxLength) {
      final end = (i + maxLength < word.length) ? i + maxLength : word.length;
      chunks.add(word.substring(i, end));
    }
    return chunks;
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

  // Process SRT content with smart line breaking and validation
  static SrtValidationResult processAndOptimizeSrt(String content, {int maxLineLength = 35}) {
    if (content.trim().isEmpty) {
      return SrtValidationResult(
        isValid: false,
        formatErrors: ['Nội dung SRT trống'],
        timelineErrors: [],
        silenceGaps: [],
      );
    }

    // Step 1: Parse original content
    final subtitles = parse(content);
    if (subtitles.isEmpty) {
      return SrtValidationResult(
        isValid: false,
        formatErrors: ['Không thể parse nội dung SRT'],
        timelineErrors: [],
        silenceGaps: [],
      );
    }

    // Step 2: Apply smart line breaking
    final optimizedSubtitles = subtitles.map((subtitle) {
      final optimizedText = _applySmartLineBreaking(subtitle.text, maxLineLength);
      return SrtSubtitle(
        index: subtitle.index,
        startTime: subtitle.startTime,
        endTime: subtitle.endTime,
        text: optimizedText,
      );
    }).toList();

    // Step 3: Generate optimized content
    final optimizedContent = generateSrt(optimizedSubtitles);

    // Step 4: Validate the optimized content
    final validationResult = validateAndFixSrt(optimizedContent);

    // Return result with optimized content
    return SrtValidationResult(
      isValid: validationResult.isValid,
      formatErrors: validationResult.formatErrors,
      timelineErrors: validationResult.timelineErrors,
      silenceGaps: validationResult.silenceGaps,
      fixedContent: optimizedContent,
      formatFixesCount: validationResult.formatFixesCount + 1, // +1 for line breaking optimization
    );
  }

  // Validate and fix SRT content
  static SrtValidationResult validateAndFixSrt(String content) {
    if (content.trim().isEmpty) {
      return SrtValidationResult(
        isValid: false,
        formatErrors: ['Nội dung SRT trống'],
        timelineErrors: [],
        silenceGaps: [],
      );
    }

    final lines = content.split('\n');
    final fixedLines = <String>[];
    final formatErrors = <String>[];
    final timelineErrors = <String>[];
    final silenceGaps = <String>[];
    int formatFixesCount = 0;

    // Pattern cho dòng thời gian
    final timePattern = RegExp(r'^(.+?)\s*-->\s*(.+?)$');
    final subtitleInfos = <Map<String, dynamic>>[];

    // Pass 1: Sửa định dạng thời gian và thu thập thông tin subtitle
    for (int i = 0; i < lines.length; i++) {
      final originalLine = lines[i];
      final line = lines[i].trim();

      final match = timePattern.firstMatch(line);
      if (match != null) {
        final startTime = match.group(1)!.trim();
        final endTime = match.group(2)!.trim();

        // Sửa định dạng thời gian
        final fixedStart = _fixTimeFormat(startTime);
        final fixedEnd = _fixTimeFormat(endTime);

        final fixedLine = '$fixedStart --> $fixedEnd';

        // Kiểm tra xem có thay đổi không
        if (fixedLine != line) {
          formatErrors.add('Dòng ${i + 1}: $line -> $fixedLine');
          formatFixesCount++;
        }

        // Lưu thông tin subtitle để kiểm tra timeline
        final startMs = _timeToMilliseconds(fixedStart);
        final endMs = _timeToMilliseconds(fixedEnd);

        if (startMs != null && endMs != null) {
          subtitleInfos.add({
            'lineNumber': i + 1,
            'subtitleNumber': subtitleInfos.length + 1,
            'startTime': fixedStart,
            'endTime': fixedEnd,
            'startMs': startMs,
            'endMs': endMs,
          });
        }

        fixedLines.add(fixedLine);
      } else {
        // Giữ nguyên dòng không phải thời gian
        fixedLines.add(originalLine.trimRight());
      }
    }

    // Pass 2: Kiểm tra timeline
    for (int i = 0; i < subtitleInfos.length; i++) {
      final subtitle = subtitleInfos[i];

      // Kiểm tra start_time < end_time
      if (subtitle['startMs'] >= subtitle['endMs']) {
        timelineErrors.add(
          'Subtitle ${subtitle['subtitleNumber']} (dòng ${subtitle['lineNumber']}): '
          'Thời gian bắt đầu >= thời gian kết thúc (${subtitle['startTime']} --> ${subtitle['endTime']})'
        );
      }

      // Kiểm tra overlap với subtitle tiếp theo
      if (i < subtitleInfos.length - 1) {
        final nextSubtitle = subtitleInfos[i + 1];
        if (subtitle['endMs'] > nextSubtitle['startMs']) {
          timelineErrors.add(
            'Subtitle ${subtitle['subtitleNumber']} và ${nextSubtitle['subtitleNumber']}: '
            'Thời gian overlap (${subtitle['endTime']} > ${nextSubtitle['startTime']})'
          );
        }
      }
    }

    // Pass 3: Kiểm tra khoảng lặng > 2.5 giây
    const silenceThresholdMs = 2500; // 2.5 giây
    final gaps = <SilenceGap>[];

    for (int i = 0; i < subtitleInfos.length - 1; i++) {
      final current = subtitleInfos[i];
      final next = subtitleInfos[i + 1];

      final gapMs = next['startMs'] - current['endMs'];
      if (gapMs > silenceThresholdMs) {
        final gapSeconds = gapMs / 1000.0;
        gaps.add(SilenceGap(
          gapSeconds: gapSeconds,
          currentSubIndex: current['subtitleNumber'],
          nextSubIndex: next['subtitleNumber'],
          endTime: current['endTime'],
          startTime: next['startTime'],
        ));
      }
    }

    // Sắp xếp gaps từ cao xuống thấp
    gaps.sort((a, b) => b.gapSeconds.compareTo(a.gapSeconds));

    // Tạo danh sách silence gaps
    for (final gap in gaps) {
      silenceGaps.add(
        'Khoảng lặng ${gap.gapSeconds.toStringAsFixed(1)}s giữa subtitle '
        '${gap.currentSubIndex} và ${gap.nextSubIndex} '
        '(từ ${gap.endTime} đến ${gap.startTime})'
      );
    }

    final isValid = formatErrors.isEmpty && timelineErrors.isEmpty;
    final fixedContent = formatFixesCount > 0 ? fixedLines.join('\n') : null;

    return SrtValidationResult(
      isValid: isValid,
      formatErrors: formatErrors,
      timelineErrors: timelineErrors,
      silenceGaps: silenceGaps,
      fixedContent: fixedContent,
      formatFixesCount: formatFixesCount,
    );
  }
  // Helper methods for time format fixing
  static String _fixTimeFormat(String timeStr) {
    timeStr = timeStr.trim();
    final originalTime = timeStr;

    // Các pattern để sửa lỗi định dạng thời gian
    final patterns = [
      // Pattern 1: MM:SS,mmm (thiếu giờ) -> 00:MM:SS,mmm
      {
        'pattern': RegExp(r'^(\d{1,2}):(\d{2}),(\d{3})$'),
        'replacement': (Match m) => '00:${m.group(1)!.padLeft(2, '0')}:${m.group(2)},${m.group(3)}',
      },
      // Pattern 2: H:MM:mmm (dấu : thay vì ,) -> 0H:MM,mmm
      {
        'pattern': RegExp(r'^(\d):(\d{2}):(\d{3})$'),
        'replacement': (Match m) => '00:0${m.group(1)}:${m.group(2)},${m.group(3)}',
      },
      // Pattern 3: HH:MM:mmm (dấu : thay vì ,) -> HH:MM,mmm
      {
        'pattern': RegExp(r'^(\d{2}):(\d{2}):(\d{3})$'),
        'replacement': (Match m) => '00:${m.group(1)}:${m.group(2)},${m.group(3)}',
      },
      // Pattern 4: H:MM,mmm -> 0H:MM,mmm
      {
        'pattern': RegExp(r'^(\d):(\d{2}),(\d{3})$'),
        'replacement': (Match m) => '00:0${m.group(1)}:${m.group(2)},${m.group(3)}',
      },
      // Pattern 5: 00:0MM,mmm (thiếu số 0 ở phút) -> 00:MM,mmm
      {
        'pattern': RegExp(r'^(\d{2}):0(\d{1}),(\d{3})$'),
        'replacement': (Match m) => '${m.group(1)}:0${m.group(2)},${m.group(3)}',
      },
      // Pattern 6: 00:0MM:mmm (thiếu số 0 ở phút + dấu : thay vì ,) -> 00:0MM,mmm
      {
        'pattern': RegExp(r'^(\d{2}):0(\d{1}):(\d{3})$'),
        'replacement': (Match m) => '${m.group(1)}:0${m.group(2)},${m.group(3)}',
      },
      // Pattern 7: 00:MMM,mmm (3 chữ số phút - lỗi format) -> 00:0M:MM,mmm
      {
        'pattern': RegExp(r'^(\d{2}):(\d{3}),(\d{3})$'),
        'replacement': (Match m) {
          final minutes = m.group(2)!;
          return '${m.group(1)}:0${minutes[0]}:${minutes.substring(1)},${m.group(3)}';
        },
      },
      // Pattern 8: 00:MMM:mmm (3 chữ số phút + dấu : thay vì ,) -> 00:0M:MM,mmm
      {
        'pattern': RegExp(r'^(\d{2}):(\d{3}):(\d{3})$'),
        'replacement': (Match m) {
          final minutes = m.group(2)!;
          return '${m.group(1)}:0${minutes[0]}:${minutes.substring(1)},${m.group(3)}';
        },
      },
    ];

    for (final patternData in patterns) {
      final pattern = patternData['pattern'] as RegExp;
      final replacement = patternData['replacement'] as Function;

      final match = pattern.firstMatch(timeStr);
      if (match != null) {
        final fixedTime = replacement(match) as String;
        // Validate format sau khi sửa
        if (_validateTimeFormat(fixedTime)) {
          return fixedTime;
        }
      }
    }

    // Nếu không match pattern nào, kiểm tra format chuẩn
    if (_validateTimeFormat(timeStr)) {
      return timeStr;
    }

    // Nếu vẫn không đúng format, trả về original
    return originalTime;
  }

  static bool _validateTimeFormat(String timeStr) {
    // Format chuẩn: HH:MM:SS,mmm
    final pattern = RegExp(r'^(\d{2}):(\d{2}):(\d{2}),(\d{3})$');
    final match = pattern.firstMatch(timeStr);
    if (match == null) return false;

    final hours = int.tryParse(match.group(1)!) ?? -1;
    final minutes = int.tryParse(match.group(2)!) ?? -1;
    final seconds = int.tryParse(match.group(3)!) ?? -1;
    final milliseconds = int.tryParse(match.group(4)!) ?? -1;

    return (hours >= 0 && hours <= 99 &&
            minutes >= 0 && minutes <= 59 &&
            seconds >= 0 && seconds <= 59 &&
            milliseconds >= 0 && milliseconds <= 999);
  }

  static int? _timeToMilliseconds(String timeStr) {
    if (!_validateTimeFormat(timeStr)) return null;

    final pattern = RegExp(r'^(\d{2}):(\d{2}):(\d{2}),(\d{3})$');
    final match = pattern.firstMatch(timeStr);
    if (match == null) return null;

    final hours = int.tryParse(match.group(1)!) ?? 0;
    final minutes = int.tryParse(match.group(2)!) ?? 0;
    final seconds = int.tryParse(match.group(3)!) ?? 0;
    final milliseconds = int.tryParse(match.group(4)!) ?? 0;

    return (hours * 3600 + minutes * 60 + seconds) * 1000 + milliseconds;
  }

  static String _millisecondsToTime(int ms) {
    final hours = ms ~/ 3600000;
    ms %= 3600000;
    final minutes = ms ~/ 60000;
    ms %= 60000;
    final seconds = ms ~/ 1000;
    final milliseconds = ms % 1000;

    return '${hours.toString().padLeft(2, '0')}:'
           '${minutes.toString().padLeft(2, '0')}:'
           '${seconds.toString().padLeft(2, '0')},'
           '${milliseconds.toString().padLeft(3, '0')}';
  }
}
