import 'package:flutter/material.dart';

// Light theme from the web application's packages/web-ui/src/tokens.css.
const canvas = Color(0xfff7f7f8);
const ink = Color(0xff1b1b1f);
const muted = Color(0xff62626b);
const webBorder = Color(0xffd7d7dc);
const softBorder = Color(0x141b1b1f);
const accent = Color(0xffe57bd9);
const accentStrong = Color(0xffa83d99);
const accentSoft = Color(0xfff7e5f4);
const plum = Color(0xff7b286f);

final webTheme = ThemeData(
  colorScheme: ColorScheme.fromSeed(seedColor: accent).copyWith(
    primary: plum,
    onPrimary: Colors.white,
    primaryContainer: accentSoft,
    onPrimaryContainer: plum,
    surface: Colors.white,
    onSurface: ink,
    onSurfaceVariant: muted,
    outline: webBorder,
  ),
  scaffoldBackgroundColor: Colors.white,
  dividerColor: webBorder,
  dividerTheme: const DividerThemeData(color: webBorder, thickness: 1),
  inputDecorationTheme: const InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    hintStyle: TextStyle(color: muted),
    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: webBorder)),
    focusedBorder: OutlineInputBorder(
      borderSide: BorderSide(color: plum, width: 2),
    ),
  ),
  menuTheme: const MenuThemeData(
    style: MenuStyle(
      padding: WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
      maximumSize: WidgetStatePropertyAll(Size(340, double.infinity)),
      backgroundColor: WidgetStatePropertyAll(canvas),
      surfaceTintColor: WidgetStatePropertyAll(Colors.transparent),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
          side: BorderSide(color: webBorder),
        ),
      ),
    ),
  ),
  popupMenuTheme: const PopupMenuThemeData(
    menuPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    color: canvas,
    surfaceTintColor: Colors.transparent,
    elevation: 5,
    position: PopupMenuPosition.under,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(10)),
      side: BorderSide(color: webBorder),
    ),
  ),
  dialogTheme: const DialogThemeData(backgroundColor: Colors.white),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: accent,
      foregroundColor: ink,
    ),
  ),
);

const double toolbarButtonHeight = 34;
const double toolbarButtonDepth = 3;

class RaisedCircle extends StatelessWidget {
  final String tooltip;
  final VoidCallback? onPressed;
  final Widget icon;
  final double edgeHeight;
  final Color fill, foreground, depth;
  final double size;

  const RaisedCircle({
    super.key,
    required this.tooltip,
    required this.onPressed,
    required this.icon,
    this.fill = canvas,
    this.foreground = muted,
    this.depth = webBorder,
    this.size = toolbarButtonHeight,
    this.edgeHeight = toolbarButtonDepth,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: enabled
            ? [BoxShadow(color: depth, offset: Offset(0, edgeHeight))]
            : null,
      ),
      child: IconButton.filled(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: icon,
        style: IconButton.styleFrom(
          fixedSize: Size.square(size),
          minimumSize: Size.square(size),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          padding: EdgeInsets.zero,
          iconSize: size * 0.55,
          backgroundColor: fill,
          foregroundColor: foreground,
          side: BorderSide(
            color: enabled
                ? depth == webBorder
                      ? webBorder
                      : fill
                : webBorder,
          ),
        ),
      ),
    );
  }
}

class PlayButton extends StatelessWidget {
  final String tooltip;
  final VoidCallback? onPressed;
  final double size;
  const PlayButton({
    super.key,
    required this.tooltip,
    required this.onPressed,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) => RaisedCircle(
    tooltip: tooltip,
    onPressed: onPressed,
    size: size,
    edgeHeight: size * 0.12,
    fill: accent,
    depth: accentStrong,
    foreground: ink,
    icon: Builder(
      builder: (context) => CustomPaint(
        size: Size.square(size * 0.42),
        painter: _PlayOutline(IconTheme.of(context).color ?? ink),
      ),
    ),
  );
}

class _PlayOutline extends CustomPainter {
  final Color color;
  const _PlayOutline(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24, size.height / 24);
    final outline = Path()
      ..moveTo(5, 4)
      ..quadraticBezierTo(5, 1, 7.6, 2.6)
      ..lineTo(20.8, 10.4)
      ..quadraticBezierTo(23.4, 12, 20.8, 13.6)
      ..lineTo(7.6, 21.4)
      ..quadraticBezierTo(5, 23, 5, 20)
      ..close();
    canvas.drawPath(
      outline,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.9
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_PlayOutline oldDelegate) => oldDelegate.color != color;
}

class MenuLabel extends StatelessWidget {
  final String label;
  final bool selected;
  const MenuLabel(this.label, {super.key, required this.selected});
  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    child: Row(
      children: [
        Expanded(
          child: Text(label, style: TextStyle(color: selected ? plum : ink)),
        ),
        if (selected) const Icon(Icons.check_rounded, color: plum, size: 16),
      ],
    ),
  );
}
