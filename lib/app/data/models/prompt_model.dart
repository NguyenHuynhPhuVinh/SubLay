import 'package:hive/hive.dart';

part 'prompt_model.g.dart';

@HiveType(typeId: 2)
class PromptModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String content;

  @HiveField(3)
  String description;

  @HiveField(4)
  DateTime createdAt;

  @HiveField(5)
  DateTime updatedAt;

  @HiveField(6)
  bool isDefault;

  @HiveField(7)
  String category;

  PromptModel({
    required this.id,
    required this.title,
    required this.content,
    required this.description,
    required this.createdAt,
    required this.updatedAt,
    this.isDefault = false,
    this.category = 'General',
  });

  PromptModel copyWith({
    String? id,
    String? title,
    String? content,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDefault,
    String? category,
  }) {
    return PromptModel(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDefault: isDefault ?? this.isDefault,
      category: category ?? this.category,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isDefault': isDefault,
      'category': category,
    };
  }

  factory PromptModel.fromJson(Map<String, dynamic> json) {
    return PromptModel(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      description: json['description'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      isDefault: json['isDefault'] ?? false,
      category: json['category'] ?? 'General',
    );
  }
}
