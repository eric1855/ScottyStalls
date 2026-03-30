import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'models/restroom.dart';
import 'reader_review_page.dart';

// ---------------------------------------------------------------------------
// Floor-plan layout types
// ---------------------------------------------------------------------------

enum _LayoutType { corridor, lShape, atrium, connected }

_LayoutType _layoutFor(String building) {
  switch (building) {
    case 'Tepper School of Business':
    case 'College of Fine Arts':
      return _LayoutType.lShape;
    case 'Cohon University Center':
    case 'Wean Hall':
    case 'Purnell Center for the Arts':
      return _LayoutType.atrium;
    case 'Gates and Hillman Centers':
      return _LayoutType.connected;
    default:
      return _LayoutType.corridor;
  }
}

// ---------------------------------------------------------------------------
// BuildingMapPage
// ---------------------------------------------------------------------------

class BuildingMapPage extends StatefulWidget {
  const BuildingMapPage(
      {super.key, required this.building, required this.restrooms});

  final String building;
  final List<Restroom> restrooms;

  @override
  State<BuildingMapPage> createState() => _BuildingMapPageState();
}

class _BuildingMapPageState extends State<BuildingMapPage> {
  late List<int> _floors;
  late int _selectedFloor;

  @override
  void initState() {
    super.initState();
    _floors = widget.restrooms.map((r) => r.floor).toSet().toList()..sort();
    _selectedFloor = _floors.first;
  }

  @override
  Widget build(BuildContext context) {
    final floorRestrooms =
        widget.restrooms.where((r) => r.floor == _selectedFloor).toList();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.building,
            style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Floor selector row ─────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(children: [
              Text('SELECT FLOOR',
                  style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF888888),
                      letterSpacing: 0.5)),
              const SizedBox(width: 12),
              // Floor chips
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _floors.map((f) {
                      final selected = f == _selectedFloor;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedFloor = f),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: selected
                                  ? const Color(0xFFC41230)
                                  : const Color(0xFF1A1A1A),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: selected
                                    ? const Color(0xFFC41230)
                                    : const Color(0xFF2A2A2A),
                              ),
                            ),
                            child: Text('${f}F',
                                style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: selected
                                        ? Colors.white
                                        : const Color(0xFF888888))),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 6),
          // ── Legend ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(children: [
              _legendDot(const Color(0xFFC41230), 'Restroom'),
              const SizedBox(width: 14),
              _legendDot(const Color(0xFF3B82F6), 'Elevator'),
              const SizedBox(width: 14),
              _legendDot(const Color(0xFF666666), 'Stairs'),
            ]),
          ),
          const SizedBox(height: 10),

          // ── Floor plan ─────────────────────────────────────
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final height = constraints.maxHeight;

                // Compute restroom positions within the floor plan.
                final positions = _restroomPositions(
                    floorRestrooms.length, widget.building, _selectedFloor);

                return Stack(
                  children: [
                    // Floor plan drawing
                    Positioned.fill(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D0D0D),
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: const Color(0xFF2A2A2A)),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: CustomPaint(
                            painter: _FloorPlanPainter(
                              building: widget.building,
                              floor: _selectedFloor,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Restroom markers
                    ...List.generate(floorRestrooms.length, (i) {
                      final r = floorRestrooms[i];
                      final pos = positions[i];
                      final dx = 16 + (width - 32) * pos.dx;
                      final dy = height * pos.dy;
                      return Positioned(
                        left: dx - 18,
                        top: dy - 18,
                        child: GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ReaderReviewPage(restroom: r),
                            ),
                          ),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: const Color(0xFFC41230),
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFC41230)
                                      .withOpacity(0.4),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: const Icon(Icons.wc,
                                color: Colors.white, size: 18),
                          ),
                        ),
                      );
                    }),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 10),

          // ── Restroom list ──────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('RESTROOMS ON THIS FLOOR',
                style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF888888),
                    letterSpacing: 0.5)),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 120,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: floorRestrooms.length,
              itemBuilder: (context, i) {
                final r = floorRestrooms[i];
                final rColor = r.generalRating >= 4.0
                    ? const Color(0xFF22C55E)
                    : r.generalRating >= 3.0
                        ? const Color(0xFFF59E0B)
                        : const Color(0xFFEF4444);
                return GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ReaderReviewPage(restroom: r),
                    ),
                  ),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF111111),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFFC41230).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(Icons.wc,
                            color: Color(0xFFC41230), size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(r.name,
                                style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white)),
                            Text(
                              r.description.isNotEmpty
                                  ? r.description
                                  : 'Floor ${r.floor}',
                              style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: const Color(0xFF888888)),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: rColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(r.generalRating.toStringAsFixed(1),
                            style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: rColor)),
                      ),
                    ]),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color.withOpacity(0.6),
            borderRadius: BorderRadius.circular(5),
          ),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF666666))),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Compute smart restroom positions within the floor plan (0–1 normalised)
