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

  double verticalSpeed = 0;
  bool onGround = true;

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
      sprite: await loadSprite("mascotte_run_frame.png"),
      position: Vector2(55, size.y - groundHeight - 75),
      size: Vector2(105, 75),
    );

    addAll([
      sky,
      mountainBack,
      mountainFront,
      river,
      quay,
      ground,
      mascotte,
    ]);
  }

  @override
  void update(double dt) {
    super.update(dt);

    verticalSpeed += gravity * dt;
    mascotte.position.y += verticalSpeed * dt;

    final groundY = size.y - groundHeight - mascotte.size.y;

    if (mascotte.position.y >= groundY) {
      mascotte.position.y = groundY;
      verticalSpeed = 0;
      onGround = true;
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
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
      ..position = Vector2(0, newSize.y - groundHeight - 90)
      ..size = Vector2(newSize.x, 90);

    quay
      ..position = Vector2(0, newSize.y - groundHeight - 30)
      ..size = Vector2(newSize.x, 30);

    ground
      ..position = Vector2(0, newSize.y - groundHeight)
      ..size = Vector2(newSize.x, groundHeight);

    if (onGround) {
      mascotte.position.y =
          newSize.y - groundHeight - mascotte.size.y;
    }
  }
}
