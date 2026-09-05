import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

class MascotteRunGame extends FlameGame with TapCallbacks {
  static const double groundHeight = 90;
  static const double gravity = 1500;
  static const double jumpForce = -620;

  late final RectangleComponent sky;
  late final RectangleComponent mountainBack;
  late final RectangleComponent mountainFront;
  late final RectangleComponent river;
  late final RectangleComponent quay;
  late final RectangleComponent ground;
  late final SpriteComponent mascotte;
  late final TextComponent distanceText;
  late final RectangleComponent obstacle;

  final List<RectangleComponent> groundMarks = [];

  double distance = 0;
  double worldSpeed = 180;
  double verticalSpeed = 0;

  bool onGround = true;
  bool gameOver = false;

  TextComponent? gameOverText;
  TextComponent? finalDistanceText;
  TextComponent? restartText;

  @override
  Color backgroundColor() => const Color(0xFF77C8FF);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    sky = RectangleComponent(
      position: Vector2.zero(),
      size: Vector2(size.x, size.y),
      paint: Paint()..color = const Color(0xFF77C8FF),
    );

    mountainBack = RectangleComponent(
      position: Vector2(0, size.y * 0.28),
      size: Vector2(size.x, size.y * 0.22),
      paint: Paint()..color = const Color(0xFF8FB5C9),
    );

    mountainFront = RectangleComponent(
      position: Vector2(0, size.y * 0.40),
      size: Vector2(size.x, size.y * 0.18),
      paint: Paint()..color = const Color(0xFF527A63),
    );

    river = RectangleComponent(
      position: Vector2(0, size.y - groundHeight - 90),
      size: Vector2(size.x, 90),
      paint: Paint()..color = const Color(0xFF4DA7D9),
    );

    quay = RectangleComponent(
      position: Vector2(0, size.y - groundHeight - 30),
      size: Vector2(size.x, 30),
      paint: Paint()..color = const Color(0xFF8C8C8C),
    );

    ground = RectangleComponent(
      position: Vector2(0, size.y - groundHeight),
      size: Vector2(size.x, groundHeight),
      paint: Paint()..color = const Color(0xFF4F6F3A),
    );

    mascotte = SpriteComponent(
      sprite: await loadSprite('mascotte_run_frame.png'),
      position: Vector2(55, size.y - groundHeight - 75),
      size: Vector2(105, 75),
    );

