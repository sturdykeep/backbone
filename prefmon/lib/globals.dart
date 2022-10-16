import 'package:prefmon/core/backbone_worker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Globals {
  static late final SharedPreferences sharedPreferences;
  static final BackboneWorker worker = BackboneWorker();
}
