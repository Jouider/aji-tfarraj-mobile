import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:aji_tfarraj/app/routes.dart';
import 'package:aji_tfarraj/app/design_system/colors.dart';
import 'package:aji_tfarraj/app/design_system/spacing.dart';
import 'package:aji_tfarraj/app/design_system/typography.dart';
import 'package:aji_tfarraj/app/design_system/states.dart';
import 'package:aji_tfarraj/app/localization/locale_provider.dart';
import 'package:aji_tfarraj/app/localization/strings.dart';
import 'package:aji_tfarraj/features/shows/data/shows_repository.dart';
import 'package:aji_tfarraj/features/shows/domain/show.dart';

/// Browse screen — Pathé-style cinema browser, shows organized by city/studio
class ShowsBrowseScreen extends ConsumerStatefulWidget {
  const ShowsBrowseScreen({super.key});

  @override
  ConsumerState<ShowsBrowseScreen> createState() => _ShowsBrowseScreenState();
}

class _ShowsBrowseScreenState extends ConsumerState<ShowsBrowseScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String? _selectedCity;
  String? _selectedChannel;

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    ref.read(showsFilterProvider.notifier).setSearchDebounced(value);
  }

  void _clearSearch() {
    _searchController.clear();
    ref.read(showsFilterProvider.notifier).clearSearch();
    _searchFocusNode.unfocus();
  }

  void _selectCity(String? city) {
    setState(() => _selectedCity = city);
    ref.read(showsFilterProvider.notifier).setCity(city);
  }

  void _openFilterSheet() {
    final s = ref.read(stringsProvider);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceOverlay,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _FilterSheet(
        s: s,
        selectedChannel: _selectedChannel,
        channels: ref.read(showsListProvider).uniqueChannels,
        onChannelSelected: (ch) {
          setState(() => _selectedChannel = ch);
          ref.read(showsFilterProvider.notifier).setChannel(ch);
          Navigator.pop(context);
        },
        onClear: () {
          setState(() {
            _selectedChannel = null;
            _selectedCity = null;
          });
          _searchController.clear();
          ref.read(showsFilterProvider.notifier).clearAll();
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final showsState = ref.watch(showsListProvider);
    final filteredShows = ref.watch(filteredShowsProvider);
    final s = ref.watch(stringsProvider);
    final isAr = ref.watch(isRtlProvider);

    // Build city list from all loaded shows
    final cities = showsState.uniqueCities;

    // Group filtered shows by studio (fallback to city)
    final grouped = _groupByStudio(filteredShows);

    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundLight,
        title: Text(s.browseTitle, style: AppTypography.h3),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
        actions: [
          // Filter icon with active indicator
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.tune_rounded),
                tooltip: s.browseFilterTooltip,
                onPressed: _openFilterSheet,
              ),
              if (_selectedChannel != null)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.secondary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          _SearchBar(
            s: s,
            controller: _searchController,
            focusNode: _searchFocusNode,
            onChanged: _onSearchChanged,
            onClear: _clearSearch,
          ),

          // City filter chips
          if (cities.isNotEmpty)
            _CityChipsRow(
              s: s,
              cities: cities,
              selectedCity: _selectedCity,
              onCitySelected: _selectCity,
            ),

          const Divider(height: 1),

          // Content
          Expanded(
            child: _buildContent(showsState, grouped, s, isAr),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    ShowsListState showsState,
    Map<String, List<Show>> grouped,
    AppStrings s,
    bool isAr,
  ) {
    if (showsState.isLoading) {
      return const _BrowseLoadingSkeleton();
    }

    if (showsState.error != null) {
      return ErrorState(
        message: showsState.error!,
        retryText: s.retry,
        onRetry: () => ref.read(showsListProvider.notifier).refresh(),
      );
    }

    if (grouped.isEmpty) {
      return EmptyState(
        icon: Icons.search_off_rounded,
        title: s.browseNoResults,
        description: s.browseNoResultsDesc,
        actionText: s.browseClearFilters,
        onAction: () {
          setState(() {
            _selectedCity = null;
            _selectedChannel = null;
          });
          _searchController.clear();
          ref.read(showsFilterProvider.notifier).clearAll();
        },
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(showsListProvider.notifier).refresh(),
      color: AppColors.secondary,
      backgroundColor: AppColors.backgroundGrey,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
        itemCount: grouped.length,
        itemBuilder: (context, index) {
          final studioName = grouped.keys.elementAt(index);
          final studioShows = grouped[studioName]!;
          return _StudioSection(
            s: s,
            studioName: studioName,
            shows: studioShows,
            isAr: isAr,
          );
        },
      ),
    );
  }

  Map<String, List<Show>> _groupByStudio(List<Show> shows) {
    final map = <String, List<Show>>{};
    for (final show in shows) {
      final key = (show.studio != null && show.studio!.isNotEmpty)
          ? show.studio!
          : show.city;
      map.putIfAbsent(key, () => []).add(show);
    }
    return map;
  }
}

// ─────────────────────────────────────────────────────
// Search Bar
// ─────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final AppStrings s;
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchBar({
    required this.s,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.backgroundLight,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: s.browseSearchHint,
          hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textLight),
          prefixIcon: Icon(Icons.search, color: AppColors.textLight, size: 22),
          suffixIcon: ListenableBuilder(
            listenable: controller,
            builder: (_, __) => controller.text.isEmpty
                ? const SizedBox.shrink()
                : IconButton(
                    icon: Icon(Icons.close, color: AppColors.textLight, size: 20),
                    onPressed: onClear,
                  ),
          ),
          filled: true,
          fillColor: AppColors.backgroundGrey,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            borderSide: const BorderSide(color: AppColors.secondary, width: 1.5),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
// City Filter Chips Row
// ─────────────────────────────────────────────────────

class _CityChipsRow extends StatelessWidget {
  final AppStrings s;
  final List<String> cities;
  final String? selectedCity;
  final ValueChanged<String?> onCitySelected;

  const _CityChipsRow({
    required this.s,
    required this.cities,
    required this.selectedCity,
    required this.onCitySelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.backgroundLight,
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        children: [
          // "Toutes" chip
          _CityChip(
            label: s.browseAllCities,
            isSelected: selectedCity == null,
            onTap: () => onCitySelected(null),
          ),
          const SizedBox(width: AppSpacing.sm),
          ...cities.map((city) => Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: _CityChip(
                  label: city,
                  isSelected: selectedCity == city,
                  onTap: () => onCitySelected(city),
                ),
              )),
        ],
      ),
    );
  }
}

