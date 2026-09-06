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

class RoadTripBackdrop extends PositionComponent {
  late final SpriteComponent background1;
  late final SpriteComponent background2;
  late final SpriteComponent transition1;
  late final SpriteComponent transition2;

  late final Map<String, Sprite> _sprites;

  final Images gameImages;

  double scrollSpeed = 0;

  String _scene = 'marseille_vieux_port';
  String? _transitionScene;

  bool _transitioning = false;
  double _transitionTimer = 0;

  static const double _transitionDuration = 1.25;
  static const double _sceneRatio = 1774 / 887;

  RoadTripBackdrop({
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

    _sprites = {
      'marseille_vieux_port': Sprite(
        await gameImages.load(
          'mascotte_run_marseille_vieux_port.png',
        ),
      ),
      'marseille_velodrome': Sprite(
        await gameImages.load(
          'mascotte_run_marseille_velodrome.png',
        ),
      ),
      'marseille_calanques': Sprite(
        await gameImages.load(
          'mascotte_run_marseille_calanques.png',
        ),
      ),
      'grenoble_bastille': Sprite(
        await gameImages.load(
          'mascotte_run_grenoble_bastille.png',
        ),
      ),
      'grenoble_quais': Sprite(
        await gameImages.load(
          'mascotte_run_grenoble_quais.png',
        ),
      ),
      'grenoble_bulles': Sprite(
        await gameImages.load(
          'mascotte_run_grenoble_bulles.png',
        ),
      ),
      'paris_eiffel': Sprite(
        await gameImages.load(
          'mascotte_run_paris_eiffel.png',
        ),
      ),
      'paris_notre_dame': Sprite(
        await gameImages.load(
          'mascotte_run_paris_notre_dame.png',
        ),
      ),
      'paris_parc_des_princes': Sprite(
        await gameImages.load(
          'mascotte_run_paris_parc_des_princes.png',
        ),
      ),
    };

    final initialSprite = _sprites[_scene]!;

    background1 = SpriteComponent(
      sprite: initialSprite,
      position: Vector2.zero(),
    );

    background2 = SpriteComponent(
      sprite: initialSprite,
      position: Vector2.zero(),
    );

    transition1 = SpriteComponent(
      sprite: initialSprite,
      position: Vector2.zero(),
    );

    transition2 = SpriteComponent(
      sprite: initialSprite,
      position: Vector2.zero(),
    );

    _setOpacity(transition1, 0);
    _setOpacity(transition2, 0);

    addAll([
      background1,
      background2,
      transition1,
      transition2,
    ]);

    _fitBackground(size);
  }

  void _setOpacity(
    SpriteComponent component,
    double opacity,
  ) {
    final alpha =
        (opacity.clamp(0.0, 1.0) * 255).round();

    component.paint.color = Color.fromARGB(
      alpha,
      255,
      255,
      255,
    );
  }

  void setScene(String scene) {
    if (!_sprites.containsKey(scene)) return;

    if (scene == _scene) return;

    if (_transitioning &&
        scene == _transitionScene) {
      return;
    }

    final newSprite = _sprites[scene]!;

    transition1
      ..sprite = newSprite
      ..position = background1.position.clone();

    transition2
      ..sprite = newSprite
      ..position = background2.position.clone();

    transition1.size = background1.size.clone();
    transition2.size = background2.size.clone();

    _setOpacity(transition1, 0);
    _setOpacity(transition2, 0);

    _transitionScene = scene;
    _transitionTimer = 0;
    _transitioning = true;
  }

  void _completeTransition() {
    final nextScene = _transitionScene;

    if (nextScene == null) return;

    final sprite = _sprites[nextScene]!;

    background1
      ..sprite = sprite
      ..position = transition1.position.clone()
      ..size = transition1.size.clone();

    background2
      ..sprite = sprite
      ..position = transition2.position.clone()
      ..size = transition2.size.clone();

    _setOpacity(background1, 1);
    _setOpacity(background2, 1);

    _setOpacity(transition1, 0);
    _setOpacity(transition2, 0);

    _scene = nextScene;
    _transitionScene = null;
    _transitioning = false;
    _transitionTimer = 0;
  }

  void _fitBackground(Vector2 targetSize) {
    final fittedHeight = targetSize.y;
    final fittedWidth =
        fittedHeight * _sceneRatio;

    background1
      ..size = Vector2(
        fittedWidth,
        fittedHeight,
      )
      ..position = Vector2(0, 0);

    background2
      ..size = Vector2(
        fittedWidth,
        fittedHeight,
      )
      ..position = Vector2(
        fittedWidth,
        0,
      );

    transition1
      ..size = Vector2(
        fittedWidth,
        fittedHeight,
      )
      ..position =
          background1.position.clone();

    transition2
      ..size = Vector2(
        fittedWidth,
        fittedHeight,
      )
      ..position =
          background2.position.clone();
  }

  void _scrollPair(
    SpriteComponent first,
    SpriteComponent second,
    double movement,
  ) {
    first.position.x -= movement;
    second.position.x -= movement;

    final width = first.size.x;

    if (first.position.x + width <= 0) {
      first.position.x =
          second.position.x + width;
    }

    if (second.position.x + width <= 0) {
      second.position.x =
          first.position.x + width;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (scrollSpeed > 0) {
      final movement = scrollSpeed * dt;

      _scrollPair(
        background1,
        background2,
        movement,
      );

      if (_transitioning) {
        _scrollPair(
          transition1,
          transition2,
          movement,
        );
      }
    }

    if (!_transitioning) return;

    _transitionTimer += dt;

    final progress =
        (_transitionTimer / _transitionDuration)
            .clamp(0.0, 1.0)
            .toDouble();

    // Fondu croisé :
    // l'ancien panorama disparaît pendant
    // que le nouveau apparaît.
    _setOpacity(
      background1,
      1 - progress,
    );
    _setOpacity(
      background2,
      1 - progress,
    );

    _setOpacity(
      transition1,
      progress,
    );
    _setOpacity(
      transition2,
      progress,
    );

    if (progress >= 1) {
      _completeTransition();
    }
  }

  @override
  void onGameResize(Vector2 newSize) {
    super.onGameResize(newSize);

    size = Vector2(
      newSize.x,
      newSize.y,
    );

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

class RunRainDrop extends RectangleComponent {
  final double fallSpeed;

  RunRainDrop({
    required Vector2 position,
    required this.fallSpeed,
  }) : super(
          position: position,
          size: Vector2(2, 15),
          priority: 45,
          paint: Paint()
            ..color = const Color(0xAABFE7FF),
        ) {
    angle = -0.20;
  }

  @override
  void update(double dt) {
    super.update(dt);

    position.y += fallSpeed * dt;
    position.x -= fallSpeed * 0.16 * dt;

    if (position.y > 1200 || position.x < -40) {
      removeFromParent();
    }
  }
}

class RunAtmosphereOverlay extends PositionComponent {
  double opacity = 0;
  Color color = Colors.transparent;

  RunAtmosphereOverlay({
    required Vector2 size,
  }) : super(
          size: size,
          priority: 40,
        );

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    if (opacity <= 0) return;

    canvas.drawRect(
      Rect.fromLTWH(
        0,
        0,
        size.x,
        size.y,
      ),
      Paint()
        ..color = color.withValues(
          alpha: opacity.clamp(0.0, 1.0),
        ),
    );
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

  late final RoadTripBackdrop backdrop;
  late final RectangleComponent ground;
  late final SpriteComponent mascotte;
  late final TextComponent distanceText;
  late final TextComponent ballText;
  late final PixelObstacle obstacle;
  late final PixelFootball ball;
  late final RunAtmosphereOverlay atmosphereOverlay;

  final List<RectangleComponent> groundMarks = [];

  double distance = 0;
  double worldSpeed = startSpeed;
  double verticalSpeed = 0;

  double _runAnimationTime = 0;
  double _landingEffect = 0;
  double _impactEffect = 0;
  double _eventParticleTimer = 0;
  double _rainParticleTimer = 0;

  final Set<int> _triggeredEvents = {};

  double _nextTwiixEventDistance = 650;
  double _zinBoostTimer = 0;
  double _ballRainTimer = 0;
  double _twiixModeTimer = 0;
  double _twiixVisualTimer = 0;
  double _twiixVisualDuration = 0;
  double _modeBonusDistance = 0;

  int _twiixEventCount = 0;
  int _extraBallScore = 0;
  int _visibleTwiixEvent = 0;

  bool _startIntroActive = false;
  double _startIntroTimer = 0;
  TextComponent? _startIntroText;


  bool _modeTwiixTriggered = false;

  late final SpriteComponent twiixGauche;
  late final SpriteComponent twiixDroit;

  bool get _twiixInvincible =>
      _zinBoostTimer > 0 || _twiixModeTimer > 0;

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

  int get score =>
      distance.floor() +
      (ballsCollected * 50) +
      _extraBallScore +
      _modeBonusDistance.floor();

  @override
  Color backgroundColor() => const Color(0xFF69B9E8);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    backdrop = RoadTripBackdrop(
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

    final twiixImage =
        await images.load('mascotte_run_twiix.png');

    final halfTwiixWidth =
        twiixImage.width.toDouble() / 2;

    twiixGauche = SpriteComponent(
      sprite: Sprite(
        twiixImage,
        srcPosition: Vector2.zero(),
        srcSize: Vector2(
          halfTwiixWidth,
          twiixImage.height.toDouble(),
        ),
      ),
      position: Vector2(-500, size.y - groundHeight),
      size: Vector2(112, 150),
      anchor: Anchor.bottomCenter,
      priority: 42,
    );

    twiixDroit = SpriteComponent(
      sprite: Sprite(
        twiixImage,
        srcPosition: Vector2(
          halfTwiixWidth,
          0,
        ),
        srcSize: Vector2(
          halfTwiixWidth,
          twiixImage.height.toDouble(),
        ),
      ),
      position: Vector2(-500, size.y - groundHeight),
      size: Vector2(112, 150),
      anchor: Anchor.bottomCenter,
      priority: 42,
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

    atmosphereOverlay = RunAtmosphereOverlay(
      size: Vector2(size.x, size.y),
    );

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
      twiixGauche,
      twiixDroit,
      obstacle,
      ball,
      atmosphereOverlay,
      distanceText,
      ballText,
    ]);

    _createGroundMarks();
    _startRunIntro();
  }

  void _startRunIntro() {
    _startIntroText?.removeFromParent();

    _startIntroActive = true;
    _startIntroTimer = 0;

    backdrop.scrollSpeed = 0;

    final twiixY = size.y - groundHeight + 4;

    twiixGauche
      ..position = Vector2(-90, twiixY)
      ..scale = Vector2.all(1.0);

    twiixDroit
      ..position = Vector2(size.x + 90, twiixY)
      ..scale = Vector2.all(1.0);

    atmosphereOverlay
      ..color = Colors.transparent
      ..opacity = 0;

    _startIntroText = TextComponent(
      text: '3',
      position: Vector2(size.x / 2, size.y * 0.24),
      anchor: Anchor.center,
      priority: 150,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 64,
          fontWeight: FontWeight.w900,
          shadows: [
            Shadow(
              color: Color(0xFFFF4081),
              blurRadius: 18,
            ),
            Shadow(
              color: Colors.black,
              blurRadius: 8,
              offset: Offset(2, 3),
            ),
          ],
        ),
      ),
    );

    add(_startIntroText!);
  }

  void _updateStartIntro(double dt) {
    _startIntroTimer += dt;

    // Le décor reste totalement figé pendant le compte à rebours.
    backdrop.scrollSpeed = 0;

    final twiixY = size.y - groundHeight + 4;

    // --------------------------------------------------------
    // 3 : Twiix Gauche entre
    // 0.00 -> 0.75 s
    // --------------------------------------------------------
    if (_startIntroTimer < 0.75) {
      _startIntroText?.text = '3';

      final t =
          (_startIntroTimer / 0.75).clamp(0.0, 1.0).toDouble();

      twiixGauche.position = Vector2(
        -90 + ((size.x * 0.32) + 90) * t,
        twiixY,
      );

      twiixDroit.position = Vector2(
        size.x + 90,
        twiixY,
      );

      final pulse = 1.0 + (t < 0.5 ? t : 1.0 - t) * 0.35;
      _startIntroText?.scale = Vector2.all(pulse);

      return;
    }

    // --------------------------------------------------------
    // 2 : Twiix Droit entre
    // 0.75 -> 1.50 s
    // --------------------------------------------------------
    if (_startIntroTimer < 1.50) {
      _startIntroText?.text = '2';

      final t =
          ((_startIntroTimer - 0.75) / 0.75)
              .clamp(0.0, 1.0)
              .toDouble();

      twiixGauche.position = Vector2(
        size.x * 0.32,
        twiixY,
      );

      twiixDroit.position = Vector2(
        size.x + 90 -
            ((size.x + 90) - (size.x * 0.68)) * t,
        twiixY,
      );

      final pulse = 1.0 + (t < 0.5 ? t : 1.0 - t) * 0.35;
      _startIntroText?.scale = Vector2.all(pulse);

      return;
    }

    // --------------------------------------------------------
    // ZIN ! : les deux Twiix se rejoignent
    // 1.50 -> 2.45 s
    // --------------------------------------------------------
    if (_startIntroTimer < 2.45) {
      _startIntroText?.text = 'ZIN !';

      final t =
          ((_startIntroTimer - 1.50) / 0.95)
              .clamp(0.0, 1.0)
              .toDouble();

      twiixGauche.position = Vector2(
        (size.x * 0.32) +
            ((size.x * 0.43) - (size.x * 0.32)) * t,
        twiixY,
      );

      twiixDroit.position = Vector2(
        (size.x * 0.68) -
            ((size.x * 0.68) - (size.x * 0.57)) * t,
        twiixY,
      );

      final characterScale =
          1.0 + (t < 0.55 ? t : 1.0 - t) * 0.22;

      twiixGauche.scale = Vector2.all(characterScale);
      twiixDroit.scale = Vector2.all(characterScale);

      final textPulse =
          1.15 + (t < 0.5 ? t : 1.0 - t) * 0.65;

      _startIntroText?.scale = Vector2.all(textPulse);

      // Flash rose au moment où ils se rejoignent.
      final flashStrength =
          (1.0 - ((t - 0.55).abs() * 4.0))
              .clamp(0.0, 1.0)
              .toDouble();

      atmosphereOverlay
        ..color = const Color(0xFFFF4081)
        ..opacity = 0.30 * flashStrength;

      return;
    }

    // --------------------------------------------------------
    // GO ! : les Twiix repartent
    // 2.45 -> 3.10 s
    // --------------------------------------------------------
    if (_startIntroTimer < 3.10) {
      _startIntroText?.text = 'GO !';

      atmosphereOverlay
        ..color = Colors.transparent
        ..opacity = 0;

      final t =
          ((_startIntroTimer - 2.45) / 0.65)
              .clamp(0.0, 1.0)
              .toDouble();

      twiixGauche.position = Vector2(
        (size.x * 0.43) +
            (-110 - (size.x * 0.43)) * t,
        twiixY,
      );

      twiixDroit.position = Vector2(
        (size.x * 0.57) +
            ((size.x + 110) - (size.x * 0.57)) * t,
        twiixY,
      );

      twiixGauche.scale = Vector2.all(1.0);
      twiixDroit.scale = Vector2.all(1.0);

      _startIntroText?.scale = Vector2.all(1.15);

      return;
    }

    // --------------------------------------------------------
    // FIN : démarrage réel de la Run
    // --------------------------------------------------------
    _startIntroActive = false;
    _startIntroTimer = 0;

    _startIntroText?.removeFromParent();
    _startIntroText = null;

    atmosphereOverlay
      ..color = Colors.transparent
      ..opacity = 0;

    _hideTwiix();

    backdrop.scrollSpeed = 0;
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

    if (_startIntroActive) {
      _updateStartIntro(dt);
      return;
    }

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

    final distanceStep = 18 * dt;

    distance += distanceStep *
        (_zinBoostTimer > 0 ? 1.35 : 1.0);

    if (_twiixModeTimer > 0) {
      _modeBonusDistance += distanceStep;
    }

    _updateTwiixEvents(dt);

    final difficulty =
        (distance / 1800).clamp(0.0, 1.0).toDouble();

    worldSpeed =
        (startSpeed + distance * 0.38 + difficulty * 55)
            .clamp(startSpeed, maxSpeed)
            .toDouble();

    final effectiveWorldSpeed =
        worldSpeed * (_zinBoostTimer > 0 ? 1.22 : 1.0);

    backdrop.scrollSpeed = effectiveWorldSpeed * 0.15;

    _updateRunEvents(dt);

    distanceText.text = 'DISTANCE  ${distance.floor()} m';

    for (final mark in groundMarks) {
      mark.position.x -= effectiveWorldSpeed * dt;

      if (mark.position.x + mark.size.x < 0) {
        final rightmost = groundMarks
            .map((m) => m.position.x)
            .reduce((a, b) => a > b ? a : b);

        mark.position.x = rightmost + 76;
      }
    }

    obstacle.position.x -= effectiveWorldSpeed * dt;

    if (obstacle.position.x + obstacle.size.x < 0) {
      _respawnObstacle();
    }

    if (ballActive) {
      ball.position.x -= effectiveWorldSpeed * dt;

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
      if (_twiixInvincible) {
        _respawnObstacle();

        _impactEffect = 0.10;

        add(
          FloatingScoreText(
            position: Vector2(
              mascotte.position.x + 60,
              mascotte.position.y - 8,
            ),
            text: 'ZIN !',
          ),
        );

        for (int i = 0; i < 8; i++) {
          add(
            CollectParticle(
              position: Vector2(
                mascotte.position.x +
                    random.nextDouble() * 80,
                mascotte.position.y +
                    random.nextDouble() * 50,
              ),
              color: const Color(0xFFFF4081),
            )..priority = 40,
          );
        }
      } else {
        _triggerGameOver();
        return;
      }
    }

    if (ballActive && _hasBallCollision()) {
      ballsCollected++;
      ballText.text = '⚽  $ballsCollected';

      int gainedPoints = 50;

      if (_ballRainTimer > 0) {
        gainedPoints += 50;
      }

      if (_twiixModeTimer > 0) {
        gainedPoints *= 2;
      }

      _extraBallScore += gainedPoints - 50;

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
          text: '+$gainedPoints',
        ),
      );

      ballActive = false;
      ball.position.x = size.x + 1000;

      _respawnBall();
    }
  }

  void _updateTwiixEvents(double dt) {
    if (_zinBoostTimer > 0) {
      _zinBoostTimer -= dt;
    }

    if (_ballRainTimer > 0) {
      _ballRainTimer -= dt;
    }

    if (_twiixModeTimer > 0) {
      _twiixModeTimer -= dt;
    }

    if (_twiixVisualTimer > 0) {
      _twiixVisualTimer -= dt;

      final elapsed =
          _twiixVisualDuration - _twiixVisualTimer;

      final enterProgress =
          (elapsed / 0.55).clamp(0.0, 1.0).toDouble();

      final exitProgress =
          ((_twiixVisualTimer < 0.55)
                  ? (1.0 - _twiixVisualTimer / 0.55)
                  : 0.0)
              .clamp(0.0, 1.0)
              .toDouble();

      final smoothEnter =
          1.0 - (1.0 - enterProgress) * (1.0 - enterProgress);

      final bounce =
          ((_runAnimationTime * 7).floor().isEven)
              ? 0.0
              : 4.0;

      final baseY = size.y - groundHeight + bounce;

      double slideOffset;

      if (exitProgress > 0) {
        slideOffset = exitProgress * 190;
      } else {
        slideOffset = (1.0 - smoothEnter) * 190;
      }

      final pop =
          enterProgress < 1.0
              ? 0.88 + 0.18 * smoothEnter
              : 1.0;

      if (_visibleTwiixEvent == 1) {
        twiixGauche.position = Vector2(
          size.x - 78 + slideOffset,
          baseY,
        );

        twiixGauche.scale = Vector2.all(pop);
      } else if (_visibleTwiixEvent == 2) {
        twiixDroit.position = Vector2(
          size.x - 78 + slideOffset,
          baseY,
        );

        twiixDroit.scale = Vector2.all(pop);
      } else if (_visibleTwiixEvent == 3) {
        twiixGauche.position = Vector2(
          size.x - 142 + slideOffset,
          baseY,
        );

        twiixDroit.position = Vector2(
          size.x - 54 + slideOffset,
          baseY,
        );

        twiixGauche.scale = Vector2.all(pop);
        twiixDroit.scale = Vector2.all(pop);
      }
    } else if (_visibleTwiixEvent != 0) {
      _hideTwiix();
    }

    if (distance >= _nextTwiixEventDistance) {
      _triggerNextTwiixEvent();
    }
  }

  void _triggerNextTwiixEvent() {
    if (_twiixEventCount == 0) {
      _activateTwiixGauche();
    } else if (_twiixEventCount == 1) {
      _activateTwiixDroit();
    } else if (_twiixEventCount == 2) {
      _activateModeTwiix();
    } else {
      final roll = random.nextInt(5);

      if (roll <= 1) {
        _activateTwiixGauche();
      } else if (roll <= 3) {
        _activateTwiixDroit();
      } else {
        _activateModeTwiix();
      }
    }

    _twiixEventCount++;

    final extraDistance =
        _twiixEventCount <= 3
            ? 850.0
            : 900.0 + random.nextDouble() * 500;

    _nextTwiixEventDistance =
        distance + extraDistance;
  }

  void _activateTwiixGauche() {
    _visibleTwiixEvent = 1;
    _twiixVisualTimer = 3.2;
    _twiixVisualDuration = 3.2;
    _zinBoostTimer = 6.0;

    _showTwiixBanner(
      'TWIIX GAUCHE',
      'BOOST ZIN !',
      const Color(0xFF42A5F5),
    );

    _spawnTwiixParticles(
      const Color(0xFF42A5F5),
    );
  }

  void _activateTwiixDroit() {
    _visibleTwiixEvent = 2;
    _twiixVisualTimer = 3.2;
    _twiixVisualDuration = 3.2;
    _ballRainTimer = 8.0;

    _showTwiixBanner(
      'TWIIX DROIT',
      'PLUIE DE BALLONS !',
      const Color(0xFFE53935),
    );

    _spawnTwiixParticles(
      const Color(0xFFE53935),
    );

    _respawnBall();
  }

  void _activateModeTwiix() {
    _modeTwiixTriggered = true;

    _visibleTwiixEvent = 3;
    _twiixVisualTimer = 4.0;
    _twiixVisualDuration = 4.0;
    _twiixModeTimer = 10.0;

    if (_zinBoostTimer < 7.0) {
      _zinBoostTimer = 7.0;
    }

    if (_ballRainTimer < 10.0) {
      _ballRainTimer = 10.0;
    }

    _showTwiixBanner(
      'MODE TWIIX ×2',
      '3, 2, ZIN !',
      const Color(0xFFFFD700),
    );

    _spawnTwiixParticles(
      const Color(0xFFFFD700),
      count: 36,
    );

    atmosphereOverlay
      ..color = const Color(0xFFFFD54F)
      ..opacity = 0.20;

    Future<void>.delayed(
      const Duration(milliseconds: 220),
      () {
        if (!gameOver) {
          atmosphereOverlay.opacity = 0.08;
        }
      },
    );

    _respawnBall();
  }

  void _hideTwiix() {
    _visibleTwiixEvent = 0;

    twiixGauche.position.x = -500;
    twiixDroit.position.x = -500;

    twiixGauche.scale = Vector2.all(1.0);
    twiixDroit.scale = Vector2.all(1.0);
  }

  void _showTwiixBanner(
    String title,
    String subtitle,
    Color color,
  ) {
    final titleComponent = TextComponent(
      text: title,
      position: Vector2(
        size.x / 2,
        size.y * 0.20,
      ),
      anchor: Anchor.center,
      priority: 110,
      textRenderer: TextPaint(
        style: TextStyle(
          color: color,
          fontSize: 28,
          fontWeight: FontWeight.w900,
          shadows: const [
            Shadow(
              color: Colors.black,
              blurRadius: 8,
              offset: Offset(2, 3),
            ),
          ],
        ),
      ),
    );

    final subtitleComponent = TextComponent(
      text: subtitle,
      position: Vector2(
        size.x / 2,
        size.y * 0.27,
      ),
      anchor: Anchor.center,
      priority: 110,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w900,
          shadows: [
            Shadow(
              color: Colors.black,
              blurRadius: 7,
              offset: Offset(1, 2),
            ),
          ],
        ),
      ),
    );

    addAll([
      titleComponent,
      subtitleComponent,
    ]);

    Future<void>.delayed(
      const Duration(milliseconds: 2200),
      () {
        if (titleComponent.isMounted) {
          titleComponent.removeFromParent();
        }

        if (subtitleComponent.isMounted) {
          subtitleComponent.removeFromParent();
        }
      },
    );
  }

  void _spawnTwiixParticles(
    Color color, {
    int count = 16,
  }) {
    for (int i = 0; i < count; i++) {
      add(
        CollectParticle(
          position: Vector2(
            size.x * 0.20 +
                random.nextDouble() * size.x * 0.75,
            size.y * 0.15 +
                random.nextDouble() * size.y * 0.55,
          ),
          color: color,
        )..priority = 100,
      );
    }
  }

  void _updateRunEvents(double dt) {
    final meters = distance.floor();

    // Voyage de 5000 m, puis la boucle recommence.
    final roadTripMeters = meters % 5000;

    // --------------------------------------------------------
    // VILLES
    // --------------------------------------------------------

    // 9 panoramas : trois par ville.
    //
    // MARSEILLE
    // 0-500    Vieux-Port
    // 500-1000 Vélodrome
    // 1000-1500 Calanques
    //
    // GRENOBLE
    // 1500-2167 Bastille
    // 2167-2834 Quais
    // 2834-3500 Bulles
    //
    // PARIS
    // 3500-4000 Tour Eiffel
    // 4000-4500 Notre-Dame
    // 4500-5000 Parc des Princes

    if (roadTripMeters < 500) {
      backdrop.setScene(
        'marseille_vieux_port',
      );
    } else if (roadTripMeters < 1000) {
      backdrop.setScene(
        'marseille_velodrome',
      );
    } else if (roadTripMeters < 1500) {
      backdrop.setScene(
        'marseille_calanques',
      );
    } else if (roadTripMeters < 2167) {
      backdrop.setScene(
        'grenoble_bastille',
      );
    } else if (roadTripMeters < 2834) {
      backdrop.setScene(
        'grenoble_quais',
      );
    } else if (roadTripMeters < 3500) {
      backdrop.setScene(
        'grenoble_bulles',
      );
    } else if (roadTripMeters < 4000) {
      backdrop.setScene(
        'paris_eiffel',
      );
    } else if (roadTripMeters < 4500) {
      backdrop.setScene(
        'paris_notre_dame',
      );
    } else {
      backdrop.setScene(
        'paris_parc_des_princes',
      );
    }

    // --------------------------------------------------------
    // EVENEMENTS DE DISTANCE HISTORIQUES
    // --------------------------------------------------------

    if (meters >= 500) {
      _triggerDistanceEvent(
        500,
        'ÇA ACCÉLÈRE !',
        const Color(0xFFFFD54F),
      );
    }

    if (meters >= 1000) {
      _triggerDistanceEvent(
        1000,
        'COUCHER DE SOLEIL',
        const Color(0xFFFFA65A),
      );
    }

    if (meters >= 2000) {
      _triggerDistanceEvent(
        2000,
        'MODE ZIN !',
        const Color(0xFFFF4081),
      );
    }

    if (meters >= 3500) {
      _triggerDistanceEvent(
        3500,
        'PARIS BY NIGHT',
        const Color(0xFF90CAF9),
      );
    }

    if (meters >= 5000) {
      _triggerDistanceEvent(
        5000,
        'KING GNOMI',
        const Color(0xFFFFD700),
      );
    }

    // --------------------------------------------------------
    // JOUR / COUCHER DE SOLEIL / NUIT
    // --------------------------------------------------------

    if (roadTripMeters < 900) {
      atmosphereOverlay
        ..color = Colors.transparent
        ..opacity = 0;
    } else if (roadTripMeters < 1500) {
      final progress =
          ((roadTripMeters - 900) / 600)
              .clamp(0.0, 1.0)
              .toDouble();

      atmosphereOverlay
        ..color = const Color(0xFFFF8A45)
        ..opacity = 0.06 + progress * 0.10;
    } else if (roadTripMeters < 2800) {
      final progress =
          ((roadTripMeters - 1500) / 1300)
              .clamp(0.0, 1.0)
              .toDouble();

      atmosphereOverlay
        ..color = const Color(0xFF607D8B)
        ..opacity = 0.04 + progress * 0.08;
    } else if (roadTripMeters < 3500) {
      final progress =
          ((roadTripMeters - 2800) / 700)
              .clamp(0.0, 1.0)
              .toDouble();

      atmosphereOverlay
        ..color = const Color(0xFF10254A)
        ..opacity = 0.12 + progress * 0.12;
    } else {
      final progress =
          ((roadTripMeters - 3500) / 1500)
              .clamp(0.0, 1.0)
              .toDouble();

      atmosphereOverlay
        ..color = const Color(0xFF07132E)
        ..opacity = 0.16 + progress * 0.10;
    }

    // --------------------------------------------------------
    // VRAIE PLUIE A GRENOBLE
    // --------------------------------------------------------

    final raining =
        roadTripMeters >= 2100 &&
        roadTripMeters < 3000;

    if (raining) {
      _rainParticleTimer -= dt;

      if (_rainParticleTimer <= 0) {
        _rainParticleTimer = 0.045;

        for (int i = 0; i < 3; i++) {
          add(
            RunRainDrop(
              position: Vector2(
                random.nextDouble() * (size.x + 80),
                -30 - random.nextDouble() * 100,
              ),
              fallSpeed:
                  430 + random.nextDouble() * 220,
            ),
          );
        }
      }
    } else {
      _rainParticleTimer = 0;
    }

    // --------------------------------------------------------
    // PARTICULES TWIIX EXISTANTES
    // --------------------------------------------------------

    if (meters >= 2000) {
      _eventParticleTimer -= dt;

      if (_eventParticleTimer <= 0) {
        _eventParticleTimer =
            meters >= 5000 ? 0.08 : 0.22;

        final colors = meters >= 5000
            ? const [
                Color(0xFFFFD700),
                Color(0xFFFF4081),
                Colors.white,
              ]
            : const [
                Color(0xFFFF4081),
                Color(0xFF42A5F5),
                Colors.white,
              ];

        add(
          CollectParticle(
            position: Vector2(
              random.nextDouble() * size.x,
              size.y * 0.35 +
                  random.nextDouble() * size.y * 0.45,
            ),
            color: colors[
                random.nextInt(colors.length)],
          )..priority = 35,
        );
      }
    }
  }

  void _triggerDistanceEvent(
    int milestone,
    String text,
    Color color,
  ) {
    if (_triggeredEvents.contains(milestone)) {
      return;
    }

    _triggeredEvents.add(milestone);

    final banner = TextComponent(
      text: text,
      position: Vector2(
        size.x / 2,
        size.y * 0.22,
      ),
      anchor: Anchor.center,
      priority: 90,
      textRenderer: TextPaint(
        style: TextStyle(
          color: color,
          fontSize: milestone >= 5000 ? 30 : 24,
          fontWeight: FontWeight.w900,
          shadows: const [
            Shadow(
              color: Colors.black,
              blurRadius: 8,
              offset: Offset(2, 3),
            ),
          ],
        ),
      ),
    );

    add(banner);

    Future<void>.delayed(
      const Duration(milliseconds: 1700),
      () {
        if (banner.isMounted) {
          banner.removeFromParent();
        }
      },
    );

    for (int i = 0; i < (milestone >= 5000 ? 24 : 10); i++) {
      add(
        CollectParticle(
          position: Vector2(
            size.x * 0.25 +
                random.nextDouble() * size.x * 0.5,
            size.y * 0.18 +
                random.nextDouble() * size.y * 0.30,
          ),
          color: color,
        )..priority = 89,
      );
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
    final extraGap = _ballRainTimer > 0
        ? 90 + random.nextDouble() * 150
        : 260 + random.nextDouble() * 420;

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

    _finalizeRunSummary();

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
      text:
          '${distance.floor()} m  •  $ballsCollected ballon(s)  •  calcul du record...',
      position: Vector2(size.x / 2, size.y * 0.40),
      anchor: Anchor.center,
      priority: 100,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
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

  Future<void> _finalizeRunSummary() async {
    final currentDistance = distance.floor();
    final currentScore = score;
    final currentBalls = ballsCollected;

    try {
      final prefs = await SharedPreferences.getInstance();
      final previousBest = prefs.getInt(bestDistanceKey) ?? 0;

      // Statistiques de carrière Mascotte Run.
      final careerGames =
          prefs.getInt('mascotte_run_stats_games') ?? 0;
      final careerDistance =
          prefs.getInt('mascotte_run_stats_distance') ?? 0;
      final careerBalls =
          prefs.getInt('mascotte_run_stats_balls') ?? 0;
      final previousBestScore =
          prefs.getInt('mascotte_run_stats_best_score') ?? 0;
      final careerModes =
          prefs.getInt('mascotte_run_stats_twiix_modes') ?? 0;

      await prefs.setInt(
        'mascotte_run_stats_games',
        careerGames + 1,
      );
      await prefs.setInt(
        'mascotte_run_stats_distance',
        careerDistance + currentDistance,
      );
      await prefs.setInt(
        'mascotte_run_stats_balls',
        careerBalls + currentBalls,
      );

      if (currentScore > previousBestScore) {
        await prefs.setInt(
          'mascotte_run_stats_best_score',
          currentScore,
        );
      }

      if (_modeTwiixTriggered) {
        await prefs.setInt(
          'mascotte_run_stats_twiix_modes',
          careerModes + 1,
        );
      }

      final skinStatKey =
          'mascotte_run_stats_skin_$skinId';
      final skinGames = prefs.getInt(skinStatKey) ?? 0;
      await prefs.setInt(skinStatKey, skinGames + 1);

      final isNewRecord = currentDistance > previousBest;
      final bestDistance =
          isNewRecord ? currentDistance : previousBest;

      await _saveBestDistance();

      final runRewardPoints =
          await _claimMascotteRunRewards(currentDistance);

      final challengePoints =
          await _claimMascotteRunChallenges(
        currentDistance: currentDistance,
        currentBalls: currentBalls,
        modeTwiixTriggered: _modeTwiixTriggered,
      );

      final awardedPoints =
          runRewardPoints + challengePoints;

      // Le joueur a peut-être déjà relancé une partie pendant
      // les opérations asynchrones.
      if (!gameOver) return;

      gameOverText?.text =
          isNewRecord ? 'NOUVEAU RECORD !' : 'GAME OVER';

      finalStatsText?.text =
          '$currentDistance m  •  $currentBalls ballon(s)  •  RECORD $bestDistance m';

      if (awardedPoints > 0) {
        finalScoreText?.text =
            'SCORE  $currentScore\n+$awardedPoints TWIIX POINTS';
      } else {
        finalScoreText?.text =
            'SCORE  $currentScore';
      }
    } catch (e) {
      debugPrint(
        'Mascotte Run: finalisation de partie impossible: $e',
      );

      await _saveBestDistance();

      if (!gameOver) return;

      finalStatsText?.text =
          '$currentDistance m  •  $currentBalls ballon(s)';

      finalScoreText?.text =
          'SCORE  $currentScore';
    }
  }

  Future<int> _claimMascotteRunChallenges({
    required int currentDistance,
    required int currentBalls,
    required bool modeTwiixTriggered,
  }) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null || user.isAnonymous) {
      return 0;
    }

    try {
      final firestore = FirebaseFirestore.instance;
      final userRef =
          firestore.collection('users').doc(user.uid);

      return await firestore.runTransaction<int>(
        (transaction) async {
          final userSnapshot =
              await transaction.get(userRef);

          if (!userSnapshot.exists) {
            return 0;
          }

          final userData = userSnapshot.data();

          final playedSkins = <String>{};

          final skinsRaw =
              userData?['mascotteRunSkinsPlayed'];

          if (skinsRaw is List) {
            for (final value in skinsRaw) {
              if (value is String) {
                playedSkins.add(value);
              }
            }
          }

          playedSkins.add(skinId);

          final candidates = <String, Map<String, dynamic>>{};

          if (currentDistance >= 1000) {
            candidates['mascotte_run_1000'] = {
              'type': 'mascotte_run_1000',
              'points': 20,
            };
          }

          if (currentBalls >= 15) {
            candidates['mascotte_run_15_balls'] = {
              'type': 'mascotte_run_15_balls',
              'points': 25,
            };
          }

          if (modeTwiixTriggered) {
            candidates['mascotte_run_mode_twiix'] = {
              'type': 'mascotte_run_mode_twiix',
              'points': 30,
            };
          }

          final hasPack =
              playedSkins.contains('wendy') &&
              playedSkins.contains('swan') &&
              playedSkins.contains('dean');

          if (hasPack) {
            candidates['mascotte_run_pack'] = {
              'type': 'mascotte_run_pack',
              'points': 40,
            };
          }

          if (currentDistance >= 5000) {
            candidates['mascotte_run_5000'] = {
              'type': 'mascotte_run_5000',
              'points': 100,
            };
          }

          final rewardSnapshots =
              <String, DocumentSnapshot<Map<String, dynamic>>>{};

          for (final entry in candidates.entries) {
            final rewardRef = userRef
                .collection('challengeRewards')
                .doc(entry.key);

            rewardSnapshots[entry.key] =
                await transaction.get(rewardRef);
          }

          var totalAwarded = 0;
          final currentPoints =
              (userData?['twiixPoints'] as num?)
                      ?.toInt() ??
                  0;

          for (final entry in candidates.entries) {
            final existing =
                rewardSnapshots[entry.key];

            if (existing?.exists == true) {
              continue;
            }

            final points =
                (entry.value['points'] as num).toInt();

            final rewardRef = userRef
                .collection('challengeRewards')
                .doc(entry.key);

            transaction.set(
              rewardRef,
              {
                'challengeId': entry.key,
                'type': entry.value['type'],
                'points': points,
                'source': 'mascotte_run',
                'awardedAt':
                    FieldValue.serverTimestamp(),
              },
            );

            totalAwarded += points;
          }

          transaction.update(
            userRef,
            {
              'mascotteRunSkinsPlayed':
                  playedSkins.toList(),
              'lastMascotteRunChallengeAt':
                  FieldValue.serverTimestamp(),
              if (totalAwarded > 0)
                'twiixPoints':
                    currentPoints + totalAwarded,
            },
          );

          return totalAwarded;
        },
      );
    } catch (e) {
      debugPrint(
        'Mascotte Run: défis impossibles: $e',
      );

      return 0;
    }
  }

  Future<int> _claimMascotteRunRewards(
    int currentDistance,
  ) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null || user.isAnonymous) {
      return 0;
    }

    const rewards = <int, int>{
      500: 5,
      1000: 10,
      2000: 20,
      3500: 35,
      5000: 50,
    };

    final eligibleMilestones = rewards.keys
        .where((milestone) => currentDistance >= milestone)
        .toList();

    if (eligibleMilestones.isEmpty) {
      return 0;
    }

    try {
      final firestore = FirebaseFirestore.instance;
      final userRef =
          firestore.collection('users').doc(user.uid);

      return await firestore.runTransaction<int>(
        (transaction) async {
          final userSnapshot =
              await transaction.get(userRef);

          if (!userSnapshot.exists) {
            return 0;
          }

          final data = userSnapshot.data();

          final alreadyClaimed = <int>{};

          final claimedRaw =
              data?['mascotteRunRewardMilestones'];

          if (claimedRaw is List) {
            for (final value in claimedRaw) {
              if (value is num) {
                alreadyClaimed.add(value.toInt());
              }
            }
          }

          final newlyClaimed = eligibleMilestones
              .where(
                (milestone) =>
                    !alreadyClaimed.contains(milestone),
              )
              .toList();

          if (newlyClaimed.isEmpty) {
            return 0;
          }

          var awardedPoints = 0;

          for (final milestone in newlyClaimed) {
            awardedPoints += rewards[milestone] ?? 0;
          }

          final currentPoints =
              (data?['twiixPoints'] as num?)?.toInt() ??
                  0;

          transaction.update(
            userRef,
            {
              'twiixPoints':
                  currentPoints + awardedPoints,
              'mascotteRunRewardMilestones':
                  FieldValue.arrayUnion(newlyClaimed),
              'lastMascotteRunRewardAt':
                  FieldValue.serverTimestamp(),
            },
          );

          return awardedPoints;
        },
      );
    } catch (e) {
      debugPrint(
        'Mascotte Run: récompense Twiix Points impossible: $e',
      );

      return 0;
    }
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

    if (skinId == 'wendy' && currentDistance >= 1500) {
      await prefs.setBool(
        'mascotte_run_legend_queen_wendy',
        true,
      );
    }

    if (skinId == 'swan' && currentDistance >= 3000) {
      await prefs.setBool(
        'mascotte_run_legend_swan_fusee',
        true,
      );
    }

    if (skinId == 'dean' && currentDistance >= 5000) {
      await prefs.setBool(
        'mascotte_run_legend_dean_sage',
        true,
      );
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

    _extraBallScore = 0;
    _modeBonusDistance = 0;

    _zinBoostTimer = 0;
    _ballRainTimer = 0;
    _twiixModeTimer = 0;
    _twiixVisualTimer = 0;
    _twiixVisualDuration = 0;

    _twiixEventCount = 0;
    _visibleTwiixEvent = 0;
    _modeTwiixTriggered = false;
    _nextTwiixEventDistance = 650;

    _hideTwiix();
    worldSpeed = startSpeed;
    verticalSpeed = 0;

    _runAnimationTime = 0;
    _landingEffect = 0;
    _impactEffect = 0;
    _eventParticleTimer = 0;
    _triggeredEvents.clear();

    atmosphereOverlay
      ..color = Colors.transparent
      ..opacity = 0;

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

    _startRunIntro();
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (gameOver) {
      _restartGame();
      super.onTapDown(event);
      return;
    }

    if (_startIntroActive) {
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
