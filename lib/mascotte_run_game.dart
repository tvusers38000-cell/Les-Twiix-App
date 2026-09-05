import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

class GrenobleBackdrop extends PositionComponent {
  double scrollOffset = 0;

  GrenobleBackdrop({required Vector2 gameSize})
      : super(
          position: Vector2.zero(),
          size: gameSize,
          priority: -100,
        );

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final w = size.x;
    final h = size.y;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()..color = const Color(0xFF69B9E8),
    );

    final backMountain = Paint()..color = const Color(0xFF92A9B5);
    final frontMountain = Paint()..color = const Color(0xFF526B67);
    final snow = Paint()..color = const Color(0xFFEAF4F7);

    final backPath = Path()
      ..moveTo(0, h * 0.47)
      ..lineTo(w * 0.13, h * 0.27)
      ..lineTo(w * 0.25, h * 0.39)
      ..lineTo(w * 0.42, h * 0.20)
      ..lineTo(w * 0.57, h * 0.40)
      ..lineTo(w * 0.74, h * 0.24)
      ..lineTo(w, h * 0.45)
      ..lineTo(w, h * 0.58)
      ..lineTo(0, h * 0.58)
      ..close();

    canvas.drawPath(backPath, backMountain);

    final snowPath = Path()
      ..moveTo(w * 0.34, h * 0.29)
      ..lineTo(w * 0.42, h * 0.20)
      ..lineTo(w * 0.49, h * 0.30)
      ..lineTo(w * 0.44, h * 0.27)
      ..lineTo(w * 0.41, h * 0.31)
      ..close();

    canvas.drawPath(snowPath, snow);

    final frontPath = Path()
      ..moveTo(0, h * 0.55)
      ..lineTo(w * 0.16, h * 0.40)
      ..lineTo(w * 0.33, h * 0.52)
      ..lineTo(w * 0.52, h * 0.36)
      ..lineTo(w * 0.72, h * 0.52)
      ..lineTo(w * 0.88, h * 0.39)
      ..lineTo(w, h * 0.50)
      ..lineTo(w, h * 0.64)
      ..lineTo(0, h * 0.64)
      ..close();

    canvas.drawPath(frontPath, frontMountain);

    _drawCity(canvas, w, h);

    canvas.drawRect(
      Rect.fromLTWH(0, h - 180, w, 90),
      Paint()..color = const Color(0xFF4B9ECC),
    );

    for (double x = -30; x < w + 40; x += 70) {
      canvas.drawRect(
        Rect.fromLTWH(x, h - 155, 35, 4),
        Paint()..color = const Color(0x55FFFFFF),
      );
    }

    canvas.drawRect(
      Rect.fromLTWH(0, h - 105, w, 15),
      Paint()..color = const Color(0xFF777777),
    );
  }

  void _drawCity(Canvas canvas, double w, double h) {
    const buildingWidth = 42.0;
    const spacing = 12.0;
    final cycle = buildingWidth + spacing;

    final offset = scrollOffset % cycle;

    int index = 0;

    for (double x = -cycle - offset; x < w + cycle; x += cycle) {
      final height = 38.0 + ((index % 4) * 11);

      final buildingPaint = Paint()
        ..color = index.isEven
            ? const Color(0xFF59646C)
            : const Color(0xFF69757C);

      canvas.drawRect(
        Rect.fromLTWH(
          x,
          h - 180 - height,
          buildingWidth,
          height,
        ),
        buildingPaint,
      );

      final windowPaint = Paint()..color = const Color(0xFFFFD56A);

      for (double wy = h - 170 - height; wy <= h - 195; wy += 14) {
        canvas.drawRect(
          Rect.fromLTWH(x + 8, wy, 6, 6),
          windowPaint,
        );

        canvas.drawRect(
          Rect.fromLTWH(x + 25, wy, 6, 6),
          windowPaint,
        );
      }

      index++;
    }
  }
}

