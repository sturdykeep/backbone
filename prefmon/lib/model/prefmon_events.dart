abstract class PrefMonEvent {}

class PrefMonDataEvent extends PrefMonEvent {
  final String category;
  final String data;

  PrefMonDataEvent(this.category, this.data);

  @override
  String toString() {
    return "$category->$data";
  }
}

class Starting extends PrefMonEvent {}

class Stopped extends PrefMonEvent {}

typedef PrefMonMessageCallback = void Function(PrefMonEvent event);
typedef LogCallback = void Function(String message);
