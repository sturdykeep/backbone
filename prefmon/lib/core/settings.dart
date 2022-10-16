import 'package:prefmon/globals.dart';

class Settings {
  String? get pathToProject {
    return Globals.sharedPreferences.get("pathToProject")?.toString();
  }

  String? get flutterCommand {
    return Globals.sharedPreferences.get("flutterCommand")?.toString();
  }

  set pathToProject(String? path) {
    Globals.sharedPreferences.setString("pathToProject", path!);
  }

  set flutterCommand(String? path) {
    Globals.sharedPreferences.setString("flutterCommand", path!);
  }
}
