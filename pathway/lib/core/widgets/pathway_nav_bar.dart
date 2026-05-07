import 'package:flutter/material.dart';

class PathwayAppBar extends StatelessWidget
  implements PreferredSizeWidget {
    final Widget? title;
    final double height;
    final bool automaticallyImplyLeading;
    final bool centertitle;
    final List<Widget>? actions;
    final Color? backgroundColor;

    const PathwayAppBar({
      super.key,
      this.title,
      this.actions,
      this.height = kToolbarHeight,
      this.automaticallyImplyLeading = true,
      this.centertitle = false,
      this.backgroundColor, // const Color.fromARGB(255, 76, 89, 185)
    });

    @override
    Size get preferredSize => Size.fromHeight(height);

    @override
    Widget build(BuildContext context) {
      // Pull color scheme, background color, and foreground color from Theme
      final cs = Theme.of(context).colorScheme;
      final bg = backgroundColor ?? cs.primary;
      final fg = cs.onPrimary;

      return AppBar(
        // Apply settings from input
        toolbarHeight: height,
        automaticallyImplyLeading: automaticallyImplyLeading,
        centerTitle: centertitle,
        elevation: 0,

        // Apply colors from Theme
        backgroundColor: bg,
        foregroundColor: fg,

        // Set IconTheme based on foreground color (dependant on style settings)
        iconTheme: IconThemeData(color: fg),
        titleTextStyle: Theme.of(context)
        .appBarTheme
        .titleTextStyle
        ?.copyWith(color: fg),
        
        flexibleSpace: Container(
          decoration: BoxDecoration(
            color: bg,
            image: DecorationImage(
              // Apply navbar_texture.png
              image: AssetImage('assets/images/navbar_texture.png',),
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(
                fg.withValues(alpha: 0.18),
                BlendMode.dstIn,
              )
              ),
          ),
        ),
        title: title,
        actions: actions,
      );
    }

  }