    distanceText = TextComponent(
      text: 'DISTANCE  0 m',
      position: Vector2(size.x - 16, 18),
      anchor: Anchor.topRight,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w900,
          shadows: [
            Shadow(
              color: Colors.black,
              blurRadius: 5,
              offset: Offset(1, 2),
            ),
          ],
        ),
      ),
    );

    obstacle = RectangleComponent(
      position: Vector2(
        size.x + 160,
        size.y - groundHeight - 54,
      ),
      size: Vector2(36, 54),
      paint: Paint()..color = const Color(0xFFE91E63),
    );

    addAll([
      sky,
      mountainBack,
      mountainFront,
      river,
      quay,
      ground,
      mascotte,
      obstacle,
      distanceText,
    ]);

    _createGroundMarks();
  }

  void _createGroundMarks() {
    const markWidth = 42.0;
    const gap = 34.0;
    double x = 0;

    while (x < size.x + 100) {
      final mark = RectangleComponent(
        position: Vector2(x, size.y - 30),
        size: Vector2(markWidth, 7),
        paint: Paint()..color = const Color(0x99FFFFFF),
      );

      groundMarks.add(mark);
      add(mark);

      x += markWidth + gap;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (gameOver) {
      return;
    }

    distance += 18 * dt;
    distanceText.text = 'DISTANCE  ${distance.floor()} m';

    for (final mark in groundMarks) {
      mark.position.x -= worldSpeed * dt;

      if (mark.position.x + mark.size.x < 0) {
        final rightmost = groundMarks
            .map((m) => m.position.x)
            .reduce((a, b) => a > b ? a : b);

        mark.position.x = rightmost + 76;
      }
    }

    obstacle.position.x -= worldSpeed * dt;

    if (obstacle.position.x + obstacle.size.x < 0) {
      obstacle.position.x = size.x + 180;
    }

    verticalSpeed += gravity * dt;
    mascotte.position.y += verticalSpeed * dt;

    final groundY =
        size.y - groundHeight - mascotte.size.y;

    if (mascotte.position.y >= groundY) {
      mascotte.position.y = groundY;
      verticalSpeed = 0;
      onGround = true;
    }

    if (_hasCollision()) {
      _triggerGameOver();
    }
  }

  bool _hasCollision() {
    final mascotRect = Rect.fromLTWH(
      mascotte.position.x + 20,
      mascotte.position.y + 8,
      mascotte.size.x - 35,
      mascotte.size.y - 12,
    );

    final obstacleRect = Rect.fromLTWH(
      obstacle.position.x + 3,
      obstacle.position.y + 2,
      obstacle.size.x - 6,
      obstacle.size.y - 2,
    );

    return mascotRect.overlaps(obstacleRect);
  }

  void _triggerGameOver() {
    if (gameOver) return;

    gameOver = true;
    verticalSpeed = 0;

    gameOverText = TextComponent(
      text: 'GAME OVER',
      position: Vector2(size.x / 2, size.y * 0.34),
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 36,
          fontWeight: FontWeight.w900,
          shadows: [
            Shadow(
              color: Colors.black,
              blurRadius: 8,
              offset: Offset(2, 3),
            ),
          ],
        ),
      ),
    );

    finalDistanceText = TextComponent(
      text: '${distance.floor()} m',
      position: Vector2(size.x / 2, size.y * 0.44),
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFFFF4081),
          fontSize: 27,
          fontWeight: FontWeight.w900,
          shadows: [
            Shadow(
              color: Colors.black,
              blurRadius: 6,
            ),
          ],
        ),
      ),
    );

    restartText = TextComponent(
      text: 'TOUCHE POUR REJOUER',
      position: Vector2(size.x / 2, size.y * 0.54),
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 17,
          fontWeight: FontWeight.w700,
          shadows: [
            Shadow(
              color: Colors.black,
              blurRadius: 5,
            ),
          ],
        ),
      ),
    );

    addAll([
      gameOverText!,
      finalDistanceText!,
      restartText!,
    ]);
  }

  void _restartGame() {
    gameOverText?.removeFromParent();
    finalDistanceText?.removeFromParent();
    restartText?.removeFromParent();

    gameOverText = null;
    finalDistanceText = null;
    restartText = null;

    distance = 0;
    distanceText.text = 'DISTANCE  0 m';

    worldSpeed = 180;
    verticalSpeed = 0;
    onGround = true;
    gameOver = false;

    mascotte.position = Vector2(
      55,
      size.y - groundHeight - mascotte.size.y,
    );

    obstacle.position = Vector2(
      size.x + 160,
      size.y - groundHeight - obstacle.size.y,
    );
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (gameOver) {
      _restartGame();
      super.onTapDown(event);
      return;
    }

    if (onGround) {
      verticalSpeed = jumpForce;
      onGround = false;
    }

    super.onTapDown(event);
  }

  @override
  void onGameResize(Vector2 newSize) {
    super.onGameResize(newSize);

    if (!isLoaded) return;

    sky.size = Vector2(newSize.x, newSize.y);

    mountainBack
      ..position = Vector2(0, newSize.y * 0.28)
      ..size = Vector2(newSize.x, newSize.y * 0.22);

    mountainFront
      ..position = Vector2(0, newSize.y * 0.40)
      ..size = Vector2(newSize.x, newSize.y * 0.18);

    river
      ..position =
          Vector2(0, newSize.y - groundHeight - 90)
      ..size = Vector2(newSize.x, 90);

    quay
      ..position =
          Vector2(0, newSize.y - groundHeight - 30)
      ..size = Vector2(newSize.x, 30);

    ground
      ..position =
          Vector2(0, newSize.y - groundHeight)
      ..size = Vector2(newSize.x, groundHeight);

    distanceText.position =
        Vector2(newSize.x - 16, 18);

    if (onGround) {
      mascotte.position.y =
          newSize.y - groundHeight - mascotte.size.y;
    }

    obstacle.position.y =
        newSize.y - groundHeight - obstacle.size.y;
  }
}