// ---------------------------------------------------------------------------

List<Offset> _restroomPositions(int count, String building, int floor) {
  if (count == 0) return [];
  // Spread restrooms along the main corridor of the building.
  final layout = _layoutFor(building);
  switch (layout) {
    case _LayoutType.corridor:
      // Restrooms along a horizontal corridor at y≈0.48
      return List.generate(count, (i) {
        final x = 0.15 + 0.7 * (i / math.max(count - 1, 1));
        return Offset(x, 0.46 + (i.isEven ? -0.06 : 0.14));
      });
    case _LayoutType.lShape:
      // Along the L: first half on horizontal, rest on vertical leg
      return List.generate(count, (i) {
        if (i < (count + 1) ~/ 2) {
          final x = 0.15 + 0.5 * (i / math.max((count + 1) ~/ 2 - 1, 1));
          return Offset(x, 0.35);
        } else {
          final j = i - (count + 1) ~/ 2;
          final rem = count - (count + 1) ~/ 2;
          final y = 0.45 + 0.35 * (j / math.max(rem - 1, 1));
          return Offset(0.65, y);
        }
      });
    case _LayoutType.atrium:
      // Around a central atrium
      return List.generate(count, (i) {
        final angle = 2 * math.pi * i / count - math.pi / 2;
        return Offset(0.5 + 0.28 * math.cos(angle),
            0.48 + 0.28 * math.sin(angle));
      });
    case _LayoutType.connected:
      // Two blocks side by side
      return List.generate(count, (i) {
        if (i.isEven) {
          return Offset(0.25, 0.3 + 0.4 * (i ~/ 2) / math.max(count ~/ 2, 1));
        } else {
          return Offset(0.75, 0.3 + 0.4 * ((i - 1) ~/ 2) / math.max(count ~/ 2, 1));
        }
      });
  }
}

// ---------------------------------------------------------------------------
// Floor plan CustomPainter
// ---------------------------------------------------------------------------

class _FloorPlanPainter extends CustomPainter {
  _FloorPlanPainter({required this.building, required this.floor});
  final String building;
  final int floor;

  @override
  void paint(Canvas canvas, Size size) {
    final wallPaint = Paint()
      ..color = const Color(0xFF3A3A3A)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final thinWall = Paint()
      ..color = const Color(0xFF2A2A2A)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    final accentPaint = Paint()
      ..color = const Color(0xFF3B82F6).withOpacity(0.25)
      ..style = PaintingStyle.fill;

    final stairPaint = Paint()
      ..color = const Color(0xFF666666).withOpacity(0.2)
      ..style = PaintingStyle.fill;

    final layout = _layoutFor(building);
    // Use a seeded random for consistent room counts per building+floor.
    final rand = math.Random(building.hashCode ^ (floor * 31));

    switch (layout) {
      case _LayoutType.corridor:
        _drawCorridor(canvas, size, wallPaint, thinWall, accentPaint, stairPaint, rand);
      case _LayoutType.lShape:
        _drawLShape(canvas, size, wallPaint, thinWall, accentPaint, stairPaint, rand);
      case _LayoutType.atrium:
        _drawAtrium(canvas, size, wallPaint, thinWall, accentPaint, stairPaint, rand);
      case _LayoutType.connected:
        _drawConnected(canvas, size, wallPaint, thinWall, accentPaint, stairPaint, rand);
    }
  }

