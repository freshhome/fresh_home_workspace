import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';
import 'package:get_it/get_it.dart';
import '../../features/profile/presentation/profile_presentation.dart';
import '../widgets/unified_bottom_bar.dart';

import 'package:flutter/services.dart';
import 'package:shared/presentation/widget/exit_app_dialog.dart';

class MainLayout extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainLayout({
    super.key,
    required this.navigationShell,
  });

  @override
  Widget build(BuildContext context) {
    final navigationConfig = GetIt.instance<NavigationConfig>();
    
    return BlocProvider<ProfileCubit>(
      create: (context) => GetIt.instance<ProfileCubit>()..load(),
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;

          // 1. If not on Home Tab (Index 0), go to Home
          if (navigationShell.currentIndex != 0) {
            navigationShell.goBranch(0);
            return;
          }

          // 2. If on Home Tab, show Exit Confirmation Dialog
          final shouldExit = await showDialog<bool>(
            context: context,
            barrierColor: Colors.black.withValues(alpha:0.5),
            builder: (context) => const ExitAppDialog(),
          );

          if (shouldExit == true) {
            SystemNavigator.pop();
          }
        },
        child: Scaffold(
          body: navigationShell,
          bottomNavigationBar: UnifiedBottomBar(
            navigationShell: navigationShell,
            navigationConfig: navigationConfig,
          ),
        ),
      ),
    );
  }
}
