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
                    Text(
                      '${widget.article.readTime} menit membaca',
                      style: const TextStyle(color: Colors.white60, fontSize: 12),
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
                fontSize: 22,
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
            fontSize: 22,
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
              style: TextStyleHelper.bodyMedium.copyWith(
                color: isDark ? AppColors.textWhite70 : AppColors.textMedium,
                fontStyle: FontStyle.italic,
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
        color: isDark ? AppColors.textWhite70 : AppColors.textMedium,
        height: 1.6,
      ),
    );
  }

  Widget _buildRecommendationsSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Artikel Rekomendasi',
          style: TextStyleHelper.headline4.copyWith(
            color: isDark ? AppColors.textWhite : AppColors.textDark,
          ),
        ),
        const SizedBox(height: 16),
        ..._recommendations.map((article) => _buildRecommendationCard(article)),
      ],
    );
  }

  Widget _buildRecommendationCard(EducationArticle article) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardBackgroundDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.dividerDark : AppColors.divider,
        ),
      ),
      child: ListTile(
        onTap: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => EducationDetailScreen(article: article),
            ),
          );
        },
        leading: CircleAvatar(
          backgroundColor: Color(int.parse(article.colorHex.replaceFirst('#', '0xFF'))).withValues(alpha: 0.1),
          child: Icon(
            Icons.article,
            color: Color(int.parse(article.colorHex.replaceFirst('#', '0xFF'))),
          ),
        ),
        title: Text(
          article.title,
          style: TextStyleHelper.titleSmall.copyWith(
            color: isDark ? AppColors.textWhite : AppColors.textDark,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          article.category,
          style: TextStyleHelper.caption.copyWith(
            color: AppColors.textLight,
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
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