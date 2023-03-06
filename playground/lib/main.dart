import 'package:backbone/realm_mixin.dart';
import 'package:backbone/widget.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter/material.dart';
import 'package:playground/games/animation.dart';
import 'package:playground/games/sprite.dart';
import 'package:playground/games/top_down.dart';
import 'package:playground/games/transform.dart';

void main() async {
  // Spin up Flutter
  WidgetsFlutterBinding.ensureInitialized();
  // Start the actual app
  runApp(
    AppShell(),
  );
}

class PlaygroundGameInitializer {
  final String name;
  final HasRealm Function() gameBuilder;

  PlaygroundGameInitializer(this.name, this.gameBuilder);
}

class AppShell extends HookWidget {
  AppShell({super.key});

  List<PlaygroundGameInitializer> games = [
    PlaygroundGameInitializer('Transform', () => TransformGame()),
    PlaygroundGameInitializer('Top-down', () => TopdownGame()),
    PlaygroundGameInitializer('Sprite', () => SpriteGame()),
    PlaygroundGameInitializer('Animation', () => AnimationGame()),
  ];

  @override
  Widget build(BuildContext context) {
    final menuOpen = useState(false);
    final selectedGame = useState(0);

    return MaterialApp(
      title: 'Backbone Playground',
      theme: ThemeData(
        primarySwatch: Colors.pink,
      ),
      home: Scaffold(
        floatingActionButton: FloatingActionButton(
          tooltip: "List",
          onPressed: () => menuOpen.value = !menuOpen.value,
          child:
              menuOpen.value ? const Icon(Icons.close) : const Icon(Icons.list),
        ),

        // Floating column for selecting a game
        // and the actual game on the right
        body: Row(
          children: [
            // Column of games
            if (menuOpen.value)
              Column(
                  children: games.map((game) {
                final index = games.indexOf(game);
                return TextButton(
                  onPressed: () => selectedGame.value = index,
                  child: Text(
                    game.name,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
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
