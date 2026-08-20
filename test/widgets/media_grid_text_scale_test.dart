import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/media_item.dart' show CardShape;
import 'package:plezy/utils/layout_constants.dart';
import 'package:plezy/widgets/media_grid_delegate.dart';

/// Grid cells encode "artwork plus a text band" as a single aspect ratio.
/// [MediaGridDelegate.aspectRatioFor] has to grow only the band when the text
/// multiplier rises — growing the whole cell would enlarge the posters and drop
/// a column, and growing nothing clips the titles.
void main() {
  /// Height per one unit of width — the axis the band actually lives on.
  double heightFor(double aspectRatio) => 1 / aspectRatio;

  const shapes = <CardShape, double>{
    CardShape.poster: GridLayoutConstants.fullCardPosterAspectRatio,
    CardShape.square: GridLayoutConstants.squareAspectRatio,
    CardShape.wide: GridLayoutConstants.episodeThumbnailAspectRatio,
  };

  group('MediaGridDelegate.aspectRatioFor text band scaling', () {
    test('is unchanged at 1.0x', () {
      for (final shape in shapes.keys) {
        expect(
          MediaGridDelegate.aspectRatioFor(shape: shape, textScale: 1.0),
          MediaGridDelegate.aspectRatioFor(shape: shape),
          reason: shape.name,
        );
      }
    });

    test('grows the band by the multiplier and leaves the artwork alone', () {
      for (final entry in shapes.entries) {
        final imageHeight = heightFor(entry.value);
        final baseBand = heightFor(MediaGridDelegate.aspectRatioFor(shape: entry.key)) - imageHeight;
        expect(baseBand, greaterThan(0), reason: '${entry.key.name} has no text band to scale');

        for (final scale in const [1.5, 2.0]) {
          final scaled = MediaGridDelegate.aspectRatioFor(shape: entry.key, textScale: scale);
          expect(
            heightFor(scaled) - imageHeight,
            closeTo(baseBand * scale, 0.0001),
            reason: '${entry.key.name} at ${scale}x',
          );
        }
      }
    });

    test('a taller multiplier always yields a taller cell', () {
      for (final shape in shapes.keys) {
        final small = MediaGridDelegate.aspectRatioFor(shape: shape, textScale: 1.0);
        final large = MediaGridDelegate.aspectRatioFor(shape: shape, textScale: 2.0);
        // Aspect ratio is width/height, so taller means a smaller number.
        expect(large, lessThan(small), reason: shape.name);
      }
    });

    test('full-bleed cells ignore the multiplier - they have no text band', () {
      for (final entry in shapes.entries) {
        expect(
          MediaGridDelegate.aspectRatioFor(shape: entry.key, fullBleedImage: true, textScale: 2.0),
          entry.value,
          reason: entry.key.name,
        );
      }
    });
  });
}
