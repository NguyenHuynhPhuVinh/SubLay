// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'video_with_subtitle.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class VideoWithSubtitleAdapter extends TypeAdapter<VideoWithSubtitle> {
  @override
  final int typeId = 0;

  @override
  VideoWithSubtitle read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return VideoWithSubtitle(
      videoId: fields[0] as String,
      youtubeUrl: fields[1] as String,
      title: fields[2] as String,
      thumbnail: fields[3] as String,
      srtContent: fields[4] as String,
      srtFileName: fields[5] as String,
      lastWatched: fields[6] as DateTime,
      lastPosition: fields[7] as Duration,
      totalDuration: fields[8] as Duration,
      subtitleCount: fields[9] as int,
    );
  }

  @override
  void write(BinaryWriter writer, VideoWithSubtitle obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.videoId)
      ..writeByte(1)
      ..write(obj.youtubeUrl)
      ..writeByte(2)
      ..write(obj.title)
      ..writeByte(3)
      ..write(obj.thumbnail)
      ..writeByte(4)
      ..write(obj.srtContent)
      ..writeByte(5)
      ..write(obj.srtFileName)
      ..writeByte(6)
      ..write(obj.lastWatched)
      ..writeByte(7)
      ..write(obj.lastPosition)
      ..writeByte(8)
      ..write(obj.totalDuration)
      ..writeByte(9)
      ..write(obj.subtitleCount);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VideoWithSubtitleAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