  // ── CORRIDOR layout ────────────────────────────────────────────────────
  void _drawCorridor(Canvas canvas, Size size, Paint wall, Paint thin,
      Paint accent, Paint stair, math.Random rand) {
    final p = 24.0; // padding
    final w = size.width - 2 * p;
    final h = size.height - 2 * p;

    // Outer walls
    canvas.drawRect(Rect.fromLTWH(p, p, w, h), wall);

    // Central corridor
    final cy = p + h * 0.44;
    final ch = h * 0.12;
    canvas.drawLine(Offset(p, cy), Offset(p + w, cy), wall);
    canvas.drawLine(Offset(p, cy + ch), Offset(p + w, cy + ch), wall);

    // Rooms above
    final nTop = 4 + rand.nextInt(3);
    for (int i = 1; i < nTop; i++) {
      final x = p + w * i / nTop;
      canvas.drawLine(Offset(x, p), Offset(x, cy), thin);
    }

    // Rooms below
    final nBot = 3 + rand.nextInt(3);
    for (int i = 1; i < nBot; i++) {
      final x = p + w * i / nBot;
      canvas.drawLine(Offset(x, cy + ch), Offset(x, p + h), thin);
    }

    // Elevator
    final eRect = Rect.fromLTWH(p + w * 0.02, cy + 2, ch - 4, ch - 4);
    canvas.drawRect(eRect, accent);
    canvas.drawRect(eRect, thin);

    // Stairs
    final sRect = Rect.fromLTWH(p + w - ch + 2, cy + 2, ch - 4, ch - 4);
    canvas.drawRect(sRect, stair);
    // draw stair lines
    for (int i = 1; i < 4; i++) {
      final sy = sRect.top + sRect.height * i / 4;
      canvas.drawLine(
          Offset(sRect.left, sy), Offset(sRect.right, sy), thin);
    }

    // Room labels (subtle)
    final labelPaint = TextPainter(textDirection: TextDirection.ltr);
    for (int i = 0; i < nTop; i++) {
      final rx = p + w * (i + 0.5) / nTop;
      final ry = p + (cy - p) * 0.5;
      labelPaint
        ..text = TextSpan(
            text: '${floor}${String.fromCharCode(65 + i)}',
            style: const TextStyle(
                color: Color(0xFF2A2A2A), fontSize: 9))
        ..layout();
      labelPaint.paint(
          canvas, Offset(rx - labelPaint.width / 2, ry - labelPaint.height / 2));
    }
  }

