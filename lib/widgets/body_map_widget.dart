import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../db/tables/enums.dart';

// Muscle groups that appear on the front body image.
const _frontMuscles = [
  (MuscleGroup.quads, 'assets/muscles/Front_quads.png'),
  (MuscleGroup.abs, 'assets/muscles/Front_abs.png'),
  (MuscleGroup.chest, 'assets/muscles/Front_chest.png'),
  (MuscleGroup.biceps, 'assets/muscles/Front_biceps.png'),
  (MuscleGroup.forearms, 'assets/muscles/Front_forearms.png'),
  (MuscleGroup.shoulders, 'assets/muscles/Front_shoulders.png'),
  (MuscleGroup.tibialis, 'assets/muscles/Front_tibialis.png'),
];

// Muscle groups that appear on the back body image.
const _backMuscles = [
  (MuscleGroup.back, 'assets/muscles/Back_back.png'),
  (MuscleGroup.hamstrings, 'assets/muscles/Back_hamstrings.png'),
  (MuscleGroup.glutes, 'assets/muscles/Back_glutes.png'),
  (MuscleGroup.calves, 'assets/muscles/Back_calves.png'),
  (MuscleGroup.traps, 'assets/muscles/Back_traps.png'),
  (MuscleGroup.triceps, 'assets/muscles/Back_triceps.png'),
  (MuscleGroup.forearms, 'assets/muscles/Back_forearms.png'),
  (MuscleGroup.shoulders, 'assets/muscles/Back_shoulders.png'),
];

const _bodyOutlineFront = 'assets/muscles/Front_no_muscles.png';
const _bodyOutlineBack = 'assets/muscles/Back_no_muscles.png';

Color _sorenessColor(Soreness s) => switch (s) {
      Soreness.none => Colors.transparent,
      Soreness.aLittle => const Color(0xFFFFE066),
      Soreness.some => const Color(0xFFFF8C00),
      Soreness.lots => const Color(0xFFD32F2F),
    };

String _muscleLabel(MuscleGroup m) => switch (m) {
      MuscleGroup.chest => 'Chest',
      MuscleGroup.back => 'Back',
      MuscleGroup.biceps => 'Biceps',
      MuscleGroup.triceps => 'Triceps',
      MuscleGroup.shoulders => 'Shoulders',
      MuscleGroup.quads => 'Quads',
      MuscleGroup.hamstrings => 'Hamstrings',
      MuscleGroup.abs => 'Abs',
      MuscleGroup.traps => 'Traps',
      MuscleGroup.forearms => 'Forearms',
      MuscleGroup.glutes => 'Glutes',
      MuscleGroup.calves => 'Calves',
      MuscleGroup.tibialis => 'Tibialis',
      MuscleGroup.fullBody => 'Full Body',
      MuscleGroup.other => 'Other',
    };

class _ImageData {
  _ImageData(this.image, this.bytes);
  final ui.Image image;
  final ByteData bytes;

  /// Returns true if the pixel at [tap] (within a display area of [displaySize])
  /// is opaque in this mask image.
  bool hitTest(Offset tap, Size displaySize) {
    final x =
        (tap.dx / displaySize.width * image.width).round().clamp(0, image.width - 1);
    final y = (tap.dy / displaySize.height * image.height)
        .round()
        .clamp(0, image.height - 1);
    final offset = (y * image.width + x) * 4 + 3; // alpha byte
    return bytes.getUint8(offset) > 10;
  }
}

class BodyMapWidget extends StatefulWidget {
  const BodyMapWidget({
    super.key,
    required this.soreness,
    required this.onChanged,
  });

  final Map<MuscleGroup, Soreness> soreness;
  final void Function(MuscleGroup muscle, Soreness soreness) onChanged;

  @override
  State<BodyMapWidget> createState() => _BodyMapWidgetState();
}

class _BodyMapWidgetState extends State<BodyMapWidget> {
  // Cached pixel data keyed by asset path.
  final Map<String, _ImageData> _cache = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadImages();
  }

  Future<void> _loadImages() async {
    final paths = {
      ..._frontMuscles.map((e) => e.$2),
      ..._backMuscles.map((e) => e.$2),
    };

    for (final path in paths) {
      final data = await rootBundle.load(path);
      final codec =
          await ui.instantiateImageCodec(data.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      final image = frame.image;
      final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (bytes != null) _cache[path] = _ImageData(image, bytes);
    }

    if (mounted) setState(() => _loading = false);
  }

  void _onTap(Offset tap, Size displaySize,
      List<(MuscleGroup, String)> muscles) {
    if (_loading) return;
    for (final (muscle, path) in muscles) {
      final data = _cache[path];
      if (data != null && data.hitTest(tap, displaySize)) {
        _showPicker(muscle);
        return;
      }
    }
  }

  void _showPicker(MuscleGroup muscle) {
    final current = widget.soreness[muscle] ?? Soreness.none;
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                _muscleLabel(muscle),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            for (final s in Soreness.values)
              ListTile(
                leading: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: s == Soreness.none
                        ? Theme.of(context).colorScheme.outline
                        : _sorenessColor(s),
                  ),
                ),
                title: Text(_sorenessLabel(s)),
                trailing:
                    current == s ? const Icon(Icons.check) : null,
                onTap: () {
                  Navigator.pop(ctx);
                  widget.onChanged(muscle, s);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return Column(
      children: [
        _bodyView('Front', _bodyOutlineFront, _frontMuscles),
        const SizedBox(height: 16),
        _bodyView('Back', _bodyOutlineBack, _backMuscles),
      ],
    );
  }

  Widget _bodyView(String label, String outlinePath,
      List<(MuscleGroup, String)> muscles) {
    return Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 4),
        LayoutBuilder(
          builder: (context, constraints) {
            // Derive height from the outline image's natural aspect ratio.
            // We don't know it until the image loads, so use BoxFit.contain
            // and an IntrinsicHeight wrapper instead.
            final displayWidth = constraints.maxWidth;
            return GestureDetector(
              onTapUp: (details) {
                // Find rendered image bounds via the RenderBox.
                final box =
                    context.findRenderObject() as RenderBox?;
                if (box == null) return;
                final size = box.size;
                _onTap(details.localPosition, size, muscles);
              },
              child: Stack(
                children: [
                  Image.asset(
                    outlinePath,
                    width: displayWidth,
                    fit: BoxFit.contain,
                  ),
                  for (final (muscle, path) in muscles)
                    if ((widget.soreness[muscle] ?? Soreness.none) !=
                        Soreness.none)
                      Positioned.fill(
                        child: Image.asset(
                          path,
                          fit: BoxFit.contain,
                          color: _sorenessColor(
                              widget.soreness[muscle] ?? Soreness.none)
                              .withValues(alpha: 0.7),
                          colorBlendMode: BlendMode.srcIn,
                        ),
                      ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

String _sorenessLabel(Soreness s) => switch (s) {
      Soreness.none => 'None',
      Soreness.aLittle => 'A Little',
      Soreness.some => 'Some',
      Soreness.lots => 'Lots',
    };
