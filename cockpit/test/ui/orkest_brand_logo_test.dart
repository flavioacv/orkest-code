import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
    SvgPicture lettering() =>
        tester.widget<SvgPicture>(find.byType(SvgPicture));
    Image symbol() => tester.widget<Image>(find.byType(Image));
    expect(
      lettering().bytesLoader,
      isA<SvgAssetLoader>().having(
        (loader) => loader.assetName,
        'assetName',
        'assets/branding/orkest-wordmark-lettering.svg',
      ),
    );
    expect(
      (symbol().image as AssetImage).assetName,
      'assets/branding/orkest-symbol-ribbon-v1.png',
    );
    expect(find.bySemanticsLabel('Orkest Code'), findsOneWidget);
    expect(tester.getSize(find.byType(Image)).width, lessThanOrEqualTo(180));

    await tester.pumpWidget(host(Brightness.dark));
    await tester.pumpAndSettle();
    expect(
      lettering().bytesLoader,
      isA<SvgAssetLoader>().having(
        (loader) => loader.assetName,
        'assetName',
        'assets/branding/orkest-wordmark-lettering-dark.svg',
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
