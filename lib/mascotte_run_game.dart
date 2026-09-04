import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

class MascotteRunGame extends FlameGame with TapCallbacks {
  static const double groundHeight = 90;
  static const double gravity = 1500;
  static const double jumpForce = -620;

  late final RectangleComponent ground;
  late final RectangleComponent mascotte;

  double verticalSpeed = 0;
  bool onGround = true;

  @override
  Color backgroundColor() => const Color(0xFF09090D);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    ground = RectangleComponent(
      position: Vector2(0, size.y - groundHeight),
      size: Vector2(size.x, groundHeight),
      paint: Paint()..color = const Color(0xFF19191F),
    );

    mascotte = RectangleComponent(
      position: Vector2(70, size.y - groundHeight - 55),
      size: Vector2(55, 55),
      paint: Paint()..color = const Color(0xFFFF2C7D),
    );

    add(ground);
    add(mascotte);
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

    ground
      ..position = Vector2(0, newSize.y - groundHeight)
      ..size = Vector2(newSize.x, groundHeight);

    if (onGround) {
      mascotte.position.y =
          newSize.y - groundHeight - mascotte.size.y;
    }
  }
}
