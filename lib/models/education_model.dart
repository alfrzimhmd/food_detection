// lib/models/education_model.dart
// SPDX-License-Identifier: Apache-2.0
import 'package:flutter/material.dart';

/// Model untuk data edukasi dari file JSON
@immutable
class EducationArticle {
  final int id;
  final String title;
  final String category;
  final String summary;
  final String content;
  final String? imageAsset;
  final int readTime; // dalam menit
  final String colorHex;

  const EducationArticle({
    required this.id,
    required this.title,
    required this.category,
    required this.summary,
    required this.content,
    this.imageAsset,
    required this.readTime,
    required this.colorHex,
  });

  /// Factory untuk membuat instance dari JSON
  factory EducationArticle.fromJson(Map<String, dynamic> json) {
    return EducationArticle(
      id: json['id'] as int,
      title: json['title'] as String,
      category: json['category'] as String,
      summary: json['summary'] as String,
      content: json['content'] as String,
      imageAsset: json['imageAsset'] as String?,
      readTime: json['readTime'] as int? ?? 3,
      colorHex: json['colorHex'] as String? ?? '#4CAF72',
    );
  }

  /// Konversi ke JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'summary': summary,
      'content': content,
      'imageAsset': imageAsset,
      'readTime': readTime,
      'colorHex': colorHex,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EducationArticle &&
        other.id == id &&
        other.title == title &&
        other.category == category;
  }

  @override
  int get hashCode => id.hashCode ^ title.hashCode ^ category.hashCode;
}

/// Model untuk kategori edukasi beserta jumlah artikel
class EducationCategory {
  final String name;
  final int count;
  final Color color;

  EducationCategory({
    required this.name,
    required this.count,
    required this.color,
  });
}