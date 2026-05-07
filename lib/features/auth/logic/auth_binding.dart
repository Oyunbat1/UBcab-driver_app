import 'package:get/get.dart';

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    // AuthApi and AuthController are registered permanently in main.dart
    // No need to re-register here
  }
}
