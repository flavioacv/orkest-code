import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:orkest_code/app/orkest/domain/entities/db_vendor.dart';

/// Ícone SVG representativo do Vendor ou Engine de Banco de Dados.
class DbVendorIcon extends StatelessWidget {
  const DbVendorIcon(this.vendor, {super.key, this.size = 15});

  final DbVendorKind vendor;
  final double size;

  static const _assetDir = 'assets/db_icons';

  @override
  Widget build(BuildContext context) {
    // Procura o arquivo correspondente ao id do vendor ou cai no engine subjacente
    final fileName = '${vendor.id}.svg';
    final fallbackFileName = '${vendor.engine.name}.svg';

    return SvgPicture.asset(
      '$_assetDir/$fileName',
      width: size,
      height: size,
      placeholderBuilder: (_) => SvgPicture.asset(
        '$_assetDir/$fallbackFileName',
        width: size,
        height: size,
        placeholderBuilder: (_) => SizedBox(width: size, height: size),
      ),
    );
  }
}