class _CityChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CityChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.secondary : AppColors.backgroundGrey,
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          border: Border.all(
            color: isSelected ? AppColors.secondary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: isSelected ? Colors.black : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
// Studio Group Section
// ─────────────────────────────────────────────────────

class _StudioSection extends StatelessWidget {
  final AppStrings s;
  final String studioName;
  final List<Show> shows;
  final bool isAr;

  const _StudioSection({required this.s, required this.studioName, required this.shows, required this.isAr});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Studio header
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.xl,
            AppSpacing.lg,
            AppSpacing.md,
          ),
          child: Row(
            children: [
              Container(
                width: 3,
                height: 18,
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                studioName,
                style: AppTypography.h4.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '(${shows.length})',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textLight,
                ),
              ),
            ],
          ),
        ),

        // Show cards
        ...shows.map((show) => _BrowseShowCard(s: s, show: show, isAr: isAr)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────
// Browse Show Card (full-width row)
// ─────────────────────────────────────────────────────

class _BrowseShowCard extends StatelessWidget {
  final AppStrings s;
  final Show show;
  final bool isAr;

  const _BrowseShowCard({required this.s, required this.show, required this.isAr});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEE d MMM • HH:mm', 'fr_FR');

    return GestureDetector(
      onTap: () => context.push(Routes.showDetail(show.id.toString())),
      child: Container(
        margin: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: AppColors.backgroundGrey,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppSpacing.radiusLg),
                bottomLeft: Radius.circular(AppSpacing.radiusLg),
              ),
              child: SizedBox(
                width: 90,
                height: 90,
                child: show.imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: show.imageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) =>
                            Container(color: AppColors.backgroundWhite),
                        errorWidget: (_, __, ___) => Container(
                          color: AppColors.backgroundWhite,
                          child: Icon(Icons.tv,
                              size: 28, color: AppColors.textLight),
                        ),
                      )
                    : Container(
                        color: AppColors.backgroundWhite,
                        child: Icon(Icons.tv,
                            size: 28, color: AppColors.textLight),
                      ),
              ),
            ),

            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title + channel badge row
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            show.localizedTitle(isAr),
                            style: AppTypography.labelLarge.copyWith(
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (show.channel != null) ...[
                          const SizedBox(width: AppSpacing.sm),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.15),
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.radiusSm),
                              border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              show.channel!,
                              style: AppTypography.caption.copyWith(
                                color: AppColors.primaryLight,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 4),

                    // Date
                    Row(
                      children: [
                        Icon(Icons.calendar_today_outlined,
                            size: 12, color: AppColors.textLight),
                        const SizedBox(width: 4),
                        Text(
                          show.startsAt != null
                              ? dateFormat.format(show.startsAt!.toLocal())
                              : '—',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    // City + seats
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined,
                            size: 12, color: AppColors.textLight),
                        const SizedBox(width: 4),
                        Text(
                          show.city,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                        const Spacer(),
                        if (show.isSoldOut)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.errorLight,
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.radiusSm),
                            ),
                            child: Text(
                              s.browseSoldOutBadge,
                              style: AppTypography.caption.copyWith(
                                color: AppColors.error,
                                fontWeight: FontWeight.w700,
                                fontSize: 9,
                                letterSpacing: 0.5,
                              ),
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.successLight,
                              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                              border: Border.all(
                                color: AppColors.success.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.event_seat_outlined,
                                  size: 11,
                                  color: AppColors.success,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  s.browseAvailableSeats(show.availableSeats),
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.success,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Chevron
            Padding(
              padding: EdgeInsets.only(right: AppSpacing.sm),
              child: Icon(Icons.chevron_right, color: AppColors.textLight, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
// Filter Bottom Sheet
// ─────────────────────────────────────────────────────

class _FilterSheet extends StatelessWidget {
  final AppStrings s;
  final String? selectedChannel;
  final List<String> channels;
  final ValueChanged<String?> onChannelSelected;
  final VoidCallback onClear;

  const _FilterSheet({
    required this.s,
    required this.selectedChannel,
    required this.channels,
    required this.onChannelSelected,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            Text(
              s.browseFilterByChannel,
              style: AppTypography.h4.copyWith(color: AppColors.textPrimary),
            ),

            const SizedBox(height: AppSpacing.lg),

            if (channels.isEmpty)
              Text(
                s.browseNoChannels,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textMuted,
                ),
              )
            else
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: channels.map((ch) {
                  final isSelected = selectedChannel == ch;
                  return GestureDetector(
                    onTap: () => onChannelSelected(isSelected ? null : ch),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.secondary
                            : AppColors.backgroundGrey,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusFull),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.secondary
                              : AppColors.border,
                        ),
                      ),
                      child: Text(
                        ch,
                        style: AppTypography.labelSmall.copyWith(
                          color: isSelected ? Colors.black : AppColors.textSecondary,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

            const SizedBox(height: AppSpacing.xl),

            // Clear button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onClear,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  side: BorderSide(color: AppColors.border),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                ),
                child: Text(
                  s.browseClearAllFilters,
                  style: AppTypography.buttonMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
// Loading Skeleton
// ─────────────────────────────────────────────────────

class _BrowseLoadingSkeleton extends StatelessWidget {
  const _BrowseLoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: 3,
      itemBuilder: (_, sectionIndex) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.lg),
          // Studio label skeleton
          Container(
            height: 18,
            width: 140,
            decoration: BoxDecoration(
              color: AppColors.backgroundGrey,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // Card skeletons
          ...List.generate(
            2,
            (_) => Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              height: 90,
              decoration: BoxDecoration(
                color: AppColors.backgroundGrey,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
