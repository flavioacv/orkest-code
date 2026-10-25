import 'dart:io';

import 'package:orkest_code/app/orkest/domain/entities/gallery_template.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'template "panel" da Galeria == cli/skills/orkest-design/templates/dashboard.panel',
    () {
      final file = File('cli/skills/orkest-design/templates/dashboard.panel');
      expect(
        file.existsSync(),
        isTrue,
        reason: 'rode o teste da raiz de orkest/',
      );
      expect(GalleryTemplate.panel.content, file.readAsStringSync());
    },
  );
}
