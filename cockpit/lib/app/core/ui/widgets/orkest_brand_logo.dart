import 'package:flutter/widgets.dart';
import 'package:orkest_code/app/core/brand/app_identity.dart';
import 'package:orkest_code/app/core/ui/themes/themes.dart';

/// The approved ribbon symbol and custom wordmark as a single brand artwork.
class OrkestBrandLogo extends StatelessWidget {
  const OrkestBrandLogo({super.key, this.width = 300});

  final double width;

  @override
  Widget build(BuildContext context) {
    final dark = context.colors.bg.computeLuminance() < 0.4;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.asset(
        dark
            ? 'assets/branding/orkest-wordmark-ribbon-dark-v1.png'
            : 'assets/branding/orkest-wordmark-ribbon-v1.png',
        width: width,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        semanticLabel: AppIdentity.name,
      ),
    );
  }
}