class PixelFootball extends PositionComponent {
  PixelFootball({
    required Vector2 position,
  }) : super(
          position: position,
          size: Vector2.all(30),
          anchor: Anchor.center,
        );

  double get radius => 15;

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final center = Offset(size.x / 2, size.y / 2);

    canvas.drawCircle(
      center,
      14,
      Paint()..color = Colors.white,
    );

    canvas.drawCircle(
      center,
      14,
      Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    final black = Paint()..color = const Color(0xFF111111);

    final middle = Path()
      ..moveTo(15, 8)
      ..lineTo(21, 12)
      ..lineTo(19, 19)
      ..lineTo(11, 19)
      ..lineTo(9, 12)
      ..close();

    canvas.drawPath(middle, black);

    canvas.drawRect(
      const Rect.fromLTWH(3, 10, 5, 6),
      black,
    );

    canvas.drawRect(
      const Rect.fromLTWH(22, 10, 5, 6),
      black,
    );

    canvas.drawRect(
      const Rect.fromLTWH(7, 22, 6, 4),
      black,
    );

    canvas.drawRect(
      const Rect.fromLTWH(17, 22, 6, 4),
      black,
    );
  }
}

class PixelObstacle extends PositionComponent {
  int type;

  PixelObstacle({
    required Vector2 position,
    required Vector2 size,
    this.type = 0,
  }) : super(
          position: position,
          size: size,
        );

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    switch (type) {
      case 1:
        _drawCrate(canvas);
        break;
      case 2:
        _drawBarrier(canvas);
        break;
      default:
        _drawCone(canvas);
    }
  }

  void _drawCone(Canvas canvas) {
    final orange = Paint()..color = const Color(0xFFFF7A00);
    final white = Paint()..color = Colors.white;
    final dark = Paint()..color = const Color(0xFF353535);

    canvas.drawRect(
      Rect.fromLTWH(2, size.y - 7, size.x - 4, 7),
      dark,
    );

    final cone = Path()
      ..moveTo(size.x / 2, 0)
      ..lineTo(size.x - 5, size.y - 7)
      ..lineTo(5, size.y - 7)
      ..close();

    canvas.drawPath(cone, orange);

    canvas.drawRect(
      Rect.fromLTWH(
        9,
        size.y * 0.55,
        size.x - 18,
        7,
      ),
      white,
    );
  }

  void _drawCrate(Canvas canvas) {
    final brown = Paint()..color = const Color(0xFF9B5A2E);
    final dark = Paint()..color = const Color(0xFF60361E);
    final highlight = Paint()..color = const Color(0xFFC98246);

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      brown,
    );

    canvas.drawRect(
      Rect.fromLTWH(4, 4, size.x - 8, 5),
      highlight,
    );

    canvas.drawRect(
      Rect.fromLTWH(4, size.y - 9, size.x - 8, 5),
      dark,
    );

    canvas.drawRect(
      Rect.fromLTWH(size.x * 0.43, 0, 6, size.y),
      dark,
    );
  }

  void _drawBarrier(Canvas canvas) {
    final pink = Paint()..color = const Color(0xFFE91E63);
    final white = Paint()..color = Colors.white;
    final dark = Paint()..color = const Color(0xFF333333);

    canvas.drawRect(
      Rect.fromLTWH(0, 4, size.x, 18),
      pink,
    );

    canvas.drawRect(
      Rect.fromLTWH(8, 8, 14, 5),
      white,
    );

    canvas.drawRect(
      Rect.fromLTWH(32, 8, 14, 5),
      white,
    );

    canvas.drawRect(
      Rect.fromLTWH(8, 22, 7, size.y - 22),
      dark,
    );

    canvas.drawRect(
      Rect.fromLTWH(size.x - 15, 22, 7, size.y - 22),
      dark,
    );
  }
}

class CollectParticle extends CircleComponent {
  double life = 0.5;

  CollectParticle({
    required Vector2 position,
    required Color color,
  }) : super(
          radius: 4,
          position: position,
          anchor: Anchor.center,
          paint: Paint()..color = color,
        );