  // ── L-SHAPE layout ─────────────────────────────────────────────────────
  void _drawLShape(Canvas canvas, Size size, Paint wall, Paint thin,
      Paint accent, Paint stair, math.Random rand) {
    final p = 24.0;
    final w = size.width - 2 * p;
    final h = size.height - 2 * p;

    // L outline
    final path = Path()
      ..moveTo(p, p)
      ..lineTo(p + w * 0.65, p)
      ..lineTo(p + w * 0.65, p + h * 0.4)
      ..lineTo(p + w, p + h * 0.4)
      ..lineTo(p + w, p + h)
      ..lineTo(p + w * 0.45, p + h)
      ..lineTo(p + w * 0.45, p + h * 0.4)
      ..lineTo(p, p + h * 0.4)
      ..close();
    canvas.drawPath(path, wall);

    // Horizontal corridor
    final hcy = p + h * 0.3;
    final hch = h * 0.1;
    canvas.drawLine(Offset(p, hcy), Offset(p + w * 0.65, hcy), thin);
    canvas.drawLine(Offset(p, hcy + hch), Offset(p + w * 0.45, hcy + hch), thin);

    // Vertical corridor
    final vcx = p + w * 0.55;
    final vcw = w * 0.1;
    canvas.drawLine(Offset(vcx, p + h * 0.4), Offset(vcx, p + h), thin);
    canvas.drawLine(Offset(vcx + vcw, p + h * 0.4), Offset(vcx + vcw, p + h), thin);

    // Rooms in horizontal wing
    final nH = 3 + rand.nextInt(2);
    for (int i = 1; i < nH; i++) {
      final x = p + (w * 0.65) * i / nH;
      canvas.drawLine(Offset(x, p), Offset(x, hcy), thin);
    }

    // Rooms in vertical wing
    final nV = 3 + rand.nextInt(2);
    for (int i = 1; i < nV; i++) {
      final y = p + h * 0.4 + (h * 0.6) * i / nV;
      canvas.drawLine(Offset(vcx + vcw, y), Offset(p + w, y), thin);
    }

    // Elevator
    canvas.drawRect(
        Rect.fromLTWH(vcx + 2, p + h * 0.42, vcw - 4, h * 0.08), accent);

    // Stairs
    final sr = Rect.fromLTWH(p + 4, hcy + 2, w * 0.06, hch - 4);
    canvas.drawRect(sr, stair);
    for (int i = 1; i < 3; i++) {
      canvas.drawLine(Offset(sr.left, sr.top + sr.height * i / 3),
          Offset(sr.right, sr.top + sr.height * i / 3), thin);
    }
  }

