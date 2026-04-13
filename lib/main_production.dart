import 'flavors.dart';
import 'main.dart' as runner;

void main() {
  F.appFlavor = Flavor.production;
  runner.main();
}
