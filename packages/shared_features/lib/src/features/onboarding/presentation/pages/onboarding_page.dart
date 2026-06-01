import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:get_it/get_it.dart';
import 'package:shared/core/constants/app_assets.dart';
import 'package:shared/core/constants/app_routes.dart';
import 'package:shared/presentation/localization/translations/app_localizations.dart';
import 'package:shared/presentation/widget/my_custom_button.dart';
import 'package:shared_features/src/features/onboarding/presentation/onboarding_presentation.dart';

class OnboardingPage extends StatelessWidget {
  OnboardingPage({super.key});

  final PageController _pageController = PageController();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final List<Widget> screens = [
      OnboardingScreen(
        title: l10n.onboarding_title_1,
        imagePath: AppAssets.onboardingImage1,
        description: l10n.onboarding_description_1,
      ),
      OnboardingScreen(
        title: l10n.onboarding_title_2,
        imagePath: AppAssets.onboardingImage2,
        description: l10n.onboarding_description_2,

      ),
      OnboardingScreen(
        title: l10n.onboarding_title_3,

        imagePath: AppAssets.onboardingImage3,
        description: l10n.onboarding_description_3,
      ),
      OnboardingScreen(
        title:l10n.onboarding_title_4,

        imagePath: AppAssets.onboardingImage4,
        description: l10n.onboarding_description_4,
      ),
    ];
    return BlocProvider(
      create: (_) => GetIt.instance<OnboardingCubit>(),
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(0.50, -0.00),
              end: Alignment(0.50, 1.00),
              colors: [const Color(0xFF9EE0F4), const Color(0xFF8BD5AF)],
            ),
          ),

          child: BlocConsumer<OnboardingCubit, OnboardingState>(
            listener: (context, state) {
              _pageController.animateToPage(
                state.currentPage,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
            builder: (context, state) {
              return Column(
                children: [
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: screens.length,
                      onPageChanged: (index) =>
                          context.read<OnboardingCubit>().updatePage(index),
                      itemBuilder: (_, index) => screens[index],
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      screens.length,
                      (index) => Container(
                        margin: const EdgeInsets.all(4),
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: state.currentPage == index
                              ? Colors.blue
                              : Colors.grey,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: MyCustomButton(
                      onPressed: () {
                        if (state.currentPage == 3) {
                          context.read<OnboardingCubit>().completeOnboarding();
                          context.go(AppRoutes.login);
                        } else {
                          context.read<OnboardingCubit>().nextPage();
                        }
                      },
                      text: state.currentPage == 3
                          ? l10n.general_get_started
                          : l10n.general_next,
                      width: double.infinity,
                      height: 56,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
