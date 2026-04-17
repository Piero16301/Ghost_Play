import 'package:ghost_play/app/app.dart';
import 'package:ghost_play/bootstrap.dart';

Future<void> main() async {
  await bootstrap(() => const App());
}
