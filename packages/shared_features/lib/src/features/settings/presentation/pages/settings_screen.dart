import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:get_it/get_it.dart';
import 'package:shared/shared.dart';
import 'package:shared/presentation/dialogs/dialog_helper.dart';
import 'package:shared_features/shared_features.dart';
import 'package:shared_features/src/features/settings/presentation/settings_presentation.dart';

class SettingsScreen extends StatelessWidget {
  final VoidCallback? onBackTap;

  const SettingsScreen({super.key, this.onBackTap});

  @override
  Widget build(BuildContext context) {
    final themeColor = context.themeColor;
    return Scaffold(
      backgroundColor: themeColor.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _buildHeader(context)),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildSectionHeader(
                  context,
                  context.l10n.settings_section_preferences,
                  Icons.tune_rounded,
                ),
                _buildPreferencesCard(context),

                const SizedBox(height: 32),
                _buildSectionHeader(
                  context,
                  context.l10n.settings_section_account,
                  Icons.person_outline_rounded,
                ),
                _buildAccountCard(context),

                const SizedBox(height: 40),
                _buildSignOutSection(context),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final themeColor = context.themeColor;
    return ClipPath(
      clipper: HeaderClipper(),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(color: themeColor.primary),
        child: Stack(
          children: [
            Positioned(
              top: -50,
              left: -50,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha:0.03),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 70, 24, 90),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () => context.go(GetIt.I<NavigationConfig>().initialPath),
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha:0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.settings_outlined,
                          color: Colors.white.withValues(alpha:0.8),
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    context.l10n.settings_title,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      fontFamily: 'Cairo',
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.l10n.settings_header_subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha:0.7),
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    IconData icon,
  ) {
    final themeColor = context.themeColor;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, right: 4),
      child: Row(
        children: [
          Icon(icon, color: themeColor.unselectedItem, size: 20),
          const SizedBox(width: 10),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: themeColor.textPrimary,
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesCard(BuildContext context) {
    final themeColor = context.themeColor;
    return Container(
      decoration: BoxDecoration(
        color: themeColor.cardBackground,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [themeColor.cardShadow],
      ),
      child: Column(
        children: [
          // Theme Switcher
          BlocBuilder<ThemeCubit, ThemeState>(
            builder: (context, state) {
              final isDark = state is ThemeLoaded ? state.isDark : false;
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFB300).withValues(alpha:0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                    color: const Color(0xFFFFB300),
                    size: 22,
                  ),
                ),
                title: Text(
                  context.l10n.settings_theme,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo',
                    fontSize: 15,
                    color: themeColor.textPrimary,
                  ),
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: themeColor.nestedCardBackground,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: themeColor.unselectedItem.withValues(alpha:0.2),
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<bool>(
                      value: isDark,
                      icon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 18,
                      ),
                      elevation: 16,
                      dropdownColor: themeColor.cardBackground,
                      style: TextStyle(
                        color: themeColor.textPrimary,
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      onChanged: (bool? newValue) {
                        if (newValue != null) {
                          context.read<ThemeCubit>().setTheme(newValue);
                        }
                      },
                      items: [
                        DropdownMenuItem(
                          value: false,
                          child: Text(context.l10n.settings_theme_light),
                        ),
                        DropdownMenuItem(
                          value: true,
                          child: Text(context.l10n.settings_theme_dark),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          Divider(
            height: 1,
            indent: 70,
            endIndent: 20,
            color: themeColor.unselectedItem.withValues(alpha:0.1),
          ),
          // Language Switcher
          BlocBuilder<LocaleCubit, LocaleState>(
            builder: (context, state) {
              final currentLocale = state is LocaleLoaded
                  ? state.locale
                  : const Locale('ar');
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: themeColor.secondary.withValues(alpha:0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.language_rounded,
                    color: themeColor.secondary,
                    size: 22,
                  ),
                ),
                title: Text(
                  context.l10n.settings_language,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo',
                    fontSize: 15,
                    color: themeColor.textPrimary,
                  ),
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: themeColor.nestedCardBackground,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: themeColor.unselectedItem.withValues(alpha:0.2),
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: currentLocale.languageCode,
                      icon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 18,
                      ),
                      elevation: 16,
                      dropdownColor: themeColor.cardBackground,
                      style: TextStyle(
                        color: themeColor.textPrimary,
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          context.read<LocaleCubit>().changeLocale(newValue);
                        }
                      },
                      items: [
                        DropdownMenuItem(
                          value: 'ar',
                          child: Text(context.l10n.settings_language_arabic),
                        ),
                        DropdownMenuItem(
                          value: 'en',
                          child: Text(context.l10n.settings_language_english),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }


  Widget _buildAccountCard(BuildContext context) {
    final themeColor = context.themeColor;
    return Container(
      decoration: BoxDecoration(
        color: themeColor.cardBackground,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [themeColor.cardShadow],
      ),
      child: Column(
        children: [
          ListTile(
            onTap: () => context.pushNamed(AppRoutes.notifications),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 12,
            ),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: themeColor.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.notifications_outlined,
                color: themeColor.primary,
                size: 22,
              ),
            ),
            title: Text(
              context.l10n.notifications_title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
                fontSize: 15,
                color: themeColor.textPrimary,
              ),
            ),
            trailing: Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: themeColor.unselectedItem,
            ),
          ),
          Divider(
            height: 1,
            indent: 70,
            endIndent: 20,
            color: themeColor.unselectedItem.withValues(alpha: 0.1),
          ),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 12,
            ),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: themeColor.unselectedItem.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.help_outline_rounded,
                color: themeColor.unselectedItem,
                size: 22,
              ),
            ),
            title: Text(
              context.l10n.settings_section_about,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
                fontSize: 15,
                color: themeColor.textPrimary,
              ),
            ),
            trailing: Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: themeColor.unselectedItem,
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildSignOutSection(BuildContext context) {
    return BlocConsumer<SignOutCubit, SignOutState>(
      listener: (context, state) {
        if (state is SignOutLoading) {
          DialogHelper.showLoading(context);
        } else {
          // Dismiss loading for any other state
          DialogHelper.dismissLoading(context);
        }

        if (state is SignOutError) {
          DialogHelper.showError(context, message: state.failure.message);
        }

        if (state is SignOutSuccess) {
          context.go(AppRoutes.login);
        }
      },
      builder: (context, state) {
        return MyCustomButton(
          onPressed: () => _showSignOutConfirmation(context),
          text: context.l10n.settings_sign_out,
          backgroundColor: Colors.redAccent.withValues(alpha:0.1),
          height: 56,
          borderRadius: 16,
          leadingIcon: const Icon(
            Icons.logout_rounded,
            color: Colors.redAccent,
            size: 20,
          ),
          textStyle: const TextStyle(
            color: Colors.redAccent,
            fontWeight: FontWeight.w800,
            fontFamily: 'Cairo',
            fontSize: 15,
          ),
        );
      },
    );
  }

  void _showSignOutConfirmation(BuildContext context) {
    DialogHelper.show(
      context,
      dialogType: DialogType.warning,
      title: context.l10n.settings_sign_out,
      desc: context
          .l10n
          .settings_sign_out_confirmation, // I assume this exists or I'll check l10n
      onOkPress: () => context.read<SignOutCubit>().signOut(),
      onCancelPress: () {},
    );
  }

}

class HeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height - 40);
    path.quadraticBezierTo(
      size.width / 2,
      size.height,
      size.width,
      size.height - 40,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
