import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Displays the correct logo asset depending on current theme.
///
/// Uses the light `assets/images/Logo.svg` in light mode and
/// `assets/images/LogoBianco.svg` in dark mode.
class ThemedLogo extends StatelessWidget {
  final double? width;
  final double? height;
  final BoxFit fit;
  final bool useThemeAsset;

  const ThemedLogo({
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.useThemeAsset = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final asset = useThemeAsset && isDark
        ? 'assets/images/LogoBianco.svg'
        : 'assets/images/Logo.svg';
    final colorFilter = useThemeAsset && isDark
        ? const ColorFilter.mode(Colors.white, BlendMode.srcIn)
        : null;

    return SvgPicture.asset(
      key: ValueKey(asset),
      asset,
      width: width,
      height: height,
      fit: fit,
      colorFilter: colorFilter,
    );
  }
}
