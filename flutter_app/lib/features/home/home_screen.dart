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
import 'package:aji_tfarraj/app/design_system/loaders.dart';
import 'package:aji_tfarraj/app/design_system/components/cards/app_card.dart';
import 'package:aji_tfarraj/features/shows/data/shows_repository.dart';
import 'package:aji_tfarraj/features/shows/domain/show.dart';
import 'package:aji_tfarraj/features/notifications/presentation/providers/notifications_provider.dart';

/// Home Screen - List of available TV shows with filters and pagination
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    // Sync search controller with current filter state
    final currentSearch = ref.read(showsFilterProvider).searchQuery;
    if (currentSearch != null) {
      _searchController.text = currentSearch;
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(showsListProvider.notifier).loadMore();
    }
  }

  void _onSearchChanged(String value) {
    // Use debounced search to avoid API spam
    ref.read(showsFilterProvider.notifier).setSearchDebounced(value);
  }

  void _onSearchSubmitted(String value) {
    // Immediate search on submit
    ref.read(showsFilterProvider.notifier).setSearchImmediate(value);
    _searchFocusNode.unfocus();
  }

  void _clearSearch() {
    _searchController.clear();
    ref.read(showsFilterProvider.notifier).clearSearch();
    _searchFocusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final showsState = ref.watch(showsListProvider);
    final filteredShows = ref.watch(filteredShowsProvider);
    final filterState = ref.watch(showsFilterProvider);
    final unreadCount = ref.watch(unreadNotificationsCountProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text('Émissions', style: AppTypography.h3),
        backgroundColor: AppColors.backgroundWhite,
        elevation: 0,
        actions: [
          // Notification bell icon with badge
          _NotificationBellButton(unreadCount: unreadCount),
          if (filterState.hasFilters)
            TextButton(
              onPressed: () {
                _searchController.clear();
                ref.read(showsFilterProvider.notifier).clearAll();
              },
              child: Text(
                'Effacer',
                style: AppTypography.labelMedium.copyWith(color: AppColors.primary),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Search input
          _SearchInput(
            controller: _searchController,
            focusNode: _searchFocusNode,
            onChanged: _onSearchChanged,
            onSubmitted: _onSearchSubmitted,
            onClear: _clearSearch,
          ),

          // Filter chips section
          if (!showsState.isLoading && showsState.items.isNotEmpty)
            _FiltersSection(
              cities: showsState.uniqueCities,
              channels: showsState.uniqueChannels,
              selectedCity: filterState.selectedCity,
              selectedChannel: filterState.selectedChannel,
              onCityChanged: (city) => ref.read(showsFilterProvider.notifier).setCity(city),
              onChannelChanged: (channel) => ref.read(showsFilterProvider.notifier).setChannel(channel),
            ),

          // Content
          Expanded(
            child: _buildContent(showsState, filteredShows),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(ShowsListState showsState, List<Show> filteredShows) {
    // Loading state
    if (showsState.isLoading) {
      return const ShowsListSkeleton(itemCount: 6);
    }

    // Error state
    if (showsState.error != null) {
      return ErrorState(
        message: showsState.error!,
        retryText: 'Réessayer',
        onRetry: () => ref.read(showsListProvider.notifier).refresh(),
      );
    }

    // Empty state (no shows at all)
    if (showsState.items.isEmpty && !showsState.hasFilters) {
      return EmptyState.noShows(
        onAction: () => ref.read(showsListProvider.notifier).refresh(),
      );
    }

    // Filtered empty state (filters applied but no results)
    if (filteredShows.isEmpty) {
      return EmptyState(
        icon: Icons.search_off,
        title: 'Aucun résultat',
        description: 'Aucune émission ne correspond à votre recherche.',
        actionText: 'Effacer les filtres',
        onAction: () {
          _searchController.clear();
          ref.read(showsFilterProvider.notifier).clearAll();
        },
      );
    }

    // Shows list
    return RefreshIndicator(
      onRefresh: () => ref.read(showsListProvider.notifier).refresh(),
      color: AppColors.primary,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: filteredShows.length + (showsState.isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == filteredShows.length) {
            return const _LoadingMoreIndicator();
          }
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
            child: _ShowListItem(show: filteredShows[index]),
          );
        },
      ),
    );
  }
}

/// Search input widget with icon and clear button
class _SearchInput extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClear;

  const _SearchInput({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onSubmitted,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.backgroundWhite,
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
        onSubmitted: onSubmitted,
        textInputAction: TextInputAction.search,
        style: AppTypography.bodyMedium,
        decoration: InputDecoration(
          hintText: 'Rechercher une émission...',
          hintStyle: AppTypography.bodyMedium.copyWith(
            color: AppColors.textMuted,
          ),
          prefixIcon: const Icon(
            Icons.search,
            color: AppColors.textMuted,
            size: 22,
          ),
          suffixIcon: ListenableBuilder(
            listenable: controller,
            builder: (context, _) {
              if (controller.text.isEmpty) {
                return const SizedBox.shrink();
              }
              return IconButton(
                icon: const Icon(
                  Icons.close,
                  color: AppColors.textMuted,
                  size: 20,
                ),
                onPressed: onClear,
                tooltip: 'Effacer la recherche',
              );
            },
          ),
          filled: true,
          fillColor: AppColors.backgroundLight,
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
            borderSide: const BorderSide(
              color: AppColors.primary,
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}

/// Filters section with city and channel chips
class _FiltersSection extends StatelessWidget {
  final List<String> cities;
  final List<String> channels;
  final String? selectedCity;
  final String? selectedChannel;
  final ValueChanged<String?> onCityChanged;
  final ValueChanged<String?> onChannelChanged;

  const _FiltersSection({
    required this.cities,
    required this.channels,
    this.selectedCity,
    this.selectedChannel,
    required this.onCityChanged,
    required this.onChannelChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.backgroundWhite,
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (cities.isNotEmpty) ...[
            FilterChipGroup(
              title: 'Ville',
              options: cities,
              selectedValue: selectedCity,
              onSelected: onCityChanged,
              allLabel: 'Toutes',
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          if (channels.isNotEmpty)
            FilterChipGroup(
              title: 'Chaîne',
              options: channels,
              selectedValue: selectedChannel,
              onSelected: onChannelChanged,
              allLabel: 'Toutes',
            ),
          // TODO: Add category filter when Show model has category field
        ],
      ),
    );
  }
}

/// Show list item with horizontal layout using design system
class _ShowListItem extends StatelessWidget {
  final Show show;

  const _ShowListItem({required this.show});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy • HH:mm', 'fr_FR');

    return AppCard(
      padding: EdgeInsets.zero,
      onTap: () => context.go(Routes.showDetail(show.id.toString())),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: Image (cached, rounded corners)
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(AppSpacing.cardRadius),
              bottomLeft: Radius.circular(AppSpacing.cardRadius),
            ),
            child: SizedBox(
              width: 120,
              height: 120,
              child: show.imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: show.imageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: AppColors.backgroundGrey,
                        child: const Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.secondary,
                            ),
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: AppColors.backgroundGrey,
                        child: const Icon(
                          Icons.tv,
                          size: 40,
                          color: AppColors.textMuted,
                        ),
                      ),
                    )
                  : Container(
                      color: AppColors.backgroundGrey,
                      child: const Icon(
                        Icons.tv,
                        size: 40,
                        color: AppColors.textMuted,
                      ),
                    ),
            ),
          ),

          // Right: Show info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title (bold)
                  Text(
                    show.title,
                    style: AppTypography.h4,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xs),

                  // City + Channel
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        show.city,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                      if (show.channel != null) ...[
                        const SizedBox(width: AppSpacing.md),
                        Icon(
                          Icons.tv_outlined,
                          size: 14,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Flexible(
                          child: Text(
                            show.channel!,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textMuted,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),

                  // Date formatted
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 14,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        dateFormat.format(show.startsAt.toLocal()),
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // Availability badge
                  if (show.isSoldOut)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.errorLight,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                      child: Text(
                        'COMPLET',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  else
                    Text(
                      '${show.availableSeats} places disponibles',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.success,
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Chevron indicator
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: Icon(
              Icons.chevron_right,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

/// Notification bell button with unread badge
class _NotificationBellButton extends StatelessWidget {
  final int unreadCount;

  const _NotificationBellButton({required this.unreadCount});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(Icons.notifications_outlined),
          if (unreadCount > 0)
            Positioned(
              right: -4,
              top: -4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(
                  minWidth: 18,
                  minHeight: 18,
                ),
                child: Text(
                  unreadCount > 99 ? '99+' : unreadCount.toString(),
                  style: const TextStyle(
                    color: AppColors.backgroundWhite,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
      tooltip: 'Notifications',
      onPressed: () => context.push(Routes.notifications),
    );
  }
}

/// Loading more indicator at bottom of list
class _LoadingMoreIndicator extends StatelessWidget {
  const _LoadingMoreIndicator();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Text(
              'Chargement...',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
