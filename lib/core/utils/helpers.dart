import 'dart:math';

/// Utility helper functions.
class Helpers {
  Helpers._();

  static final Random _random = Random();

  /// Returns a random integer between [min] (inclusive) and [max] (exclusive).
  static int randomInt(int min, int max) {
    return min + _random.nextInt(max - min);
  }

  /// Shuffles a list in place and returns it.
  static List<T> shuffle<T>(List<T> list) {
    list.shuffle(_random);
    return list;
  }

  /// Returns a random element from the list.
  static T randomElement<T>(List<T> list) {
    if (list.isEmpty) {
      throw ArgumentError('Cannot pick from an empty list');
    }
    return list[_random.nextInt(list.length)];
  }

  /// Picks [count] random elements from the list.
  static List<T> sample<T>(List<T> list, int count) {
    if (count >= list.length) {
      return List<T>.from(list)..shuffle(_random);
    }
    final copy = List<T>.from(list)..shuffle(_random);
    return copy.take(count).toList();
  }

  /// Calculates accuracy percentage.
  static int calculateAccuracy(int correct, int total) {
    if (total == 0) return 0;
    return ((correct / total) * 100).round();
  }
}
