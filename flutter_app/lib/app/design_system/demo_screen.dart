import 'package:flutter/material.dart';
import 'package:aji_tfarraj/app/design_system/design_system.dart';

/// Demo screen to showcase all design system components
class DesignSystemDemoScreen extends StatefulWidget {
  const DesignSystemDemoScreen({super.key});

  @override
  State<DesignSystemDemoScreen> createState() => _DesignSystemDemoScreenState();
}

class _DesignSystemDemoScreenState extends State<DesignSystemDemoScreen> {
  final _textController = TextEditingController();
  final _passwordController = TextEditingController();
  final _searchController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    _passwordController.dispose();
    _searchController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Design System Demo'),
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ============================================
            // COLORS SECTION
            // ============================================
            _buildSectionTitle('Colors'),
            const SizedBox(height: AppSpacing.md),
            _buildColorRow('Primary', AppColors.primary),
            _buildColorRow('Secondary', AppColors.secondary),
            _buildColorRow('Success', AppColors.success),
            _buildColorRow('Warning', AppColors.warning),
            _buildColorRow('Error', AppColors.error),
            
            const SizedBox(height: AppSpacing.xl),

            // ============================================
            // TYPOGRAPHY SECTION
            // ============================================
            _buildSectionTitle('Typography'),
            const SizedBox(height: AppSpacing.md),
            Text('H1 - Page Title', style: AppTypography.h1),
            Text('H2 - Section Title', style: AppTypography.h2),
            Text('H3 - Card Title', style: AppTypography.h3),
            Text('H4 - Subtitle', style: AppTypography.h4),
            const SizedBox(height: AppSpacing.sm),
            Text('Body Large - Main content text', style: AppTypography.bodyLarge),
            Text('Body Medium - Default body text', style: AppTypography.bodyMedium),
            Text('Body Small - Captions and hints', style: AppTypography.bodySmall),
            const SizedBox(height: AppSpacing.sm),
            Text('Label Large', style: AppTypography.labelLarge),
            Text('Label Medium', style: AppTypography.labelMedium),
            Text('Label Small', style: AppTypography.labelSmall),

            const SizedBox(height: AppSpacing.xl),

            // ============================================
            // BUTTONS SECTION
            // ============================================
            _buildSectionTitle('Buttons'),
            const SizedBox(height: AppSpacing.md),
            
            AppButton(
              text: 'Primary Button',
              onPressed: () => _showSnackbar('Primary pressed!'),
            ),
            const SizedBox(height: AppSpacing.md),
            
            AppButtonSecondary(
              text: 'Secondary Button',
              onPressed: () => _showSnackbar('Secondary pressed!'),
            ),
            const SizedBox(height: AppSpacing.md),
            
            AppButtonSecondary(
              text: 'Outline Button',
              onPressed: () => _showSnackbar('Outline pressed!'),
            ),
            const SizedBox(height: AppSpacing.md),
            
            AppButton(
              text: 'Button with Icon',
              icon: Icons.arrow_forward,
              onPressed: () => _showSnackbar('Icon button pressed!'),
            ),
            const SizedBox(height: AppSpacing.md),
            
            AppButton(
              text: 'Loading Button',
              isLoading: true,
              onPressed: () {},
            ),
            const SizedBox(height: AppSpacing.md),
            
            AppButton(
              text: 'Disabled Button',
              onPressed: null,
            ),

            const SizedBox(height: AppSpacing.xl),

            // ============================================
            // INPUTS SECTION
            // ============================================
            _buildSectionTitle('Input Fields'),
            const SizedBox(height: AppSpacing.md),
            
            AppInput(
              controller: _textController,
              label: 'Full Name',
              hint: 'Enter your name',
              prefixIcon: const Icon(Icons.person_outline),
            ),
            const SizedBox(height: AppSpacing.lg),
            
            AppInput(
              controller: _passwordController,
              label: 'Password',
              hint: 'Enter your password',
              obscureText: true,
              prefixIcon: const Icon(Icons.lock_outline),
            ),
            const SizedBox(height: AppSpacing.lg),
            
            AppSearchInput(
              controller: _searchController,
              hint: 'Search shows...',
              onChanged: (value) {},
            ),
            const SizedBox(height: AppSpacing.lg),
            
            AppInput(
              controller: _phoneController,
              label: 'Phone Number',
              hint: '6 12 34 56 78',
              keyboardType: TextInputType.phone,
              prefixIcon: const Icon(Icons.phone_outlined),
            ),
            const SizedBox(height: AppSpacing.lg),
            
            AppInput(
              controller: TextEditingController(),
              label: 'Error State',
              hint: 'Field with error',
              errorText: 'This field is required',
            ),

            const SizedBox(height: AppSpacing.xl),

            // ============================================
            // BADGES SECTION
            // ============================================
            _buildSectionTitle('Status Badges'),
            const SizedBox(height: AppSpacing.md),
            
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                AppBadge.status(StatusType.approved),
                AppBadge.status(StatusType.pendingReview),
                AppBadge.status(StatusType.rejected),
                AppBadge.status(StatusType.checkedIn),
                AppBadge.status(StatusType.expired),
                AppBadge.status(StatusType.cancelled),
              ],
            ),

            const SizedBox(height: AppSpacing.xl),

            // ============================================
            // CARDS SECTION
            // ============================================
            _buildSectionTitle('Cards'),
            const SizedBox(height: AppSpacing.md),
            
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Basic Card', style: AppTypography.h4),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'This is a basic card with some content inside.',
                    style: AppTypography.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            
            AppCard(
              onTap: () => _showSnackbar('Card tapped!'),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.backgroundGrey,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    child: const Icon(Icons.tv, color: AppColors.primary),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Tappable Card', style: AppTypography.h4),
                        Text('Tap me!', style: AppTypography.bodySmall),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: AppColors.textMuted),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // ============================================
            // STATES SECTION
            // ============================================
            _buildSectionTitle('State Widgets'),
            const SizedBox(height: AppSpacing.md),
            
            const LoadingState(),
            const SizedBox(height: AppSpacing.lg),
            
            SizedBox(
              height: 280,
              child: EmptyState(
                icon: Icons.search_off,
                title: 'No results found',
                description: 'Try adjusting your search criteria',
                actionText: 'Clear filters',
                onAction: () => _showSnackbar('Filters cleared!'),
              ),
            ),

            const SizedBox(height: AppSpacing.xxxl),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Text(
        title.toUpperCase(),
        style: AppTypography.labelLarge.copyWith(
          color: AppColors.primary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildColorRow(String name, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              border: Border.all(color: AppColors.border),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(name, style: AppTypography.bodyMedium),
          const Spacer(),
          Text(
            '#${color.value.toRadixString(16).substring(2).toUpperCase()}',
            style: AppTypography.caption,
          ),
        ],
      ),
    );
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