  @override
  void update(double dt) {
    super.update(dt);

    life -= dt;
    position.y -= 70 * dt;
    scale += Vector2.all(1.4 * dt);

    if (life <= 0) {
      removeFromParent();
    }
  }
}

class MascotteRunGame extends FlameGame with TapCallbacks {
  static const double groundHeight = 90;
  static const double gravity = 1500;
  static const double jumpForce = -620;
  static const double startSpeed = 180;
  static const double maxSpeed = 330;

  final Random random = Random();

  late final GrenobleBackdrop backdrop;
  late final RectangleComponent ground;
  late final SpriteComponent mascotte;
  late final TextComponent distanceText;
  late final TextComponent ballText;
  late final PixelObstacle obstacle;
  late final PixelFootball ball;

  final List<RectangleComponent> groundMarks = [];

  double distance = 0;
  double worldSpeed = startSpeed;
  double verticalSpeed = 0;

  int ballsCollected = 0;

  bool onGround = true;
  bool gameOver = false;
  bool ballActive = true;

  TextComponent? gameOverText;
  TextComponent? finalStatsText;
  TextComponent? finalScoreText;
  TextComponent? restartText;

  int get score => distance.floor() + (ballsCollected * 50);

  @override
  Color backgroundColor() => const Color(0xFF69B9E8);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    backdrop = GrenobleBackdrop(
      gameSize: Vector2(size.x, size.y),
    );

    ground = RectangleComponent(
      position: Vector2(0, size.y - groundHeight),
      size: Vector2(size.x, groundHeight),
      paint: Paint()..color = const Color(0xFF3E4F3A),
    );

    mascotte = SpriteComponent(
      sprite: await loadSprite('mascotte_run_frame.png'),
      position: Vector2(55, size.y - groundHeight - 75),
      size: Vector2(105, 75),
      priority: 20,
    );

    obstacle = PixelObstacle(
      position: Vector2(
        size.x + 220,
        size.y - groundHeight - 50,
      ),
      size: Vector2(34, 50),
      priority: 15,
    );

    ball = PixelFootball(
      position: Vector2(
        size.x + 430,
        size.y - groundHeight - 95,
      ),
    )..priority = 15;

