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
      
      // Parse text (can be multiple lines) - kiểm tra format đặc biệt trước
      final textLines = lines.skip(2).toList();
      final originalText = textLines.join('\n').trim();

      // Kiểm tra xem có phải format đặc biệt với dấu > không
      final rawText = _isSpecialQuoteFormat(originalText)
          ? originalText  // Giữ nguyên ngắt dòng cho format đặc biệt
          : textLines.join(' ').trim(); // Gộp thành 1 dòng cho format thường

      final text = _processSubtitleText(rawText);
      
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
      // Đảm bảo text được xử lý và ngắt dòng phù hợp
      buffer.writeln(_processSubtitleText(subtitle.text));
      
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
    // Sử dụng hàm xử lý subtitle mới để làm sạch text
    return _processSubtitleText(text);
  }

  // Xử lý nội dung subtitle sau khi gộp thành 1 dòng và ngắt dòng phù hợp
  static String _processSubtitleText(String text) {
    if (text.isEmpty) return text;

    // Kiểm tra xem có phải format đặc biệt với dấu > không
    if (_isSpecialQuoteFormat(text)) {
      return _processSpecialQuoteFormat(text);
    }

    // Bước 1: Loại bỏ các thẻ HTML và formatting
    String processedText = text
        .replaceAll(RegExp(r'<[^>]*>'), '') // Loại bỏ HTML tags
        .replaceAll(RegExp(r'\{[^}]*\}'), '') // Loại bỏ formatting tags như {an8}
        .replaceAll(RegExp(r'\[[^\]]*\]'), ''); // Loại bỏ các thẻ trong ngoặc vuông

    // Bước 2: Chuẩn hóa khoảng trắng - gộp nhiều khoảng trắng thành 1
    processedText = processedText.replaceAll(RegExp(r'\s+'), ' ');

    // Bước 3: Xử lý dấu câu - đảm bảo có khoảng trắng sau dấu câu
    processedText = processedText.replaceAllMapped(
      RegExp(r'([.!?,:;])([^\s])'),
      (match) => '${match.group(1)} ${match.group(2)}', // Thêm space sau dấu câu
    );
    processedText = processedText.replaceAllMapped(
      RegExp(r'\s+([.!?,:;])'),
      (match) => '${match.group(1)}', // Loại bỏ space trước dấu câu
    );

    // Bước 4: Xử lý dấu ngoặc
    processedText = processedText
        .replaceAll(RegExp(r'\(\s+'), '(') // Loại bỏ space sau dấu mở ngoặc
        .replaceAll(RegExp(r'\s+\)'), ')') // Loại bỏ space trước dấu đóng ngoặc
        .replaceAll(RegExp(r'\[\s+'), '[') // Loại bỏ space sau dấu mở ngoặc vuông
        .replaceAll(RegExp(r'\s+\]'), ']'); // Loại bỏ space trước dấu đóng ngoặc vuông

    // Bước 5: Xử lý dấu gạch nối và gạch dài
    processedText = processedText
        .replaceAll(RegExp(r'\s*-\s*'), ' - ') // Chuẩn hóa dấu gạch nối
        .replaceAll(RegExp(r'\s*—\s*'), ' — '); // Chuẩn hóa dấu gạch dài

    // Bước 6: Loại bỏ khoảng trắng thừa ở đầu và cuối
    processedText = processedText.trim();

    // Bước 7: Xử lý các trường hợp đặc biệt
    // Loại bỏ các ký tự điều khiển không mong muốn
    processedText = processedText.replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '');

    // Bước 8: Đảm bảo không có khoảng trắng kép
    processedText = processedText.replaceAll(RegExp(r'\s{2,}'), ' ');

    // Bước 9: Ngắt dòng thông minh sau khi đã gộp và xử lý
    processedText = _smartLineBreaking(processedText);

    return processedText.trim();
  }

  // Hàm ngắt dòng thông minh cho subtitle
  static String _smartLineBreaking(String text) {
    if (text.isEmpty) return text;

    // Cấu hình ngắt dòng
    const int maxLineLength = 42; // Độ dài tối đa mỗi dòng (chuẩn subtitle)
    const int maxLines = 2; // Tối đa 2 dòng cho subtitle

    // Nếu text ngắn hơn maxLineLength, giữ nguyên 1 dòng
    if (text.length <= maxLineLength) {
      return text;
    }

    // Tách text thành các từ
    final words = text.split(' ');
    if (words.length <= 1) {
      // Nếu chỉ có 1 từ dài, cắt cứng
      return _hardBreakLongWord(text, maxLineLength);
    }

    // Thử ngắt dòng thông minh
    final lines = <String>[];
    String currentLine = '';

    for (int i = 0; i < words.length; i++) {
      final word = words[i];
      final testLine = currentLine.isEmpty ? word : '$currentLine $word';

      // Kiểm tra xem có thể thêm từ này vào dòng hiện tại không
      if (testLine.length <= maxLineLength) {
        currentLine = testLine;
      } else {
        // Không thể thêm từ này, kết thúc dòng hiện tại
        if (currentLine.isNotEmpty) {
          lines.add(currentLine);
          currentLine = word;
        } else {
          // Từ này quá dài cho 1 dòng, cắt cứng
          final brokenWord = _hardBreakLongWord(word, maxLineLength);
          final brokenLines = brokenWord.split('\n');
          lines.addAll(brokenLines.take(brokenLines.length - 1));
          currentLine = brokenLines.last;
        }

        // Nếu đã đạt số dòng tối đa, gộp phần còn lại vào dòng cuối
        if (lines.length >= maxLines - 1) {
          final remainingWords = words.skip(i + 1).toList();
          if (remainingWords.isNotEmpty) {
            final remainingText = remainingWords.join(' ');
            currentLine = currentLine.isEmpty ? remainingText : '$currentLine $remainingText';
          }
          break;
        }
      }
    }

    // Thêm dòng cuối cùng
    if (currentLine.isNotEmpty) {
      lines.add(currentLine);
    }

    // Giới hạn số dòng tối đa
    final finalLines = lines.take(maxLines).toList();

    // Nếu có quá nhiều dòng, gộp dòng cuối
    if (lines.length > maxLines) {
      final lastLine = finalLines.last;
      final extraLines = lines.skip(maxLines).join(' ');
      finalLines[finalLines.length - 1] = '$lastLine $extraLines';
    }

    return finalLines.join('\n');
  }

  // Cắt cứng từ quá dài
  static String _hardBreakLongWord(String word, int maxLength) {
    if (word.length <= maxLength) return word;

    final lines = <String>[];
    for (int i = 0; i < word.length; i += maxLength) {
      final end = (i + maxLength < word.length) ? i + maxLength : word.length;
      lines.add(word.substring(i, end));
    }
    return lines.join('\n');
  }

  // Kiểm tra xem có phải format đặc biệt với dấu > không
  static bool _isSpecialQuoteFormat(String text) {
    final lines = text.split('\n');
    if (lines.length < 2) return false;

    // Kiểm tra xem có ít nhất 2 dòng bắt đầu bằng dấu > không
    int quoteLineCount = 0;
    for (final line in lines) {
      final trimmedLine = line.trim();
      if (trimmedLine.startsWith('>')) {
        quoteLineCount++;
      }
    }

    // Nếu có ít nhất 2 dòng bắt đầu bằng >, coi là format đặc biệt
    return quoteLineCount >= 2;
  }

  // Xử lý format đặc biệt với dấu > - giữ nguyên ngắt dòng
  static String _processSpecialQuoteFormat(String text) {
    final lines = text.split('\n');
    final processedLines = <String>[];

    for (final line in lines) {
      String processedLine = line.trim();

      // Loại bỏ các thẻ HTML và formatting nhưng giữ nguyên cấu trúc dòng
      processedLine = processedLine
          .replaceAll(RegExp(r'<[^>]*>'), '') // Loại bỏ HTML tags
          .replaceAll(RegExp(r'\{[^}]*\}'), '') // Loại bỏ formatting tags
          .replaceAll(RegExp(r'\[[^\]]*\]'), ''); // Loại bỏ các thẻ trong ngoặc vuông

      // Chuẩn hóa khoảng trắng trong dòng
      processedLine = processedLine.replaceAll(RegExp(r'\s+'), ' ').trim();

      // Xử lý dấu câu cho từng dòng bằng replaceAllMapped
      processedLine = processedLine.replaceAllMapped(
        RegExp(r'([.!?,:;])([^\s])'),
        (match) => '${match.group(1)} ${match.group(2)}',
      );
      processedLine = processedLine.replaceAllMapped(
        RegExp(r'\s+([.!?,:;])'),
        (match) => '${match.group(1)}',
      );

      // Xử lý dấu ngoặc
      processedLine = processedLine
          .replaceAll(RegExp(r'\(\s+'), '(')
          .replaceAll(RegExp(r'\s+\)'), ')')
          .replaceAll(RegExp(r'\[\s+'), '[')
          .replaceAll(RegExp(r'\s+\]'), ']');

      // Xử lý dấu gạch nối
      processedLine = processedLine
          .replaceAll(RegExp(r'\s*-\s*'), ' - ')
          .replaceAll(RegExp(r'\s*—\s*'), ' — ');

      // Loại bỏ ký tự điều khiển
      processedLine = processedLine.replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '');

      if (processedLine.isNotEmpty) {
        processedLines.add(processedLine);
      }
    }

    return processedLines.join('\n').trim();
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
