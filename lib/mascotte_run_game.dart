import 'dart:math';

import 'package:flame/cache.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GrenobleBackdrop extends PositionComponent {
  late final SpriteComponent background1;
  late final SpriteComponent background2;

  final Images gameImages;

  double scrollSpeed = 0;

  GrenobleBackdrop({
    required Vector2 gameSize,
    required this.gameImages,
  }) : super(
          position: Vector2.zero(),
          size: gameSize,
          priority: -100,
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final sprite = Sprite(
      await gameImages.load('mascotte_run_grenoble.png'),
    );

    background1 = SpriteComponent(
      sprite: sprite,
      position: Vector2.zero(),
    );

    background2 = SpriteComponent(
      sprite: sprite,
      position: Vector2.zero(),
    );

    addAll([
      background1,
      background2,
    ]);

    _fitBackground(size);
  }

  void _fitBackground(Vector2 targetSize) {
    const imageRatio = 1774 / 887;

    final fittedHeight = targetSize.y;
    final fittedWidth = fittedHeight * imageRatio;

    background1
      ..size = Vector2(fittedWidth, fittedHeight)
      ..position = Vector2(0, 0);

    background2
      ..size = Vector2(fittedWidth, fittedHeight)
      ..position = Vector2(fittedWidth, 0);
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (scrollSpeed <= 0) return;

    final movement = scrollSpeed * dt;

    background1.position.x -= movement;
    background2.position.x -= movement;

    final width = background1.size.x;

    if (background1.position.x + width <= 0) {
      background1.position.x = background2.position.x + width;
    }

    if (background2.position.x + width <= 0) {
      background2.position.x = background1.position.x + width;
    }
  }

  @override
  void onGameResize(Vector2 newSize) {
    super.onGameResize(newSize);

    size = Vector2(newSize.x, newSize.y);

    if (isLoaded) {
      _fitBackground(newSize);
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

  void _drawPixelShadow(Canvas canvas, double width, double y) {
    final shadow = Paint()..color = const Color(0x66000000);

    canvas.drawRect(
      Rect.fromLTWH(
        (size.x - width) / 2,
        y,
        width,
        4,
      ),
      shadow,
    );
  }

  void _drawCone(Canvas canvas) {
    final outline = Paint()..color = const Color(0xFF2B2524);
    final darkOrange = Paint()..color = const Color(0xFFC94D00);
    final orange = Paint()..color = const Color(0xFFFF7A00);
    final lightOrange = Paint()..color = const Color(0xFFFFA43A);
    final white = Paint()..color = const Color(0xFFF6F3E8);
    final base = Paint()..color = const Color(0xFF393536);

    _drawPixelShadow(canvas, size.x - 2, size.y - 3);

    canvas.drawRect(
      Rect.fromLTWH(1, size.y - 9, size.x - 2, 8),
      outline,
    );

    canvas.drawRect(
      Rect.fromLTWH(4, size.y - 7, size.x - 8, 5),
      base,
    );

    final coneOutline = Path()
      ..moveTo(size.x / 2, 0)
      ..lineTo(size.x - 5, size.y - 9)
      ..lineTo(5, size.y - 9)
      ..close();

    canvas.drawPath(coneOutline, outline);

    final coneBody = Path()
      ..moveTo(size.x / 2, 4)
      ..lineTo(size.x - 9, size.y - 11)
      ..lineTo(9, size.y - 11)
      ..close();

    canvas.drawPath(coneBody, orange);

    canvas.drawRect(
      Rect.fromLTWH(
        size.x * 0.30,
        size.y * 0.42,
        size.x * 0.40,
        7,
      ),
      white,
    );

    canvas.drawRect(
      Rect.fromLTWH(
        size.x * 0.34,
        size.y * 0.18,
        4,
        size.y * 0.18,
      ),
      lightOrange,
    );

    canvas.drawRect(
      Rect.fromLTWH(
        size.x * 0.22,
        size.y * 0.68,
        size.x * 0.56,
        5,
      ),
      darkOrange,
    );
  }

  void _drawCrate(Canvas canvas) {
    final outline = Paint()..color = const Color(0xFF3B2518);
    final darkest = Paint()..color = const Color(0xFF5A341E);
    final brown = Paint()..color = const Color(0xFF9F5C31);
    final light = Paint()..color = const Color(0xFFD38A4E);
    final highlight = Paint()..color = const Color(0xFFF0AC65);

    _drawPixelShadow(canvas, size.x - 3, size.y - 3);

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      outline,
    );

    canvas.drawRect(
      Rect.fromLTWH(4, 4, size.x - 8, size.y - 8),
      brown,
    );

    canvas.drawRect(
      Rect.fromLTWH(5, 5, size.x - 10, 6),
      light,
    );

    canvas.drawRect(
      Rect.fromLTWH(5, size.y - 11, size.x - 10, 6),
      darkest,
    );

    canvas.drawRect(
      Rect.fromLTWH(5, 5, 6, size.y - 10),
      darkest,
    );

    canvas.drawRect(
      Rect.fromLTWH(size.x - 11, 5, 6, size.y - 10),
      darkest,
    );

    final bracePaint = Paint()
      ..color = const Color(0xFF6D4025)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.square;

    canvas.drawLine(
      const Offset(10, 11),
      Offset(size.x - 10, size.y - 11),
      bracePaint,
    );

    canvas.drawLine(
      Offset(size.x - 10, 11),
      Offset(10, size.y - 11),
      bracePaint,
    );

    canvas.drawRect(
      const Rect.fromLTWH(8, 8, 4, 4),
      highlight,
    );

    canvas.drawRect(
      Rect.fromLTWH(size.x - 13, 8, 4, 4),
      highlight,
    );
  }

  void _drawBarrier(Canvas canvas) {
    final outline = Paint()..color = const Color(0xFF27242A);
    final pinkDark = Paint()..color = const Color(0xFF9F164D);
    final pink = Paint()..color = const Color(0xFFE91E63);
    final pinkLight = Paint()..color = const Color(0xFFFF5A91);
    final white = Paint()..color = const Color(0xFFF4F1F3);
    final metal = Paint()..color = const Color(0xFF45424A);

    _drawPixelShadow(canvas, size.x - 2, size.y - 3);

    canvas.drawRect(
      Rect.fromLTWH(0, 3, size.x, 22),
      outline,
    );

    canvas.drawRect(
      Rect.fromLTWH(3, 6, size.x - 6, 16),
      pink,
    );

    final stripe1 = Path()
      ..moveTo(7, 6)
      ..lineTo(19, 6)
      ..lineTo(10, 22)
      ..lineTo(3, 22)
      ..close();

    final stripe2 = Path()
      ..moveTo(28, 6)
      ..lineTo(40, 6)
      ..lineTo(31, 22)
      ..lineTo(19, 22)
      ..close();

    final stripe3 = Path()
      ..moveTo(49, 6)
      ..lineTo(size.x - 3, 6)
      ..lineTo(size.x - 12, 22)
      ..lineTo(40, 22)
      ..close();

    canvas.drawPath(stripe1, white);
    canvas.drawPath(stripe2, white);
    canvas.drawPath(stripe3, white);

    canvas.drawRect(
      Rect.fromLTWH(5, 7, size.x - 10, 3),
      pinkLight,
    );

    canvas.drawRect(
      Rect.fromLTWH(3, 19, size.x - 6, 3),
      pinkDark,
    );

    canvas.drawRect(
      Rect.fromLTWH(8, 25, 8, size.y - 25),
      outline,
    );

    canvas.drawRect(
      Rect.fromLTWH(size.x - 16, 25, 8, size.y - 25),
      outline,
    );

    canvas.drawRect(
      Rect.fromLTWH(10, 27, 4, size.y - 29),
      metal,
    );

    canvas.drawRect(
      Rect.fromLTWH(size.x - 14, 27, 4, size.y - 29),
      metal,
    );

    canvas.drawRect(
      Rect.fromLTWH(4, size.y - 6, 16, 5),
      outline,
    );

    canvas.drawRect(
      Rect.fromLTWH(size.x - 20, size.y - 6, 16, 5),
      outline,
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

class FloatingScoreText extends TextComponent {
  double life = 0.7;

  FloatingScoreText({
    required Vector2 position,
    required String text,
  }) : super(
          text: text,
          position: position,
          anchor: Anchor.center,
          priority: 60,
          textRenderer: TextPaint(
            style: const TextStyle(
              color: Color(0xFFFF4081),
              fontSize: 24,
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

  @override
  void update(double dt) {
    super.update(dt);

    life -= dt;
    position.y -= 55 * dt;
    scale += Vector2.all(0.35 * dt);

    if (life <= 0) {
      removeFromParent();
    }
  }
}

class MascotteRunGame extends FlameGame with TapCallbacks {
  final String skinId;
  final bool soundEnabled;

  MascotteRunGame({
    this.skinId = 'gnomi',
    this.soundEnabled = true,
  });

  final AudioPlayer _sfxPlayer = AudioPlayer();

  Future<void> _playSfx(String asset, {double volume = 0.7}) async {
    if (!soundEnabled) return;

    try {
      await _sfxPlayer.setAudioContext(
        AudioContext(
          android: const AudioContextAndroid(
            contentType: AndroidContentType.sonification,
            usageType: AndroidUsageType.game,
            audioFocus: AndroidAudioFocus.none,
          ),
        ),
      );

      await _sfxPlayer.stop();
      await _sfxPlayer.setVolume(volume);
      await _sfxPlayer.play(
        AssetSource('audio/$asset'),
      );
    } catch (e) {
      debugPrint('Mascotte Run SFX error: $e');
    }
  }

  String get _skinAssetName {
    switch (skinId) {
      case 'wendy':
        return 'mascotte_run_wendy.png';
      case 'swan':
        return 'mascotte_run_swan.png';
      case 'dean':
        return 'mascotte_run_dean.png';
      case 'gnomi':
      default:
        return 'mascotte_run_frame.png';
    }
  }

  static const double groundHeight = 90;
  static const double gravity = 1500;
  static const double jumpForce = -620;
  static const double startSpeed = 205;
  static const double maxSpeed = 500;

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

  double _runAnimationTime = 0;
  double _landingEffect = 0;
  double _impactEffect = 0;

  int ballsCollected = 0;

  bool onGround = true;
  bool gameOver = false;
  bool ballActive = true;

  TextComponent? gameOverText;
  TextComponent? finalStatsText;
  TextComponent? finalScoreText;
  TextComponent? restartText;

  static const String bestDistanceKey = 'mascotte_run_best_distance';

  static const List<int> distanceMilestones = [
    500,
    1000,
    2000,
    3500,
    5000,
  ];

  int get score => distance.floor() + (ballsCollected * 50);

  @override
  Color backgroundColor() => const Color(0xFF69B9E8);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    backdrop = GrenobleBackdrop(
      gameSize: Vector2(size.x, size.y),
      gameImages: images,
    );

    ground = RectangleComponent(
      position: Vector2(0, size.y - groundHeight),
      size: Vector2(size.x, groundHeight),
      paint: Paint()..color = const Color(0xFF3E4F3A),
    );

    mascotte = SpriteComponent(
      sprite: await loadSprite(_skinAssetName),
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
    )..priority = 15;

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

    if (gameOver) {
      if (_impactEffect > 0) {
        _impactEffect -= dt;

        final shake =
            ((_impactEffect * 55).floor().isEven)
                ? 1.0
                : -1.0;

        mascotte.angle = 0.05 * shake;
        obstacle.angle = -0.035 * shake;
      } else {
        mascotte.angle = 0;
        obstacle.angle = 0;
      }

      return;
    }

    _runAnimationTime += dt;

    distance += 18 * dt;

    final difficulty =
        (distance / 1800).clamp(0.0, 1.0).toDouble();

    worldSpeed =
        (startSpeed + distance * 0.38 + difficulty * 55)
            .clamp(startSpeed, maxSpeed)
            .toDouble();

    backdrop.scrollSpeed = worldSpeed * 0.15;


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

      ball.angle += dt * (3.5 + worldSpeed / 140);

      if (ball.position.x + ball.radius < 0) {
        _respawnBall();
      }
    }

    verticalSpeed += gravity * dt;
    mascotte.position.y += verticalSpeed * dt;

    final groundY =
        size.y - groundHeight - mascotte.size.y;

    final wasInAir = !onGround;

    if (mascotte.position.y >= groundY) {
      mascotte.position.y = groundY;
      verticalSpeed = 0;
      onGround = true;

      if (wasInAir) {
        _landingEffect = 0.16;
      }
    }

    if (onGround) {
      final runPhase =
          ((_runAnimationTime * (7 + worldSpeed / 80)).floor())
                  .isEven
              ? 1.0
              : -1.0;

      if (_landingEffect > 0) {
        _landingEffect -= dt;

        mascotte.scale = Vector2(
          1.06,
          0.92,
        );
        mascotte.angle = 0;
      } else {
        mascotte.scale = Vector2(
          1.0,
          1.0 + (runPhase * 0.025),
        );
        mascotte.angle = runPhase * 0.012;
      }
    } else {
      mascotte.scale = Vector2(
        1.0,
        0.96,
      );

      mascotte.angle =
          verticalSpeed < 0
              ? -0.06
              : 0.045;
    }

    if (_hasObstacleCollision()) {
      _triggerGameOver();
      return;
    }

    if (ballActive && _hasBallCollision()) {
      ballsCollected++;
      ballText.text = '⚽  $ballsCollected';

      _playSfx(
        'mascotte_ball.wav',
        volume: 0.55,
      );

      _spawnBallParticles();

      add(
        FloatingScoreText(
          position: Vector2(
            ball.position.x,
            ball.position.y - 24,
          ),
          text: '+50',
        ),
      );

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

    final difficulty =
        (distance / 1800).clamp(0.0, 1.0).toDouble();

    final minGap = 170 - (difficulty * 70);
    final randomGap = 260 - (difficulty * 120);
    final extraGap = minGap + random.nextDouble() * randomGap;

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

    ball.angle = 0;
    ballActive = true;
  }

  void _spawnBallParticles() {
    const colors = [
      Colors.white,
      Color(0xFFE91E63),
      Color(0xFFFFD54F),
    ];

    for (int i = 0; i < 10; i++) {
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
    _impactEffect = 0.28;

    mascotte.scale = Vector2.all(1.0);

    _playSfx(
      'mascotte_collision.wav',
      volume: 0.65,
    );

    _saveBestDistance();

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

  Future<void> _saveBestDistance() async {
    final currentDistance = distance.floor();
    final currentScore = score;

    final prefs = await SharedPreferences.getInstance();
    final previousBest = prefs.getInt(bestDistanceKey) ?? 0;

    if (currentDistance > previousBest) {
      await prefs.setInt(
        bestDistanceKey,
        currentDistance,
      );

      await _playSfx(
        'mascotte_record.wav',
        volume: 0.75,
      );

      await _saveCommunityRecord(
        distance: currentDistance,
        score: currentScore,
      );
    }

    for (final milestone in distanceMilestones) {
      if (currentDistance >= milestone) {
        await prefs.setBool(
          'mascotte_run_milestone_$milestone',
          true,
        );
      }
    }
  }

  Future<void> _saveCommunityRecord({
    required int distance,
    required int score,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) return;

      final firestore = FirebaseFirestore.instance;

      final profile =
          await firestore.collection('users').doc(user.uid).get();

      final profileData = profile.data();

      final savedPseudo =
          (profileData?['pseudo'] as String?)?.trim();

      final pseudo =
          savedPseudo != null && savedPseudo.isNotEmpty
              ? savedPseudo
              : (user.displayName?.trim().isNotEmpty == true
                  ? user.displayName!.trim()
                  : 'Membre Twiix');

      final recordRef = firestore
          .collection('mascotte_run_scores')
          .doc(user.uid);

      await firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(recordRef);
        final data = snapshot.data();

        final previousDistance =
            (data?['bestDistance'] as num?)?.toInt() ?? 0;

        if (distance <= previousDistance) {
          return;
        }

        transaction.set(
          recordRef,
          {
            'uid': user.uid,
            'pseudo': pseudo,
            'bestDistance': distance,
            'bestScore': score,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      });
    } catch (e) {
      debugPrint(
        'Mascotte Run: sauvegarde classement impossible: $e',
      );
    }
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

    _runAnimationTime = 0;
    _landingEffect = 0;
    _impactEffect = 0;

    mascotte.scale = Vector2.all(1.0);
    mascotte.angle = 0;
    obstacle.angle = 0;
    ball.angle = 0;

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

      _playSfx(
        'mascotte_jump.wav',
        volume: 0.45,
      );
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
