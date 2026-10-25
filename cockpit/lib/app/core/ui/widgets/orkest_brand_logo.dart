import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:orkest_code/app/core/brand/app_identity.dart';
import 'package:orkest_code/app/core/ui/themes/themes.dart';

/// The approved ribbon symbol with the custom vector wordmark.
class OrkestBrandLogo extends StatelessWidget {
  const OrkestBrandLogo({super.key, this.width = 300});

  final double width;

  @override
  Widget build(BuildContext context) {
    final dark = context.colors.bg.computeLuminance() < 0.4;
    return SizedBox(
      width: width,
      child: AspectRatio(
        aspectRatio: 1263 / 379,
        child: LayoutBuilder(
          builder: (context, constraints) => Semantics(
            label: AppIdentity.name,
            child: Stack(
              children: [
                Positioned(
                  left: constraints.maxWidth * 60.386 / 1263,
                  top: 0,
                  width: constraints.maxWidth * 371 / 1263,
                  height: constraints.maxHeight * 371 / 379,
                  child: Image.asset(
                    'assets/branding/orkest-symbol-ribbon-v1.png',
                    fit: BoxFit.fill,
                    filterQuality: FilterQuality.high,
                    excludeFromSemantics: true,
                  ),
                ),
                SvgPicture.asset(
                  dark
                      ? 'assets/branding/orkest-wordmark-lettering-dark.svg'
                      : 'assets/branding/orkest-wordmark-lettering.svg',
                  width: constraints.maxWidth,
                  height: constraints.maxHeight,
                  fit: BoxFit.fill,
                  excludeFromSemantics: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
