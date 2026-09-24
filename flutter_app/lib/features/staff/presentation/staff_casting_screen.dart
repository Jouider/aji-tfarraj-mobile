import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aji_tfarraj/app/design_system/colors.dart';
import 'package:aji_tfarraj/app/design_system/spacing.dart';
import 'package:aji_tfarraj/app/design_system/states.dart';
import 'package:aji_tfarraj/app/design_system/typography.dart';
import 'package:aji_tfarraj/app/localization/locale_provider.dart';
import 'package:aji_tfarraj/features/staff/data/staff_casting_repository.dart';
import 'package:aji_tfarraj/features/staff/presentation/staff_casting_book_screen.dart';

/// Choisir le membre que l'équipe va photographier.
///
/// Les téléphones des membres prennent souvent de mauvaises photos, et il y en
/// a toujours un qui s'éteint au moment de poser. Ici, le staff cherche la
/// personne qui est devant lui au studio et ouvre son book.
class StaffCastingScreen extends ConsumerStatefulWidget {
  const StaffCastingScreen({super.key});

  @override
  ConsumerState<StaffCastingScreen> createState() => _StaffCastingScreenState();
}

class _StaffCastingScreenState extends ConsumerState<StaffCastingScreen> {
  final _search = TextEditingController();

  /// Ce qui est réellement envoyé au serveur : la frappe est laissée
  /// retomber, sinon chaque lettre ferait une requête.
  String _query = '';
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _onTyped(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) setState(() => _query = value.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final members = ref.watch(castingMembersProvider(_query));

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(title: Text(s.staffCastingTitle)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: TextField(
              controller: _search,
              onChanged: _onTyped,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: s.staffCastingSearchHint,
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: AppColors.backgroundWhite,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
              ),
            ),
          ),
          Expanded(
            child: members.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => ErrorState(
                message: s.staffCastingLoadError,
                onRetry: () => ref.invalidate(castingMembersProvider(_query)),
              ),
              data: (list) => list.isEmpty
                  ? EmptyState(
                      icon: Icons.person_search_outlined,
                      title: s.staffCastingNobody,
                      description: s.staffCastingNobodyHint,
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0,
                          AppSpacing.lg, AppSpacing.xxl),
                      itemCount: list.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, index) => _MemberTile(
                        member: list[index],
                        s: s,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                StaffCastingBookScreen(member: list[index]),
                          ),
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  const _MemberTile({
    required this.member,
    required this.s,
    required this.onTap,
  });

  final CastingMember member;
  final dynamic s;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.backgroundWhite,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.backgroundGrey,
                backgroundImage: member.avatarUrl != null
                    ? CachedNetworkImageProvider(member.avatarUrl!)
                    : null,
                child: member.avatarUrl == null
                    ? Icon(Icons.person_outline, color: AppColors.textMuted)
                    : null,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(member.name, style: AppTypography.bodyMedium),
                    if (member.phone != null)
                      // En chiffres latins et de gauche à droite, même en
                      // arabe : un numéro lu à l'envers ne sert à personne.
                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: Text(
                          member.phone!,
                          style: AppTypography.caption
                              .copyWith(color: AppColors.textMuted),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _BookBadge(member: member, s: s),
            ],
          ),
        ),
      ),
    );
  }
}

/// Où en est le book : complet, ou combien de clichés sur combien.
class _BookBadge extends StatelessWidget {
  const _BookBadge({required this.member, required this.s});

  final CastingMember member;
  final dynamic s;

  @override
  Widget build(BuildContext context) {
    final complete = member.isComplete;

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: complete
            ? AppColors.success.withValues(alpha: 0.12)
            : AppColors.secondary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Text(
        complete
            ? s.staffCastingBookComplete
            : '${member.photosTaken}/${member.posesTotal}',
        style: AppTypography.labelSmall.copyWith(
          color: complete ? AppColors.success : AppColors.secondaryDark,
        ),
      ),
    );
  }
}
