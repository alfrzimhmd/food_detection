// lib/services/education_service.dart
// SPDX-License-Identifier: Apache-2.0

import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import '../models/education_model.dart';

/// Service untuk mengelola data edukasi
class EducationService {
  static const String _educationJsonPath = 'assets/data/education_data.json';
  
  List<EducationArticle> _allArticles = [];
  
  /// Load data edukasi dari file JSON di assets
  Future<List<EducationArticle>> loadEducationData() async {
    try {
      final jsonString = await rootBundle.loadString(_educationJsonPath);
      final List<dynamic> jsonList = json.decode(jsonString);
      
      _allArticles = jsonList.map((json) => EducationArticle.fromJson(json)).toList();
      return _allArticles;
    } catch (e) {
      debugPrint('Error loading education data: $e');
      return [];
    }
  }
  
  /// Mendapatkan semua artikel
  List<EducationArticle> getAllArticles() {
    return _allArticles;
  }
  
  /// Mendapatkan artikel berdasarkan ID
  EducationArticle? getArticleById(int id) {
    try {
      return _allArticles.firstWhere((article) => article.id == id);
    } catch (e) {
      return null;
    }
  }
  
  /// Mendapatkan daftar kategori unik beserta jumlah artikel
  List<Map<String, dynamic>> getCategories() {
    final Map<String, int> categoryCount = {};
    
    for (final article in _allArticles) {
      categoryCount[article.category] = (categoryCount[article.category] ?? 0) + 1;
    }
    
    return categoryCount.entries.map((entry) {
      return {
        'name': entry.key,
        'count': entry.value,
      };
    }).toList();
  }
  
  /// Filter artikel berdasarkan kategori
  List<EducationArticle> getArticlesByCategory(String category) {
    return _allArticles.where((article) => article.category == category).toList();
  }
  
  /// Search artikel berdasarkan title atau content
  List<EducationArticle> searchArticles(String query) {
    if (query.trim().isEmpty) return _allArticles;
    
    final lowercaseQuery = query.toLowerCase().trim();
    return _allArticles.where((article) {
      return article.title.toLowerCase().contains(lowercaseQuery) ||
          article.summary.toLowerCase().contains(lowercaseQuery) ||
          article.content.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }
  
  /// Mendapatkan artikel terbaru (berdasarkan ID, asumsi ID terbaru = ID terbesar)
  List<EducationArticle> getLatestArticles({int limit = 3}) {
    final sorted = List<EducationArticle>.from(_allArticles)
      ..sort((a, b) => b.id.compareTo(a.id));
    return sorted.take(limit).toList();
  }
  
  /// Mendapatkan artikel rekomendasi untuk user (berdasarkan kategori yang sama)
  List<EducationArticle> getRecommendedArticles(EducationArticle article, {int limit = 3}) {
    final sameCategory = _allArticles.where((a) => 
      a.category == article.category && a.id != article.id
    ).toList();
    
    if (sameCategory.length >= limit) {
      return sameCategory.take(limit).toList();
    }
    
    // Jika tidak cukup, tambahkan artikel dari kategori lain
    final otherArticles = _allArticles.where((a) => 
      a.category != article.category && a.id != article.id
    ).toList();
    
    final combined = [...sameCategory, ...otherArticles];
    return combined.take(limit).toList();
  }
}