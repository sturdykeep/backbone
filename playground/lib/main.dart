import 'package:backbone/realm_mixin.dart';
import 'package:backbone/widget.dart';
import 'package:flame/game.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter/material.dart';

void main() async {
  // Spin up Flutter
  WidgetsFlutterBinding.ensureInitialized();
  // Start the actual app
  runApp(
    AppShell(),
  );
}

class PlaygroundGame {
  final String name;
  final HasRealm Function() gameBuilder;

  PlaygroundGame(this.name, this.gameBuilder);
}

class AppShell extends HookWidget {
  const AppShell({super.key});

  List<PlaygroundGame> get games => [
        PlaygroundGame('Game 1', () => throw UnimplementedError()),
      ];

  @override
  Widget build(BuildContext context) {
    final selectedGame = useState(0);

    return MaterialApp(
      title: 'Backbone Playground',
      theme: ThemeData(
        primarySwatch: Colors.pink,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Backbone Playground'),
        ),
        // Floating column for selecting a game
        // and the actual game on the right
        body: Row(
          children: [
            // Column of games
            Column(
                children: games.map((game) {
              final index = games.indexOf(game);
              return TextButton(
                onPressed: () => selectedGame.value = index,
                child: Text(game.name),
              );
            }).toList()),
            // Game
            Expanded(
              child: BackboneGameWidget(
                  game: games[selectedGame.value].gameBuilder()),
            ),
          ],
        ),
      ),
    );
  }
}
