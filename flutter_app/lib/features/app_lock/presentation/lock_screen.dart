import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aji_tfarraj/app/design_system/colors.dart';
import 'package:aji_tfarraj/app/design_system/spacing.dart';
import 'package:aji_tfarraj/app/design_system/typography.dart';
import 'package:aji_tfarraj/app/localization/locale_provider.dart';
import 'package:aji_tfarraj/features/app_lock/data/app_lock_controller.dart';

/// L'app verrouillée : le logo sur noir, et Face ID par-dessus.
///
/// C'est le dernier plan de la vidéo de lancement, à l'identique : au
/// démarrage, la vidéo s'arrête sur ce logo et cet écran le prolonge, si bien
/// qu'on ne voit qu'une animation, puis Face ID — pas un écran « verrouillé ».
/// Au retour d'arrière-plan, c'est le même logo.
///
/// Face ID est demandé tout seul. Un bouton n'apparaît que si la personne l'a
/// annulé ou s'il a échoué ; pendant que le système demande, rien ne bouge.
class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});

  /// Le dernier plan de `assets/splash/splash.mp4` (1080 × 1920).
  static const cover = AssetImage('assets/splash/splash_last.jpg');

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  bool _prompting = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _unlock());
  }

  Future<void> _unlock() async {
    if (_prompting) return;
    setState(() {
      _prompting = true;
      _failed = false;
    });
    final ok = await ref.read(appLockProvider.notifier).unlock();
    // Réussi : l'écran disparaît avec le verrou, rien à faire ici.
    if (mounted && !ok) {
      setState(() {
        _prompting = false;
        _failed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final bottom = MediaQuery.paddingOf(context).bottom;

    return PopScope(
      canPop: false,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        // Icônes blanches : on est sur le noir du lancement.
        value: SystemUiOverlayStyle.light,
        child: Semantics(
          label: s.biometricUnlockTitle,
          child: ColoredBox(
            color: AppColors.splashBackground,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Contenu, pas rogné : exactement comme la vidéo.
                const Image(
                  image: LockScreen.cover,
                  fit: BoxFit.contain,
                  gaplessPlayback: true,
                ),
                Positioned(
                  left: AppSpacing.xl,
                  right: AppSpacing.xl,
                  bottom: bottom + AppSpacing.xxxl,
                  child: Center(
                    child: AnimatedOpacity(
                      opacity: _failed ? 1 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: IgnorePointer(
                        ignoring: !_failed,
                        child: _UnlockButton(
                          label: s.biometricUnlockButton,
                          onPressed: _unlock,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Une pastille discrète, blanche sur le noir : on la remarque, elle ne
/// prend pas la place du logo.
class _UnlockButton extends StatelessWidget {
  const _UnlockButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.12),
      shape: StadiumBorder(
        side: BorderSide(color: Colors.white.withValues(alpha: 0.24)),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl, vertical: AppSpacing.md),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_open_rounded,
                  size: 20, color: Colors.white),
              const SizedBox(width: AppSpacing.sm),
              Text(
                label,
                style: AppTypography.labelLarge.copyWith(color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
