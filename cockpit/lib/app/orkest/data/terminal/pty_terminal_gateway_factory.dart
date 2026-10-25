import 'package:orkest_code/app/orkest/data/terminal/pty_terminal_gateway.dart';
import 'package:orkest_code/app/orkest/domain/contracts/terminal_gateway.dart';
import 'package:orkest_code/app/orkest/domain/contracts/terminal_gateway_factory.dart';

/// Cria um [PtyTerminalGateway] novo por terminal.
class PtyTerminalGatewayFactory implements TerminalGatewayFactory {
  const PtyTerminalGatewayFactory();

  @override
  TerminalGateway create() => PtyTerminalGateway();
}
