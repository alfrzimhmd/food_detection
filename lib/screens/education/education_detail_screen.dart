// lib/screens/education_detail_screen.dart
// SPDX-License-Identifier: Apache-2.0

import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../utils/text_style_helper.dart';
import '../../models/education_model.dart';
import '../../services/education_service.dart';

class EducationDetailScreen extends StatefulWidget {
  final EducationArticle article;
  
  const EducationDetailScreen({
    super.key,
    required this.article,
  });

  @override
  State<EducationDetailScreen> createState() => _EducationDetailScreenState();
}

class _EducationDetailScreenState extends State<EducationDetailScreen> {
  late EducationService _educationService;
  List<EducationArticle> _recommendations = [];
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    _educationService = EducationService();
    _loadRecommendations();
  }

  Future<void> _loadRecommendations() async {
    await _educationService.loadEducationData();
    setState(() {
      _recommendations = _educationService.getRecommendedArticles(widget.article);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final categoryColor = Color(int.parse(widget.article.colorHex.replaceFirst('#', '0xFF')));

    return Scaffold(
      backgroundColor: AppColors.backgroundColor(context),
      body: Column(
        children: [
          _buildAppBar(),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(categoryColor, isDark),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSummaryBox(categoryColor, isDark),
                        const SizedBox(height: 24),
                        _buildContent(isDark),
                        const SizedBox(height: 32),
                        const Divider(),
                        const SizedBox(height: 24),
                        if (_recommendations.isNotEmpty)
                          _buildRecommendationsSection(isDark),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      color: AppColors.primaryDark,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 12, 14),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 18),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.article.category,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: Icon(
                    _isSaved ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  onPressed: () {
                    setState(() => _isSaved = !_isSaved);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(_isSaved ? 'Artikel disimpan' : 'Artikel dihapus dari simpanan'),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Color categoryColor, bool isDark) {
    final hasImage = widget.article.imageAsset != null && widget.article.imageAsset!.isNotEmpty;
    
    if (hasImage) {
      return Stack(
        children: [
          Container(
            width: double.infinity,
            height: 240,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(widget.article.imageAsset!),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(
            width: double.infinity,
            height: 240,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.7),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 16,
            left: 20,
            right: 20,
            child: Text(
              widget.article.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
                height: 1.3,
              ),
            ),
          ),
        ],
      );
    } else {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: categoryColor.withValues(alpha: 0.1),
        ),
        child: Text(
          widget.article.title,
          style: TextStyleHelper.displaySmall.copyWith(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.textWhite : AppColors.textDark,
          ),
        ),
      );
    }
  }

  Widget _buildSummaryBox(Color categoryColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: categoryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: categoryColor.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.format_quote,
            color: categoryColor,
            size: 32,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.article.summary,
              style: TextStyleHelper.bodyLarge.copyWith(
                fontSize: 15,
                color: isDark ? AppColors.textWhite70 : AppColors.textMedium,
                fontStyle: FontStyle.italic,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(bool isDark) {
    return Text(
      _formatContent(widget.article.content),
      style: TextStyleHelper.bodyLarge.copyWith(
        fontSize: 18,
        color: isDark ? AppColors.textWhite70 : AppColors.textMedium,
        height: 1.7,
      ),
    );
  }

  // ============================================================
  // REKOMENDASI ARTIKEL - DIPERBAIKI DENGAN CARD GAMBAR
  // ============================================================
  
  Widget _buildRecommendationsSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.recommend_rounded, color: AppColors.primary, size: 18),
            ),
            const SizedBox(width: 12),
            Text(
              'Rekomendasi untuk Anda',
              style: TextStyleHelper.headline4.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.textWhite : AppColors.textDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _recommendations.length,
          separatorBuilder: (context, index) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final article = _recommendations[index];
            return _buildRecommendationCard(article, isDark);
          },
        ),
      ],
    );
  }

  Widget _buildRecommendationCard(EducationArticle article, bool isDark) {
    final categoryColor = Color(int.parse(article.colorHex.replaceFirst('#', '0xFF')));
    final hasImage = article.imageAsset != null && article.imageAsset!.isNotEmpty;
    
    return GestureDetector(
      onTap: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => EducationDetailScreen(article: article),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [AppColors.cardBackgroundDark, AppColors.cardBackgroundDark.withValues(alpha: 0.95)]
                : [Colors.white, Colors.white.withValues(alpha: 0.95)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner gambar dengan kategori overlay
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  child: hasImage
                      ? Image.asset(
                          article.imageAsset!,
                          height: 140,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 140,
                              width: double.infinity,
                              color: categoryColor.withValues(alpha: 0.2),
                              child: Icon(
                                Icons.image_not_supported,
                                size: 40,
                                color: categoryColor,
                              ),
                            );
                          },
                        )
                      : Container(
                          height: 140,
                          width: double.infinity,
                          color: categoryColor.withValues(alpha: 0.2),
                          child: Icon(
                            Icons.food_bank,
                            size: 40,
                            color: categoryColor,
                          ),
                        ),
                ),
                // Gradient overlay untuk teks kategori
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.7),
                        ],
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: categoryColor,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            article.category,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // Konten card
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article.title,
                    style: TextStyleHelper.titleMedium.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.textWhite : AppColors.textDark,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.format_quote,
                        size: 16,
                        color: categoryColor.withValues(alpha: 0.7),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          article.summary,
                          style: TextStyleHelper.bodySmall.copyWith(
                            fontSize: 14,
                            color: isDark ? AppColors.textWhite70 : AppColors.textLight,
                            height: 1.5,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'Baca Selengkapnya',
                        style: TextStyleHelper.labelMedium.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: categoryColor,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 16,
                        color: categoryColor,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatContent(String content) {
    String formatted = content;
    formatted = formatted.replaceAll('•', '\n•');
    formatted = formatted.replaceAll(RegExp(r'\*\*(.*?)\*\*'), r'\1');
    formatted = formatted.replaceAll(RegExp(r'(\d+)\.'), r'\n\1.');
    formatted = formatted.replaceAll('|', ' ');
    return formatted;
  }
}