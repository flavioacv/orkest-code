#!/bin/bash
# Package an already-built Release app for private Apple Silicon testing.
# No installation, publishing, certificate import or Gatekeeper modification.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="${1:-$ROOT/build/macos/Build/Products/Release/Orkest Code.app}"
OUT="$ROOT/dist"
PLIST="$APP/Contents/Info.plist"
[[ -f "$PLIST" ]] || { echo "Release app not found: $APP" >&2; exit 1; }
VERSION=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$PLIST")
BUILD=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$PLIST")
MIN_OS=$(/usr/libexec/PlistBuddy -c 'Print :LSMinimumSystemVersion' "$PLIST")
IDENTIFIER=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$PLIST")
[[ "$IDENTIFIER" == 'com.flavioacv.orkestcode' ]] || {
  echo "Expected independent Release identifier; got $IDENTIFIER" >&2; exit 1;
}
for exe in "$APP/Contents/MacOS/Orkest Code" \
           "$APP/Contents/Resources/orkest-cli" \
           "$APP/Contents/Resources/orkest-server-bundle/bin/orkest-server"; do
  [[ -x "$exe" ]] || { echo "Required executable missing: $exe" >&2; exit 1; }
  /usr/bin/lipo -archs "$exe" | /usr/bin/grep -qw arm64 || {
    echo "Apple Silicon slice missing: $exe" >&2; exit 1;
  }
done
/usr/bin/codesign --verify --deep --strict "$APP"
SERVER_VERSION=$("$APP/Contents/Resources/orkest-server-bundle/bin/orkest-server" --version)
[[ "$SERVER_VERSION" == "$VERSION" ]] || {
  echo "Server version $SERVER_VERSION differs from app version $VERSION" >&2; exit 1;
}
mkdir -p "$OUT" "$ROOT/build"
NAME="Orkest-Code-${VERSION}-${BUILD}-macos-apple-silicon-test.dmg"
DMG="$OUT/$NAME"
[[ ! -e "$DMG" ]] || { echo "Refusing to overwrite: $DMG" >&2; exit 1; }
STAGE=$(mktemp -d "$ROOT/build/dmg-stage.XXXXXX")
IMAGE_WORK=$(mktemp -d "$ROOT/build/dmg-image.XXXXXX")
trap 'rm -rf "$STAGE" "$IMAGE_WORK"' EXIT
/usr/bin/ditto "$APP" "$STAGE/Orkest Code.app"
ln -s /Applications "$STAGE/Applications"
cat > "$STAGE/Leia-me.txt" <<EOF
ORKEST CODE — TESTE PRIVADO
Orkest Code $VERSION (build $BUILD)
Mac Apple Silicon (M1 ou mais recente), macOS $MIN_OS ou mais recente.

INSTALAÇÃO
1. Abra o DMG e arraste Orkest Code.app para Applications/Aplicativos.
2. Ejete a imagem e abra o aplicativo pela pasta Aplicativos.
3. Esta prévia não tem assinatura Developer ID nem notarização Apple.
   Se o macOS bloquear a primeira abertura, consulte Privacidade e Segurança
   nas Configurações do Sistema e permita a abertura somente desta cópia,
   recebida de uma pessoa de confiança. Não é preciso desativar o Gatekeeper.

Não é necessário instalar Flutter ou Dart para abrir o app. Para usar agentes,
instale e autentique no seu Mac o CLI do agente escolhido. Contas, chaves e
histórico do desenvolvedor não acompanham este pacote. O app usa dados próprios
em ~/.orkest e não substitui o Cockpit original. Updates automáticos desligados.

CLI EM FERRAMENTAS DE AGENTES
Se a ferramenta do agente filtrar o PATH, o CLI continua disponível por
caminho absoluto: ~/.orkest/bin/orkest. Peça para reler a skill orkest-cli.
Operation not permitted ao acessar o socket exige autorização pontual na
ferramenta do agente; não significa que o aplicativo esteja ausente.
Não é necessário desativar o sandbox global nem trocar por agentes internos.

O QUE TESTAR
- Abrir uma pasta e digitar/colar no terminal.
- Iniciar seu agente habitual e acompanhar o personagem no Office.
- Conferir atividades, conclusão e pedidos de resposta/permissão.
- Editar nome/aparência e alternar entre terminal e Office.
- Mudar tema e idioma; conferir logo e ícone.

AO REPORTAR UM PROBLEMA
Informe versão do macOS, modelo do Mac, agente e passos para reproduzir.
Remova credenciais e informações privadas de prints/logs antes de compartilhar.

Licenças e atribuições acompanham a aplicação. Esta é uma prévia de teste,
não uma release pública notarizada.
EOF
if [[ -f "$ROOT/THIRD_PARTY_NOTICES.md" ]]; then
  cp "$ROOT/THIRD_PARTY_NOTICES.md" "$STAGE/Licencas.txt"
fi
/usr/bin/hdiutil create -volname "Orkest Code Test" -srcfolder "$STAGE" \
  -fs HFS+ -format UDZO "$IMAGE_WORK/$NAME"
/usr/bin/hdiutil verify "$IMAGE_WORK/$NAME"
mv "$IMAGE_WORK/$NAME" "$DMG"
(cd "$OUT" && /usr/bin/shasum -a 256 "$NAME" > "$NAME.sha256")
cp "$STAGE/Leia-me.txt" "$OUT/Leia-me-Orkest-Code.txt"
echo "Created: $DMG"
echo "Checksum: $DMG.sha256"
