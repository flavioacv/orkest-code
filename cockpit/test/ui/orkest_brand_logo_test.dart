import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orkest_code/app/core/ui/themes/themes.dart';
import 'package:orkest_code/app/core/ui/widgets/orkest_brand_logo.dart';

Widget host(Brightness brightness) {
  final tokens = buildTokens(brightness: brightness);
  return Directionality(
    textDirection: TextDirection.ltr,
    child: OrkestTheme(
      colors: tokens.colors,
      typo: tokens.typo,
      syntax: tokens.syntax,
      terminal: tokens.terminal,
      child: const Center(
        child: SizedBox(width: 180, child: OrkestBrandLogo()),
      ),
    ),
  );
}

void main() {
  testWidgets('brand follows theme changes and fits a narrow layout', (
    tester,
  ) async {
    await tester.pumpWidget(host(Brightness.light));
    await tester.pumpAndSettle();
    Image logo() => tester.widget<Image>(find.byType(Image));
    expect(
      (logo().image as AssetImage).assetName,
      'assets/branding/orkest-wordmark-ribbon-v1.png',
    );
    expect(logo().semanticLabel, 'Orkest Code');
    expect(tester.getSize(find.byType(Image)).width, lessThanOrEqualTo(180));

    await tester.pumpWidget(host(Brightness.dark));
    await tester.pumpAndSettle();
    expect(
      (logo().image as AssetImage).assetName,
      'assets/branding/orkest-wordmark-ribbon-dark-v1.png',
    );
    expect(tester.takeException(), isNull);
  });
}
