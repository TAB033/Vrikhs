import 'package:flutter/material.dart';
import 'dart:math' as math;

class DyingLeaf {
  final String nodeId;
  Offset position;
  double rotation;
  double scale;
  double opacity;
  double fallSpeed;
  double rotationSpeed;
  Color color;
  final DateTime startTime;
  final Offset startPosition;
  
  DyingLeaf({
    required this.nodeId,
    required this.position,
  }) : 
    rotation = 0,
    scale = 1.0,
    opacity = 1.0,
    fallSpeed = 0.5 + math.Random().nextDouble() * 1.5,
    rotationSpeed = (math.Random().nextDouble() - 0.5) * 0.05,
    color = const Color(0xFF8B4513).withOpacity(0.8),
    startTime = DateTime.now(),
    startPosition = position;

  bool update() {
    final now = DateTime.now();
    final elapsed = now.difference(startTime);
    
    // Update position (falling with slight horizontal movement)
    position = Offset(
      position.dx + math.sin(elapsed.inMilliseconds * 0.003) * 0.5,
      position.dy + fallSpeed,
    );
    
    // Update rotation
    rotation += rotationSpeed;
    
    // Update scale (shrink slightly)
    scale = 1.0 - (elapsed.inMilliseconds / 2000).clamp(0.0, 0.5);
    
    // Update opacity (fade out)
    opacity = 1.0 - (elapsed.inMilliseconds / 1500).clamp(0.0, 1.0);
    
    // Update color (turn brownish)
    final progress = (elapsed.inMilliseconds / 1000).clamp(0.0, 1.0);
    color = Color.lerp(
      const Color(0xFF8B4513).withOpacity(0.8), // Brown
      const Color(0xFF5D4037).withOpacity(0.6), // Darker brown
      progress,
    )!;
    
    // Return true if animation is complete
    return elapsed.inMilliseconds > 2000;
  }
}