  // ── ATRIUM layout ──────────────────────────────────────────────────────
  void _drawAtrium(Canvas canvas, Size size, Paint wall, Paint thin,
      Paint accent, Paint stair, math.Random rand) {
    final p = 24.0;
    final w = size.width - 2 * p;
    final h = size.height - 2 * p;

    // Outer walls
    canvas.drawRect(Rect.fromLTWH(p, p, w, h), wall);

    // Central atrium (open space)
    final ax = p + w * 0.3;
    final ay = p + h * 0.3;
    final aw = w * 0.4;
    final ah = h * 0.4;
    final atriumPaint = Paint()
      ..color = const Color(0xFF1A1A1A)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(ax, ay, aw, ah), const Radius.circular(4)),
        atriumPaint);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(ax, ay, aw, ah), const Radius.circular(4)),
        wall);

    // Rooms around atrium
    // Top wing
    final nTop = 3 + rand.nextInt(2);
    for (int i = 1; i < nTop; i++) {
      final x = p + w * i / nTop;
      canvas.drawLine(Offset(x, p), Offset(x, ay), thin);
    }
    // Bottom wing
    final nBot = 3 + rand.nextInt(2);
    for (int i = 1; i < nBot; i++) {
      final x = p + w * i / nBot;
      canvas.drawLine(Offset(x, ay + ah), Offset(x, p + h), thin);
    }
    // Left wing
    final nLeft = 2 + rand.nextInt(2);
    for (int i = 1; i < nLeft; i++) {
      final y = ay + ah * i / nLeft;
      canvas.drawLine(Offset(p, y), Offset(ax, y), thin);
    }
    // Right wing
    final nRight = 2 + rand.nextInt(2);
    for (int i = 1; i < nRight; i++) {
      final y = ay + ah * i / nRight;
      canvas.drawLine(Offset(ax + aw, y), Offset(p + w, y), thin);
    }

    // Elevator (bottom-left)
    canvas.drawRect(
        Rect.fromLTWH(p + 4, p + h - h * 0.1, w * 0.05, h * 0.06), accent);

    // Stairs (top-right)
    final sr = Rect.fromLTWH(p + w - w * 0.08, p + 4, w * 0.06, h * 0.06);
    canvas.drawRect(sr, stair);
    for (int i = 1; i < 3; i++) {
      canvas.drawLine(Offset(sr.left, sr.top + sr.height * i / 3),
          Offset(sr.right, sr.top + sr.height * i / 3), thin);
    }

    // Atrium label
    final tp = TextPainter(
      text: const TextSpan(
          text: 'ATRIUM',
          style: TextStyle(
              color: Color(0xFF2A2A2A), fontSize: 10, letterSpacing: 2)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas,
        Offset(ax + aw / 2 - tp.width / 2, ay + ah / 2 - tp.height / 2));
  }

  // ── CONNECTED layout (Gates+Hillman style) ─────────────────────────────
  void _drawConnected(Canvas canvas, Size size, Paint wall, Paint thin,
      Paint accent, Paint stair, math.Random rand) {
    final p = 24.0;
    final w = size.width - 2 * p;
    final h = size.height - 2 * p;
    final gap = w * 0.04;
    final bw = (w - gap) / 2;

    // Left block
    canvas.drawRect(Rect.fromLTWH(p, p, bw, h), wall);
    // Right block
    canvas.drawRect(Rect.fromLTWH(p + bw + gap, p, bw, h), wall);

    // Connecting bridge
    final by = p + h * 0.42;
    final bh = h * 0.16;
    canvas.drawRect(Rect.fromLTWH(p + bw, by, gap, bh), wall);

    // Corridors
    final cy = p + h * 0.46;
    final ch = h * 0.08;
    canvas.drawLine(Offset(p, cy), Offset(p + bw, cy), thin);
    canvas.drawLine(Offset(p, cy + ch), Offset(p + bw, cy + ch), thin);
    canvas.drawLine(
        Offset(p + bw + gap, cy), Offset(p + bw + gap + bw, cy), thin);
    canvas.drawLine(Offset(p + bw + gap, cy + ch),
        Offset(p + bw + gap + bw, cy + ch), thin);

    // Rooms — left block
    final nL = 3 + rand.nextInt(2);
    for (int i = 1; i < nL; i++) {
      final x = p + bw * i / nL;
      canvas.drawLine(Offset(x, p), Offset(x, cy), thin);
    }
    final nLb = 2 + rand.nextInt(2);
    for (int i = 1; i < nLb; i++) {
      final x = p + bw * i / nLb;
      canvas.drawLine(Offset(x, cy + ch), Offset(x, p + h), thin);
    }

    // Rooms — right block
    final nR = 3 + rand.nextInt(2);
    for (int i = 1; i < nR; i++) {
      final x = p + bw + gap + bw * i / nR;
      canvas.drawLine(Offset(x, p), Offset(x, cy), thin);
    }
    final nRb = 2 + rand.nextInt(2);
    for (int i = 1; i < nRb; i++) {
      final x = p + bw + gap + bw * i / nRb;
      canvas.drawLine(Offset(x, cy + ch), Offset(x, p + h), thin);
    }

    // Elevator (bridge area)
    canvas.drawRect(
        Rect.fromLTWH(p + bw + 2, by + 2, gap - 4, bh * 0.35), accent);

    // Stairs (right block, top-right)
    final sr = Rect.fromLTWH(
        p + w - w * 0.06, p + 4, w * 0.04, h * 0.06);
    canvas.drawRect(sr, stair);

    // Block labels
    final ltp = TextPainter(
      text: TextSpan(
          text: building.contains('Gates') ? 'GATES' : 'BLOCK A',
          style: const TextStyle(
              color: Color(0xFF2A2A2A), fontSize: 9, letterSpacing: 1)),
      textDirection: TextDirection.ltr,
    )..layout();
    ltp.paint(canvas, Offset(p + bw / 2 - ltp.width / 2, p + h * 0.15));

    final rtp = TextPainter(
      text: TextSpan(
          text: building.contains('Gates') ? 'HILLMAN' : 'BLOCK B',
          style: const TextStyle(
              color: Color(0xFF2A2A2A), fontSize: 9, letterSpacing: 1)),
      textDirection: TextDirection.ltr,
    )..layout();
    rtp.paint(canvas,
        Offset(p + bw + gap + bw / 2 - rtp.width / 2, p + h * 0.15));
  }

  @override
  bool shouldRepaint(covariant _FloorPlanPainter old) =>
      old.building != building || old.floor != floor;
}
