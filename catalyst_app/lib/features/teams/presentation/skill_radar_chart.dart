import 'dart:math' as math;
import 'package:flutter/material.dart';

class SkillRadarChart extends StatelessWidget {
  final Map<String, double> skills;
  final Color color;

  const SkillRadarChart({
    super.key,
    required this.skills,
    this.color = Colors.blue,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(200, 200),
      painter: RadarChartPainter(skills, color),
    );
  }
}

class RadarChartPainter extends CustomPainter {
  final Map<String, double> skills;
  final Color color;

  RadarChartPainter(this.skills, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width / 2, size.height / 2) * 0.8;
    final angleStep = (2 * math.pi) / skills.length;

    final axisPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final fillPaint = Paint()
      ..color = color.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Draw background circles
    for (var i = 1; i <= 5; i++) {
      canvas.drawCircle(center, radius * (i / 5), axisPaint);
    }

    // Draw axes and collect points
    final points = <Offset>[];
    final skillList = skills.keys.toList();

    for (var i = 0; i < skillList.length; i++) {
      final angle = angleStep * i - math.pi / 2;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      
      // Draw axis line
      canvas.drawLine(center, Offset(x, y), axisPaint);

      // Label (optional)
      final labelPos = Offset(
        center.dx + (radius + 20) * math.cos(angle),
        center.dy + (radius + 20) * math.sin(angle),
      );
      _drawText(canvas, skillList[i], labelPos);

      // Data point
      final value = skills[skillList[i]] ?? 0.0;
      final px = center.dx + radius * value * math.cos(angle);
      final py = center.dy + radius * value * math.sin(angle);
      points.add(Offset(px, py));
    }

    // Draw the radar shape
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    path.close();

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, strokePaint);

    // Draw points
    for (var p in points) {
      canvas.drawCircle(p, 4, Paint()..color = color);
    }
  }

  void _drawText(Canvas canvas, String text, Offset position) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: const TextStyle(color: Colors.white, fontSize: 10)),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, Offset(position.dx - textPainter.width / 2, position.dy - textPainter.height / 2));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
