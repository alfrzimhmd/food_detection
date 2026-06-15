// lib/screens/education_screen.dart
// SPDX-License-Identifier: Apache-2.0

import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../utils/text_style_helper.dart';
import '../../models/education_model.dart';
import '../../services/education_service.dart';
import 'education_detail_screen.dart';

class EducationScreen extends StatefulWidget {
  const EducationScreen({super.key});

  @override
  State<EducationScreen> createState() => _EducationScreenState();
}

class _EducationScreenState extends State<EducationScreen> {
  late EducationService _educationService;
  List<EducationArticle> _articles = [];
  List<Map<String, dynamic>> _categories = [];
  String _selectedCategory = 'Semua';
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _educationService = EducationService();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    await _educationService.loadEducationData();
    
    setState(() {
      _articles = _educationService.getAllArticles();
      _categories = _educationService.getCategories();
      _isLoading = false;
    });
  }

  List<EducationArticle> get _filteredArticles {
    List<EducationArticle> result = _selectedCategory == 'Semua'
        ? _articles
        : _educationService.getArticlesByCategory(_selectedCategory);
    
    if (_searchQuery.isNotEmpty) {
      result = result.where((article) =>
        article.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        article.summary.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }
    
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.backgroundColor(context),
      body: Column(
        children: [
          _buildAppBar(_articles.length, _isLoading),
          _buildSearchBar(isDark),
          _buildCategoryFilter(isDark),
          Expanded(
            child: _isLoading
                ? _buildLoadingState()
                : _filteredArticles.isEmpty
                    ? _buildEmptyState()
                    : _buildArticleList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(int totalCount, bool isLoading) {
    return Container(
      color: AppColors.primaryDark,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 12, 14),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.school_rounded, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Edukasi Gizi',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    if (!isLoading)
                      Text(
                        '$totalCount artikel tersedia',
                        style: const TextStyle(color: Colors.white60, fontSize: 12),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardBackgroundDark : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          onChanged: (value) {
            setState(() => _searchQuery = value);
          },
          decoration: InputDecoration(
            hintText: 'Cari artikel edukasi...',
            hintStyle: TextStyleHelper.bodyMedium.copyWith(
              color: isDark ? AppColors.textWhite70 : AppColors.textLight,
            ),
            prefixIcon: Icon(
              Icons.search,
              color: isDark ? AppColors.textWhite70 : AppColors.textLight,
            ),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      Icons.clear,
                      color: isDark ? AppColors.textWhite70 : AppColors.textLight,
                    ),
                    onPressed: () {
                      setState(() => _searchQuery = '');
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
          style: TextStyleHelper.bodyMedium.copyWith(
            color: isDark ? AppColors.textWhite : AppColors.textDark,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryFilter(bool isDark) {
    final categories = [
      {'name': 'Semua', 'count': _articles.length},
      ..._categories,
    ];

    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = _selectedCategory == category['name'];
          
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: FilterChip(
              label: Text(
                '${category['name']} (${category['count']})',
                style: TextStyleHelper.labelMedium.copyWith(
                  color: isSelected ? Colors.white : (isDark ? AppColors.textWhite70 : AppColors.textMedium),
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedCategory = category['name'] as String;
                });
              },
              backgroundColor: isDark ? AppColors.cardBackgroundDark : Colors.white,
              selectedColor: AppColors.primary,
              checkmarkColor: Colors.white,
              shape: StadiumBorder(
                side: BorderSide(
                  color: isSelected ? Colors.transparent : (isDark ? AppColors.dividerDark : AppColors.divider),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.primary),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.school_outlined,
            size: 64,
            color: AppColors.textLight,
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty
                ? 'Tidak ditemukan artikel untuk "$_searchQuery"'
                : 'Belum ada artikel edukasi',
            style: TextStyleHelper.bodyLarge.copyWith(
              color: AppColors.textLight,
            ),
          ),
          if (_searchQuery.isNotEmpty) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                setState(() {
                  _searchQuery = '';
                });
              },
              child: Text(
                'Hapus pencarian',
                style: TextStyleHelper.labelLarge.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildArticleList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredArticles.length,
      itemBuilder: (context, index) {
        final article = _filteredArticles[index];
        return _buildArticleCard(article);
      },
    );
  }

  Widget _buildArticleCard(EducationArticle article) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasImage = article.imageAsset != null && article.imageAsset!.isNotEmpty;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardBackgroundDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EducationDetailScreen(article: article),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hasImage)
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  child: Image.asset(
                    article.imageAsset!,
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Color(int.parse(article.colorHex.replaceFirst('#', '0xFF'))),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            article.category,
                            style: TextStyleHelper.labelSmall.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 14,
                              color: AppColors.textLight,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${article.readTime} menit',
                              style: TextStyleHelper.caption.copyWith(
                                color: AppColors.textLight,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      article.title,
                      style: TextStyleHelper.titleLarge.copyWith(
                        color: isDark ? AppColors.textWhite : AppColors.textDark,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      article.summary,
                      style: TextStyleHelper.bodyMedium.copyWith(
                        color: isDark ? AppColors.textWhite70 : AppColors.textMedium,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text(
                          'Baca selengkapnya',
                          style: TextStyleHelper.labelMedium.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward,
                          size: 16,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}