/// Application-wide constants.
class AppConstants {
  AppConstants._();

  /// App name displayed in the UI.
  static const String appName = 'Country Trivia';

  /// App version.
  static const String appVersion = '1.0.0';

  /// Number of answer options per question.
  static const int optionsPerQuestion = 4;

  /// Maximum number of attempts per question.
  static const int maxAttempts = 3;

  /// Points awarded for a correct answer on the first attempt.
  static const int pointsFirstAttempt = 10;

  /// Points awarded for a correct answer on the second attempt.
  static const int pointsSecondAttempt = 8;

  /// Points awarded for a correct answer on the third attempt.
  static const int pointsThirdAttempt = 5;

  /// Number of recently used countries to exclude from question generation.
  static const int recentCountriesExclusionCount = 10;

  /// Default number of questions per game.
  static const int defaultQuestionsPerGame = 10;
}
