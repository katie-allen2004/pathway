import 'package:flutter/material.dart';

class AppColors {
  static const background = Color.fromARGB(255, 233, 234, 247);
  static const primary = Color.fromARGB(255, 76, 89, 185);
}

class AppRadii {
  static const card = 16.0;
  static const button = 8.0;
  static const input = 12.0;
}

class AppSpacing {
  static const page = EdgeInsets.all(16);
  static const cardPadding = EdgeInsets.all(12);
  static const titlePadding = EdgeInsets.only(left: 10);
}

class TileSection extends StatelessWidget {
  final List<Widget> tiles;
  final EdgeInsets padding;

  const TileSection({
    super.key, 
    required this.tiles,
    this.padding = const EdgeInsets.all(16),
    });

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: padding,
        child: Card(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: _withDividers(tiles),
          ),
        ),
      ),
    );
  }

  List<Widget> _withDividers(List<Widget> children) {
    final out = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      out.add(children[i]);
      if (i < children.length - 1) {
        out.add(const Divider(height: 1));
      }
    }
    return out;
  }
}

class TileInstance extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback? onTap;

  const TileInstance({
    super.key, 
    required this.icon, 
    required this.title, 
    this.onTap,
    });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: Icon(icon),
      title: Text(
        title, 
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 15),
      ),
      onTap: onTap,
    );
  }
}

class SwitchInstance extends StatelessWidget {
  final String title;
  final bool value;
  final bool enabled;
  final ValueChanged<bool>? onChanged;

  const SwitchInstance({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        title,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      value: value,
      onChanged: enabled ? onChanged : null,
    );
  }
}


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