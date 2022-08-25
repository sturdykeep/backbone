import 'package:benchmark/benchmark.dart';
import 'package:oxygen/oxygen.dart';

// Components
class TestComponentA extends Component<int> {
  int? yourProperty;

  @override
  void init([int? data]) {
    yourProperty = 10;
  }

  @override
  void reset() {
    yourProperty = null;
  }
}

// System
class TestSystem extends System {
  late Query query;
  int result = 0;

  @override
  void init() {
    query = createQuery([Has<TestComponentA>()]);
  }

  @override
  void execute(double delta) {
    var result = 0;
    for (final entity in query.entities) {
      final value = entity.get<TestComponentA>();
      result += value?.yourProperty ?? 0;
    }
    this.result = result;
  }
}

BenchmarkFunction oxygenPureMillion() {
  final world = World();
  final system = TestSystem();
  world.registerComponent(() => TestComponentA());
  world.registerSystem(system);
  world.init();

  // Setup 100000 entities
  for (var i = 0; i < 100000; i++) {
    final entity = world.createEntity();
    entity.add<TestComponentA, int>(10);
  }

  return () {
    world.execute(0.0);
    return system.result;
  };
}
