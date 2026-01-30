import 'package:flutter/material.dart';

class PathwayAppBar extends StatelessWidget
  implements PreferredSizeWidget {
    final Widget? title;
    final double height;
    final bool automaticallyImplyLeading;
    final bool centertitle;
    final List<Widget>? actions;
    final Color backgroundColor;

    const PathwayAppBar({
      super.key,
      this.title,
      this.actions,
      this.height = kToolbarHeight,
      this.automaticallyImplyLeading = true,
      this.centertitle = false,
      this.backgroundColor = const Color.fromARGB(255, 76, 89, 185)
    });

    @override
    Size get preferredSize => Size.fromHeight(height);

    @override
    Widget build(BuildContext context) {
      return AppBar(
        toolbarHeight: height,
        automaticallyImplyLeading: automaticallyImplyLeading,
        centerTitle: centertitle,
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            color: Color.fromARGB(255, 76, 89, 185),
            image: DecorationImage(
              image: AssetImage('assets/images/navbar_texture.png',),
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(
                Color.fromARGB(55, 0, 0, 0),
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