import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

class CircularLoadingAnimation extends StatefulWidget {
  const CircularLoadingAnimation({
    required this.outerCircleColor,
    required this.innerCircleColor,
    required this.backgroundColor,
    super.key,
    this.centerWidget,
    this.size = 120.0,
  });
  final Color outerCircleColor;
  final Color innerCircleColor;
  final Color backgroundColor;
  final Widget? centerWidget;
  final double size;

  @override
  State<CircularLoadingAnimation> createState() =>
      _CircularLoadingAnimationState();
}

class _CircularLoadingAnimationState extends State<CircularLoadingAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    unawaited(_controller.repeat());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        shape: BoxShape.circle,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return CustomPaint(
                size: Size(widget.size * 0.8, widget.size * 0.8),
                painter: _LoadingPainter(
                  progress: _controller.value,
                  outerColor: widget.outerCircleColor,
                  innerColor: widget.innerCircleColor,
                ),
              );
            },
          ),
          if (widget.centerWidget != null) widget.centerWidget!,
        ],
      ),
    );
  }
}

class _LoadingPainter extends CustomPainter {
  _LoadingPainter({
    required this.progress,
    required this.outerColor,
    required this.innerColor,
  });
  final double progress;
  final Color outerColor;
  final Color innerColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final strokeWidth = size.width * 0.08;

    final outerRadius = size.width / 2 - strokeWidth / 2;
    final innerRadius = outerRadius - strokeWidth * 1.5;

    final outerPaint = Paint()
      ..color = outerColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final innerPaint = Paint()
      ..color = innerColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final mainAngle = progress * 2 * math.pi;

    // Outer arc
    canvas
      ..drawArc(
        Rect.fromCircle(center: center, radius: outerRadius),
        mainAngle - math.pi / 2,
        1.6 * math.pi,
        false,
        outerPaint,
      )
      // Inner arc
      ..drawArc(
        Rect.fromCircle(center: center, radius: innerRadius),
        mainAngle + math.pi,
        1.2 * math.pi,
        false,
        innerPaint,
      );
  }

  @override
  bool shouldRepaint(_LoadingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.outerColor != outerColor ||
        oldDelegate.innerColor != innerColor;
  }
}