    distanceText = TextComponent(
      text: 'DISTANCE  0 m',
      position: Vector2(size.x - 16, 18),
      anchor: Anchor.topRight,
      priority: 50,
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

    ballText = TextComponent(
      text: '⚽  0',
      position: Vector2(16, 18),
      priority: 50,
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

    addAll([
      backdrop,
      ground,
      mascotte,
      obstacle,
      ball,
      distanceText,
      ballText,
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
        priority: 10,
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

    if (gameOver) return;

    distance += 18 * dt;

    worldSpeed =
        (startSpeed + distance * 0.55).clamp(startSpeed, maxSpeed).toDouble();

    backdrop.scrollOffset += worldSpeed * 0.10 * dt;

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
      _respawnObstacle();
    }

    if (ballActive) {
      ball.position.x -= worldSpeed * dt;

      if (ball.position.x + ball.radius < 0) {
        _respawnBall();
      }
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

    if (_hasObstacleCollision()) {
      _triggerGameOver();
      return;
    }

    if (ballActive && _hasBallCollision()) {
      ballsCollected++;
      ballText.text = '⚽  $ballsCollected';

      _spawnBallParticles();

      ballActive = false;
      ball.position.x = size.x + 1000;

      _respawnBall();
    }
  }

  void _respawnObstacle() {
    obstacle.type = random.nextInt(3);

    switch (obstacle.type) {
      case 1:
        obstacle.size = Vector2(46, 46);
        break;
      case 2:
        obstacle.size = Vector2(58, 42);
        break;
      default:
        obstacle.size = Vector2(34, 50);
    }

    final extraGap = 170 + random.nextDouble() * 260;

    obstacle.position = Vector2(
      size.x + extraGap,
      size.y - groundHeight - obstacle.size.y,
    );
  }

  void _respawnBall() {
    final extraGap = 260 + random.nextDouble() * 420;

    final lowBall = random.nextBool();

    ball.position = Vector2(
      size.x + extraGap,
      size.y - groundHeight - (lowBall ? 55 : 105),
    );

    ballActive = true;
  }

  void _spawnBallParticles() {
    const colors = [
      Colors.white,
      Color(0xFFE91E63),
      Color(0xFFFFD54F),
    ];

    for (int i = 0; i < 6; i++) {
      final particle = CollectParticle(
        position: Vector2(
          ball.position.x + random.nextDouble() * 20 - 10,
          ball.position.y + random.nextDouble() * 20 - 10,
        ),
        color: colors[i % colors.length],
      )..priority = 30;

      add(particle);
    }
  }

  bool _hasObstacleCollision() {
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

  bool _hasBallCollision() {
    final mascotRect = Rect.fromLTWH(
      mascotte.position.x + 15,
      mascotte.position.y + 5,
      mascotte.size.x - 25,
      mascotte.size.y - 10,
    );

    final ballRect = Rect.fromCircle(
      center: Offset(ball.position.x, ball.position.y),
      radius: ball.radius,
    );

    return mascotRect.overlaps(ballRect);
  }

  void _triggerGameOver() {
    if (gameOver) return;

    gameOver = true;
    verticalSpeed = 0;

    gameOverText = TextComponent(
      text: 'GAME OVER',
      position: Vector2(size.x / 2, size.y * 0.30),
      anchor: Anchor.center,
      priority: 100,
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

    finalStatsText = TextComponent(
      text: '${distance.floor()} m  •  $ballsCollected ballon(s)',
      position: Vector2(size.x / 2, size.y * 0.40),
      anchor: Anchor.center,
      priority: 100,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 19,
          fontWeight: FontWeight.w700,
          shadows: [
            Shadow(
              color: Colors.black,
              blurRadius: 6,
            ),
          ],
        ),
      ),
    );

    finalScoreText = TextComponent(
      text: 'SCORE  $score',
      position: Vector2(size.x / 2, size.y * 0.48),
      anchor: Anchor.center,
      priority: 100,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFFFF4081),
          fontSize: 28,
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
      position: Vector2(size.x / 2, size.y * 0.58),
      anchor: Anchor.center,
      priority: 100,
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
      finalStatsText!,
      finalScoreText!,
      restartText!,
    ]);
  }

  void _restartGame() {
    gameOverText?.removeFromParent();
    finalStatsText?.removeFromParent();
    finalScoreText?.removeFromParent();
    restartText?.removeFromParent();

    gameOverText = null;
    finalStatsText = null;
    finalScoreText = null;
    restartText = null;

    distance = 0;
    ballsCollected = 0;
    worldSpeed = startSpeed;
    verticalSpeed = 0;

    onGround = true;
    gameOver = false;
    ballActive = true;

    distanceText.text = 'DISTANCE  0 m';
    ballText.text = '⚽  0';

    mascotte.position = Vector2(
      55,
      size.y - groundHeight - mascotte.size.y,
    );

    obstacle
      ..type = 0
      ..size = Vector2(34, 50)
      ..position = Vector2(
        size.x + 220,
        size.y - groundHeight - 50,
      );

    ball.position = Vector2(
      size.x + 430,
      size.y - groundHeight - 95,
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

    backdrop.size = Vector2(newSize.x, newSize.y);

    ground
      ..position = Vector2(0, newSize.y - groundHeight)
      ..size = Vector2(newSize.x, groundHeight);

    distanceText.position = Vector2(newSize.x - 16, 18);

    if (onGround) {
      mascotte.position.y =
          newSize.y - groundHeight - mascotte.size.y;
    }

    obstacle.position.y =
        newSize.y - groundHeight - obstacle.size.y;
  }
}
