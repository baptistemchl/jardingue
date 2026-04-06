import 'package:flutter_test/flutter_test.dart';
import 'package:jardingue/core/utils/plant_emoji_mapper.dart';

void main() {
  group('PlantEmojiMapper', () {
    group('fromName', () {
      test('returns tomato emoji for "Tomate"', () {
        expect(
          PlantEmojiMapper.fromName('Tomate'),
          '\u{1F345}',
        );
      });

      test('returns carrot emoji for "Carotte"', () {
        expect(
          PlantEmojiMapper.fromName('Carotte'),
          '\u{1F955}',
        );
      });

      test('handles accented characters', () {
        expect(
          PlantEmojiMapper.fromName('\u{00C9}pinard'),
          '\u{1F96C}',
        );
      });

      test('is case insensitive', () {
        expect(
          PlantEmojiMapper.fromName('TOMATE'),
          '\u{1F345}',
        );
      });

      test('returns fallback for unknown name', () {
        expect(
          PlantEmojiMapper.fromName('Xylophone'),
          PlantEmojiMapper.fallback,
        );
      });

      test(
        'falls back to category when name not found',
        () {
          expect(
            PlantEmojiMapper.fromName(
              'Plante inconnue',
              categoryCode: 'herb',
            ),
            '\u{1F33F}',
          );
        },
      );

      test(
        'prefers name match over category',
        () {
          // "Tomate" matches name -> tomato emoji
          // even if categoryCode is 'herb'
          expect(
            PlantEmojiMapper.fromName(
              'Tomate cerise',
              categoryCode: 'herb',
            ),
            '\u{1F345}',
          );
        },
      );
    });

    group('fromCategory', () {
      test('returns correct emoji for known codes', () {
        expect(
          PlantEmojiMapper.fromCategory(
            'fruit_vegetable',
          ),
          '\u{1F345}',
        );
        expect(
          PlantEmojiMapper.fromCategory('root'),
          '\u{1F955}',
        );
        expect(
          PlantEmojiMapper.fromCategory('herb'),
          '\u{1F33F}',
        );
      });

      test('returns fallback for null', () {
        expect(
          PlantEmojiMapper.fromCategory(null),
          PlantEmojiMapper.fallback,
        );
      });

      test('returns fallback for unknown code', () {
        expect(
          PlantEmojiMapper.fromCategory('unknown'),
          PlantEmojiMapper.fallback,
        );
      });
    });
  });
}
