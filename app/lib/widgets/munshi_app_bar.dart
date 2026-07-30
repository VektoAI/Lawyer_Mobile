library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme.dart';

class MunshiAppBar extends StatelessWidget implements PreferredSizeWidget {
  const MunshiAppBar({
    super.key,
    required this.title,
    this.titleWidget,
    this.actions,
    this.leading,
  });

  final String title;
  /// Overrides the plain [title] text when set — e.g. an inline search field.
  final Widget? titleWidget;
  final List<Widget>? actions;
  final Widget? leading;

  /// Standard back: pop when possible, otherwise home to cases tab.
  static MunshiAppBar withBack(BuildContext context, {required String title, List<Widget>? actions}) {
    return MunshiAppBar(
      title: title,
      actions: actions,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        tooltip: 'Back',
        onPressed: () => _popOrHome(context),
      ),
    );
  }

  static void _popOrHome(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/cases');
    }
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: leading,
      automaticallyImplyLeading: leading == null,
      title: titleWidget ?? Text(title, style: const TextStyle(fontFamily: 'Fraunces', fontWeight: FontWeight.w600)),
      backgroundColor: MunshiColors.inkGreen,
      foregroundColor: Colors.white,
      elevation: 0,
      actions: actions,
    );
  }
}
