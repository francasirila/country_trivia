# Country Trivia - Master Plan & Architecture

## Table of Contents

1. [Overview](#overview)
2. [API & Data Strategy](#api--data-strategy)
3. [Architecture Overview](#architecture-overview)
4. [Project Structure](#project-structure)
5. [Data Layer](#data-layer)
6. [Domain Layer](#domain-layer)
7. [ViewModel Layer](#viewmodel-layer)
8. [View Layer](#view-layer)
9. [Game Logic & Scoring](#game-logic--scoring)
10. [State Management with Provider](#state-management-with-provider)
11. [Navigation](#navigation)
12. [Error Handling](#error-handling)
13. [Testing Strategy](#testing-strategy)
14. [Dependencies](#dependencies)
15. [Implementation Phases](#implementation-phases)

---

## Overview

Country Trivia is a Flutter quiz game where players identify countries by their flags. Each round presents a flag image and four country name options. Players have three attempts to guess correctly, with points awarded based on speed: 10 points (1st try), 8 points (2nd try), 5 points (3rd try). After three wrong guesses, the correct answer is revealed and no points are awarded.

### Core Features

- Display a random country flag
- Present 4 country name options (1 correct + 3 distractors)
- 3 attempts per question with decreasing point rewards
- Score tracking across rounds
- Reveal correct answer after exhausting attempts
- Smooth, engaging UI with animations

---

## API & Data Strategy

### API Situation

The originally referenced REST Countries v2 API (`https://restcountries.com/v2/all`) has been **deprecated**. The current API is v5 (`https://api.restcountries.com/countries/v5`) and requires an API key via `Authorization: Bearer YOUR_API_KEY` header.

### Recommended Approach: Hybrid Data Strategy

We will implement a **flexible data layer** that supports two modes:

#### Mode 1: Live API (v5)

- Endpoint: `GET https://api.restcountries.com/countries/v5?response_fields=names.common,codes.alpha_2&limit=100`
- Requires API key (stored securely, not hardcoded)
- Response structure (JSON:API-like):
  ```json
  {
    "data": {
      "objects": [
        { "names": { "common": "Germany" }, "codes": { "alpha_2": "DE" } }
      ],
      "meta": { "total": 249, "count": 100, "limit": 100, "offset": 0, "more": true }
    }
  }
  ```
- Paginated (max 100 per page on free plan, up to 500 on paid)

#### Mode 2: Local JSON Fallback

- A local `assets/data/countries.json` file containing a curated subset of countries
- Used when: no API key is configured, API is unreachable, or for offline play
- Same data shape as the API response for seamless swapping

### Flag CDN

- URL pattern: `https://flagcdn.com/w320/{iso}.png`
- `{iso}` is the lowercase ISO 3166-1 alpha-2 code (e.g., `us`, `de`, `br`)
- No authentication required
- Multiple sizes available: `w40`, `w80`, `w160`, `w320`, `w640`, `w1280`, `w2560`

### Data Flow

```
[API v5] --> [Repository] --> [ViewModel] --> [View]
[Local JSON] --> [Repository] --> [ViewModel] --> [View]
```

---

## Architecture Overview

We use **MVVM (Model-View-ViewModel)** with **Provider** for state management.

```
┌─────────────────────────────────────────────────────┐
│                      VIEW                            │
│  (Widgets - Stateless, reactive to ViewModel)        │
│  - FlagDisplayWidget                                 │
│  - AnswerOptionsWidget                               │
│  - ScoreBoardWidget                                  │
│  - GameScreen                                        │
│  - ResultOverlayWidget                               │
└──────────────────────┬──────────────────────────────┘
                       │ reads state via
                       │ context.watch / Consumer
┌──────────────────────▼──────────────────────────────┐
│                   VIEWMODEL                          │
│  (ChangeNotifier - holds game state & logic)         │
│  - GameViewModel                                     │
│    - currentQuestion                                 │
│    - score                                           │
│    - attemptsRemaining                               │
│    - gameStatus                                      │
│    - answerQuestion()                                │
│    - nextQuestion()                                  │
│    - resetGame()                                     │
└──────────────────────┬──────────────────────────────┘
                       │ calls
┌──────────────────────▼──────────────────────────────┐
│                  REPOSITORY                          │
│  (Abstracts data source - API or local)              │
│  - CountryRepository (interface)                     │
│  - ApiCountryRepository                              │
│  - LocalCountryRepository                            │
└──────────────────────┬──────────────────────────────┘
                       │ fetches from
┌──────────────────────▼──────────────────────────────┐
│                   DATA SOURCE                        │
│  - REST Countries v5 API (HTTP)                      │
│  - Local JSON asset file                             │
└─────────────────────────────────────────────────────┘
```

---

## Project Structure

```
lib/
├── main.dart                          # App entry point, Provider setup
├── app.dart                           # MaterialApp configuration, theme
│
├── core/
│   ├── constants/
│   │   ├── api_constants.dart          # API URLs, endpoints
│   │   ├── app_constants.dart          # App-wide constants
│   │   └── storage_keys.dart           # SharedPreferences keys
│   ├── theme/
│   │   ├── app_theme.dart             # ThemeData, colors, text styles
│   │   └── app_colors.dart            # Color palette
│   ├── utils/
│   │   ├── extensions.dart            # BuildContext, String extensions
│   │   └── helpers.dart               # Utility functions
│   └── exceptions/
│       └── app_exceptions.dart        # Custom exception classes
│
├── data/
│   ├── models/
│   │   └── country.dart               # Country data model
│   ├── datasources/
│   │   ├── country_remote_datasource.dart   # API calls
│   │   └── country_local_datasource.dart    # Local JSON loading
│   └── repositories/
│       └── country_repository_impl.dart     # Repository implementation
│
├── domain/
│   ├── entities/
│   │   └── country_entity.dart        # Business entity (clean model)
│   ├── repositories/
│   │   └── country_repository.dart    # Abstract repository interface
│   └── usecases/
│       ├── get_countries.dart         # Fetch all countries
│       ├── generate_question.dart     # Create a trivia question
│       └── check_answer.dart          # Validate answer & compute score
│
├── presentation/
│   ├── providers/
│   │   └── game_provider.dart         # GameViewModel (ChangeNotifier)
│   ├── screens/
│   │   ├── splash_screen.dart         # Loading/data fetch screen
│   │   ├── home_screen.dart           # Start game screen
│   │   ├── game_screen.dart           # Main game play screen
│   │   └── game_over_screen.dart      # Final score screen
│   └── widgets/
│       ├── flag_display.dart          # Flag image with loading/error states
│       ├── answer_button.dart         # Individual answer option button
│       ├── answer_options_grid.dart   # 2x2 grid of answer buttons
│       ├── score_board.dart           # Current score display
│       ├── attempts_indicator.dart    # Visual attempts remaining
│       ├── question_counter.dart      # Question number display
│       ├── feedback_overlay.dart      # Correct/wrong feedback animation
│       └── reveal_answer.dart         # Correct answer reveal widget
│
└── services/
    ├── api_service.dart               # HTTP client wrapper
    └── storage_service.dart           # SharedPreferences wrapper
```

---

## Data Layer

### Country Model (`data/models/country.dart`)

```dart
class Country {
  final String name;        // Common name (e.g., "Germany")
  final String isoCode;     // ISO alpha-2 code (e.g., "DE")

  const Country({required this.name, required this.isoCode});

  // Factory constructors for both API v5 and local JSON
  factory Country.fromApiV5(Map<String, dynamic> json) { ... }
  factory Country.fromLocalJson(Map<String, dynamic> json) { ... }

  // Flag URL getter
  String get flagUrl => 'https://flagcdn.com/w320/${isoCode.toLowerCase()}.png';
}
```

### Remote Data Source (`data/datasources/country_remote_datasource.dart`)

- Uses `http` package for API calls
- Handles pagination (fetches all pages if needed)
- Parses v5 JSON:API response structure
- Throws `ServerException` on failure

### Local Data Source (`data/datasources/country_local_datasource.dart`)

- Loads `assets/data/countries.json` from assets
- Parses JSON into List<Country>
- Used as fallback or when no API key is available

### Repository Implementation (`data/repositories/country_repository_impl.dart`)

- Implements `CountryRepository` interface
- Tries remote first, falls back to local on failure
- Caches results in memory after first successful fetch

---

## Domain Layer

### Country Entity (`domain/entities/country_entity.dart`)

- Pure business object, independent of data source
- Contains only `name` and `isoCode`
- Used by use cases and ViewModels

### Repository Interface (`domain/repositories/country_repository.dart`)

```dart
abstract class CountryRepository {
  Future<List<CountryEntity>> getCountries();
}
```

### Use Cases

#### `GetCountries`
- Fetches all available countries
- Returns `List<CountryEntity>`

#### `GenerateQuestion`
- Input: List of all countries, previously used country ISO codes (to avoid repeats)
- Output: `Question` object containing:
  - `correctCountry: CountryEntity`
  - `options: List<CountryEntity>` (4 options, shuffled)
- Logic:
  1. Pick a random country from the pool (excluding recently used)
  2. Pick 3 random distractor countries (different from correct answer)
  3. Combine and shuffle all 4 options

#### `CheckAnswer`
- Input: selected country, correct country, current attempt number
- Output: `AnswerResult` containing:
  - `isCorrect: bool`
  - `pointsEarned: int` (10, 8, 5, or 0)
  - `attemptsRemaining: int`

---

## ViewModel Layer

### GameViewModel (`presentation/providers/game_provider.dart`)

```dart
class GameViewModel extends ChangeNotifier {
  // --- State ---
  GameStatus _status;              // loading, playing, revealed, gameOver
  Question? _currentQuestion;      // Current question with options
  int _score;                      // Running total score
  int _attemptsRemaining;          // 3, 2, 1, or 0
  int _currentAttempt;             // 1, 2, or 3
  int _questionNumber;             // Question counter (1-based)
  int _correctAnswers;             // Total correct answers
  String? _selectedAnswer;         // Currently selected option
  bool _isAnswerCorrect;           // Result of last answer
  List<String> _usedCountryCodes;  // Track used countries to avoid repeats

  // --- Getters ---
  GameStatus get status => _status;
  Question? get currentQuestion => _currentQuestion;
  int get score => _score;
  int get attemptsRemaining => _attemptsRemaining;
  int get currentAttempt => _currentAttempt;
  int get questionNumber => _questionNumber;
  int get correctAnswers => _correctAnswers;
  String? get selectedAnswer => _selectedAnswer;
  bool get isAnswerCorrect => _isAnswerCorrect;

  // --- Methods ---
  Future<void> initialize();                    // Load countries
  void answerQuestion(String selectedCountry);  // Process answer
  void nextQuestion();                          // Move to next question
  void resetGame();                             // Reset all state
}
```

### Game Status Enum

```dart
enum GameStatus {
  loading,     // Fetching countries
  ready,       // Countries loaded, ready to start
  playing,     // Question displayed, awaiting answer
  answered,    // Answer selected, showing feedback
  revealed,    // All attempts used, showing correct answer
  gameOver,    // Game ended
}
```

### Scoring Logic

| Attempt | Points |
|---------|--------|
| 1st     | 10     |
| 2nd     | 8      |
| 3rd     | 5      |
| Failed  | 0      |

---

## View Layer

### Screen Flow

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│   Splash     │────▶│    Home      │────▶│    Game      │
│   Screen     │     │   Screen     │     │   Screen     │
│              │     │              │     │              │
│ - Load data  │     │ - Start btn  │     │ - Flag       │
│ - Show       │     │ - High score │     │ - 4 options  │
│   progress   │     │              │     │ - Score      │
└──────────────┘     └──────────────┘     │ - Attempts   │
                                          └──────┬───────┘
                                                 │
                                          ┌──────▼───────┐
                                          │  Game Over   │
                                          │   Screen     │
                                          │              │
                                          │ - Final score│
                                          │ - Stats      │
                                          │ - Play again │
                                          └──────────────┘
```

### Widget Details

#### `FlagDisplay`
- Loads flag from `https://flagcdn.com/w320/{iso}.png`
- Shows loading indicator while image loads
- Shows error icon if image fails to load
- Cached network image for performance

#### `AnswerButton`
- Displays country name
- States: default, selected-correct, selected-wrong, disabled
- Color-coded feedback (green for correct, red for wrong)
- Disabled after answer is revealed

#### `AnswerOptionsGrid`
- 2x2 grid layout of `AnswerButton` widgets
- Responsive sizing

#### `ScoreBoard`
- Displays current score with icon
- Animated score changes

#### `AttemptsIndicator`
- Visual dots/hearts showing remaining attempts
- Updates after each wrong answer

#### `FeedbackOverlay`
- Animated overlay showing "Correct!" or "Try again!"
- Auto-dismisses after short delay
- Shows points earned

#### `RevealAnswer`
- Highlights the correct answer in green
- Shows "The correct answer is: [Country]"
- "Next Question" button appears

---

## Game Logic & Scoring

### Question Generation Algorithm

```
1. Maintain pool of all countries
2. Exclude recently used countries (last 10) to avoid repeats
3. Randomly select correct answer from remaining pool
4. Randomly select 3 distractors from remaining pool
5. Combine correct + distractors = 4 options
6. Shuffle options randomly
7. Add correct answer to used list
```

### Answer Flow

```
User taps option
  │
  ├── Is it the correct answer?
  │     ├── YES → Award points (10/8/5 based on attempt)
  │     │         Show "Correct!" feedback
  │     │         Update score
  │     │         Show "Next Question" button
  │     │
  │     └── NO → Decrement attempts remaining
  │              If attempts > 0:
  │                Show "Try again!" feedback
  │                Highlight wrong selection in red
  │                Disable that option
  │              If attempts == 0:
  │                Reveal correct answer
  │                Show "Next Question" button
  │
  └── Wait for user to tap "Next Question"
        │
        └── Generate new question, reset attempts to 3
```

### Points System

```dart
int getPointsForAttempt(int attempt) {
  switch (attempt) {
    case 1: return 10;
    case 2: return 8;
    case 3: return 5;
    default: return 0;
  }
}
```

---

## State Management with Provider

### Provider Setup (`main.dart`)

```dart
void main() {
  runApp(
    MultiProvider(
      providers: [
        // Services
        Provider<ApiService>(create: (_) => ApiService()),
        Provider<StorageService>(create: (_) => StorageService()),
        // Repository
        Provider<CountryRepository>(
          create: (ctx) => CountryRepositoryImpl(
            remoteDataSource: ctx.read<ApiService>(),
            localDataSource: LocalCountryDataSource(),
          ),
        ),
        // Use Cases
        Provider<GetCountries>(create: (ctx) => GetCountries(ctx.read())),
        Provider<GenerateQuestion>(create: (ctx) => GenerateQuestion()),
        Provider<CheckAnswer>(create: (ctx) => CheckAnswer()),
        // ViewModel
        ChangeNotifierProvider<GameViewModel>(
          create: (ctx) => GameViewModel(
            getCountries: ctx.read<GetCountries>(),
            generateQuestion: ctx.read<GenerateQuestion>(),
            checkAnswer: ctx.read<CheckAnswer>(),
          ),
        ),
      ],
      child: const CountryTriviaApp(),
    ),
  );
}
```

### Consuming State in Widgets

```dart
// In build method:
final gameViewModel = context.watch<GameViewModel>();

// Or using Consumer for granular rebuilds:
Consumer<GameViewModel>(
  builder: (context, viewModel, child) {
    return Text('Score: ${viewModel.score}');
  },
)
```

---

## Navigation

Using Flutter's built-in `Navigator` with named routes:

```dart
routes: {
  '/': (context) => const SplashScreen(),
  '/home': (context) => const HomeScreen(),
  '/game': (context) => const GameScreen(),
  '/game-over': (context) => const GameOverScreen(),
}
```

### Navigation Flow

1. **Splash** → auto-navigates to Home when data is ready
2. **Home** → "Start Game" button → Game
3. **Game** → "End Game" or after N questions → Game Over
4. **Game Over** → "Play Again" → Game (reset) or "Home" → Home

---

## Error Handling

### Exception Hierarchy

```dart
abstract class AppException implements Exception {
  final String message;
  const AppException(this.message);
}

class ServerException extends AppException { ... }
class NetworkException extends AppException { ... }
class CacheException extends AppException { ... }
class NoDataException extends AppException { ... }
```

### Error States in UI

| State | UI Behavior |
|-------|-------------|
| Loading | Show `CircularProgressIndicator` with message |
| Network Error | Show error message with "Retry" button |
| API Error | Fall back to local data, show subtle banner |
| No Data | Show "No countries available" with retry |
| Image Load Error | Show placeholder flag icon |

### Retry Strategy

- API calls: 3 retries with exponential backoff
- Image loading: Flutter's built-in `errorBuilder` widget
- Data initialization: Retry button on splash screen

---

## Testing Strategy

### Unit Tests

- **Model tests**: JSON parsing, serialization
- **Use case tests**: Question generation, answer checking, scoring logic
- **ViewModel tests**: State transitions, score calculation, game flow

### Widget Tests

- **FlagDisplay**: Loading, loaded, error states
- **AnswerButton**: Tap, disabled, color states
- **GameScreen**: Full game flow simulation
- **ScoreBoard**: Score display updates

### Integration Tests

- Complete game flow: Start → Answer → Next → Game Over → Replay
- API data fetching and parsing
- Local fallback when API unavailable

### Test File Structure

```
test/
├── unit/
│   ├── models/
│   │   └── country_test.dart
│   ├── usecases/
│   │   ├── generate_question_test.dart
│   │   └── check_answer_test.dart
│   └── viewmodels/
│       └── game_viewmodel_test.dart
├── widget/
│   ├── flag_display_test.dart
│   ├── answer_button_test.dart
│   └── game_screen_test.dart
└── integration/
    └── game_flow_test.dart
```

---

## Dependencies

### pubspec.yaml

```yaml
dependencies:
  flutter:
    sdk: flutter

  # State Management
  provider: ^6.1.2

  # Networking
  http: ^1.2.2

  # Local Storage
  shared_preferences: ^2.3.3

  # Image Caching
  cached_network_image: ^3.4.1

  # Connectivity
  connectivity_plus: ^6.1.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0
  mockito: ^5.4.5
  build_runner: ^2.4.14
```

### Dependency Justification

| Package | Purpose |
|---------|---------|
| `provider` | State management (required) |
| `http` | REST API calls |
| `shared_preferences` | Persist high score, settings |
| `cached_network_image` | Efficient flag image loading & caching |
| `connectivity_plus` | Detect network availability |
| `mockito` | Mocking for tests |

---

## Implementation Phases

### Phase 1: Foundation
- Set up project structure
- Add dependencies to `pubspec.yaml`
- Create constants, theme, and app configuration
- Implement `Country` model with JSON parsing
- Create API service and local data source
- Implement repository pattern

### Phase 2: Domain Layer
- Create `CountryEntity`
- Implement `GetCountries` use case
- Implement `GenerateQuestion` use case
- Implement `CheckAnswer` use case
- Write unit tests for all use cases

### Phase 3: ViewModel
- Implement `GameViewModel` with full game logic
- Implement scoring system
- Handle all game states (loading, playing, revealed, game over)
- Write unit tests for ViewModel

### Phase 4: UI - Core Game
- Build `SplashScreen` with data loading
- Build `HomeScreen` with start button
- Build `GameScreen` with flag display and answer options
- Implement `FlagDisplay` widget with caching
- Implement `AnswerButton` and `AnswerOptionsGrid`
- Implement `ScoreBoard` and `AttemptsIndicator`

### Phase 5: UI - Feedback & Polish
- Add `FeedbackOverlay` animations
- Add `RevealAnswer` widget
- Build `GameOverScreen` with statistics
- Add transitions between screens
- Polish theme, colors, and typography

### Phase 6: Data & API
- Add local JSON fallback data
- Implement API key configuration
- Add error handling and retry logic
- Implement connectivity checking
- Add caching strategy

### Phase 7: Testing & Quality
- Write comprehensive unit tests
- Write widget tests
- Write integration tests
- Achieve >80% code coverage
- Performance optimization

### Phase 8: Final Polish
- Add app icon and splash screen
- Add sound effects (optional)
- Add haptic feedback
- Accessibility support (screen readers)
- Final UI/UX review

---

## Key Design Decisions

1. **Repository Pattern**: Abstracts data source, enabling easy switching between API and local data
2. **Use Cases**: Single-responsibility business logic, easily testable
3. **ChangeNotifier**: Simple, well-integrated with Provider, sufficient for this app's complexity
4. **Cached Network Image**: Essential for flag images to avoid redundant network requests
5. **Hybrid Data Strategy**: Ensures app works even without API key or network
6. **Entity Separation**: Domain entities are independent of data layer models

---

## Asset Requirements

```
assets/
├── data/
│   └── countries.json          # Local fallback country data
└── images/
    ├── placeholder_flag.png    # Shown when flag fails to load
    └── app_logo.png            # App branding
```

---

## API Key Configuration

The API key should be configured via:

1. **Environment variable** (recommended for CI/CD):
   ```bash
   flutter run --dart-define=REST_COUNTRIES_API_KEY=your_key_here
   ```

2. **Local properties** (for local development):
   - Create `lib/core/constants/api_config.dart`
   - Read from environment with fallback to empty string

3. **No key**: App falls back to local JSON data automatically

---

---

## Execution Tickets

This section breaks the plan into individual, actionable tickets with dependencies and parallel execution guidance.

### Ticket Summary

| ID | Title | Phase | Dependencies | Parallel Group |
|----|-------|-------|--------------|----------------|
| T-01 | Project setup & dependencies | 1 | None | A |
| T-02 | Core constants, theme & app config | 1 | T-01 | A |
| T-03 | Country model & JSON parsing | 1 | T-01 | A |
| T-04 | API service & remote data source | 1 | T-01, T-03 | B |
| T-05 | Local JSON data source | 1 | T-01, T-03 | B |
| T-06 | Repository implementation | 1 | T-04, T-05 | C |
| T-07 | Domain entity & repository interface | 2 | T-03 | C |
| T-08 | GetCountries use case | 2 | T-06, T-07 | D |
| T-09 | GenerateQuestion use case | 2 | T-07 | D |
| T-10 | CheckAnswer use case | 2 | T-07 | D |
| T-11 | Unit tests - models & use cases | 2 | T-08, T-09, T-10 | E |
| T-12 | GameViewModel implementation | 3 | T-08, T-09, T-10 | E |
| T-13 | Unit tests - ViewModel | 3 | T-12 | F |
| T-14 | Splash screen | 4 | T-02, T-12 | F |
| T-15 | Home screen | 4 | T-02, T-12 | F |
| T-16 | FlagDisplay widget | 4 | T-02 | F |
| T-17 | AnswerButton widget | 4 | T-02 | F |
| T-18 | AnswerOptionsGrid widget | 4 | T-17 | G |
| T-19 | ScoreBoard widget | 4 | T-02 | G |
| T-20 | AttemptsIndicator widget | 4 | T-02 | G |
| T-21 | GameScreen assembly | 4 | T-14, T-15, T-16, T-18, T-19, T-20 | H |
| T-22 | FeedbackOverlay widget | 5 | T-02 | H |
| T-23 | RevealAnswer widget | 5 | T-02 | H |
| T-24 | GameOverScreen | 5 | T-02, T-12 | H |
| T-25 | Screen transitions & navigation | 5 | T-21, T-24 | I |
| T-26 | Local JSON fallback data | 6 | T-05 | I |
| T-27 | API key configuration | 6 | T-04 | I |
| T-28 | Error handling & retry logic | 6 | T-06, T-21 | J |
| T-29 | Connectivity checking | 6 | T-06 | J |
| T-30 | Widget tests | 7 | T-21, T-22, T-23 | K |
| T-31 | Integration tests | 7 | T-25, T-28 | L |
| T-32 | Performance optimization | 7 | T-31 | M |
| T-33 | App icon & splash screen | 8 | T-25 | M |
| T-34 | Sound effects & haptic feedback | 8 | T-25 | M |
| T-35 | Accessibility support | 8 | T-25 | M |
| T-36 | Final UI/UX review & polish | 8 | T-30, T-31, T-32, T-33, T-34, T-35 | N |

---

### Parallel Execution Groups

```
Group A (Start here - no dependencies):
├── T-01: Project setup & dependencies
├── T-02: Core constants, theme & app config
└── T-03: Country model & JSON parsing

Group B (After T-01 & T-03):
├── T-04: API service & remote data source
└── T-05: Local JSON data source

Group C (After T-04, T-05 & T-03):
├── T-06: Repository implementation
└── T-07: Domain entity & repository interface

Group D (After T-06 & T-07):
├── T-08: GetCountries use case
├── T-09: GenerateQuestion use case
└── T-10: CheckAnswer use case

Group E (After T-08, T-09, T-10):
├── T-11: Unit tests - models & use cases
└── T-12: GameViewModel implementation

Group F (After T-02 & T-12):
├── T-13: Unit tests - ViewModel
├── T-14: Splash screen
├── T-15: Home screen
├── T-16: FlagDisplay widget
└── T-17: AnswerButton widget

Group G (After T-17 & T-02):
├── T-18: AnswerOptionsGrid widget
├── T-19: ScoreBoard widget
└── T-20: AttemptsIndicator widget

Group H (After T-14, T-15, T-16, T-18, T-19, T-20):
├── T-21: GameScreen assembly
├── T-22: FeedbackOverlay widget
├── T-23: RevealAnswer widget
└── T-24: GameOverScreen

Group I (After T-21 & T-24):
├── T-25: Screen transitions & navigation
├── T-26: Local JSON fallback data
└── T-27: API key configuration

Group J (After T-06 & T-21):
├── T-28: Error handling & retry logic
└── T-29: Connectivity checking

Group K (After T-21, T-22, T-23):
└── T-30: Widget tests

Group L (After T-25 & T-28):
└── T-31: Integration tests

Group M (After T-31 & T-25):
├── T-32: Performance optimization
├── T-33: App icon & splash screen
├── T-34: Sound effects & haptic feedback
└── T-35: Accessibility support

Group N (After all above):
└── T-36: Final UI/UX review & polish
```

---

### Ticket Details

#### T-01: Project Setup & Dependencies
**Phase:** 1 - Foundation
**Dependencies:** None
**Parallel Group:** A

**Tasks:**
- [ ] Update `pubspec.yaml` with all required dependencies
- [ ] Run `flutter pub get`
- [ ] Create project directory structure (`lib/core/`, `lib/data/`, `lib/domain/`, `lib/presentation/`, `lib/services/`)
- [ ] Create `assets/data/` and `assets/images/` directories
- [ ] Update `pubspec.yaml` with asset declarations
- [ ] Verify project builds successfully

**Acceptance Criteria:**
- All dependencies resolve without conflicts
- Directory structure matches plan
- `flutter analyze` passes with no errors
- App builds and runs on emulator/device

---

#### T-02: Core Constants, Theme & App Config
**Phase:** 1 - Foundation
**Dependencies:** T-01
**Parallel Group:** A

**Tasks:**
- [ ] Create `lib/core/constants/api_constants.dart` (API URLs, endpoints)
- [ ] Create `lib/core/constants/app_constants.dart` (app name, version)
- [ ] Create `lib/core/constants/storage_keys.dart` (SharedPreferences keys)
- [ ] Create `lib/core/theme/app_colors.dart` (color palette)
- [ ] Create `lib/core/theme/app_theme.dart` (ThemeData configuration)
- [ ] Create `lib/core/exceptions/app_exceptions.dart` (exception classes)
- [ ] Create `lib/core/utils/extensions.dart` (BuildContext, String extensions)
- [ ] Create `lib/core/utils/helpers.dart` (utility functions)
- [ ] Create `lib/app.dart` (MaterialApp with theme and routes)

**Acceptance Criteria:**
- All constant files compile without errors
- Theme applies correctly to MaterialApp
- Exception hierarchy is properly defined
- Extensions work as expected

---

#### T-03: Country Model & JSON Parsing
**Phase:** 1 - Foundation
**Dependencies:** T-01
**Parallel Group:** A

**Tasks:**
- [ ] Create `lib/data/models/country.dart`
- [ ] Implement `Country` class with `name` and `isoCode` fields
- [ ] Add `Country.fromApiV5()` factory constructor (parses v5 JSON:API response)
- [ ] Add `Country.fromLocalJson()` factory constructor (parses local JSON)
- [ ] Add `flagUrl` getter returning `https://flagcdn.com/w320/{iso}.png`
- [ ] Add `toJson()` serialization method
- [ ] Add `==` and `hashCode` overrides for value equality

**Acceptance Criteria:**
- Model parses both API v5 and local JSON formats correctly
- `flagUrl` returns correct URL format
- Value equality works for testing
- `flutter analyze` passes

---

#### T-04: API Service & Remote Data Source
**Phase:** 1 - Foundation
**Dependencies:** T-01, T-03
**Parallel Group:** B

**Tasks:**
- [ ] Create `lib/services/api_service.dart` (HTTP client wrapper)
- [ ] Implement GET request method with headers
- [ ] Add API key support via `Authorization: Bearer` header
- [ ] Create `lib/data/datasources/country_remote_datasource.dart`
- [ ] Implement `fetchCountries()` method with pagination support
- [ ] Parse v5 JSON:API response (`data.objects` array)
- [ ] Handle HTTP errors and throw appropriate exceptions
- [ ] Add request timeout configuration

**Acceptance Criteria:**
- Successfully fetches countries from v5 API
- Handles pagination (fetches all pages)
- Throws `ServerException` on API errors
- Throws `NetworkException` on connectivity issues

---

#### T-05: Local JSON Data Source
**Phase:** 1 - Foundation
**Dependencies:** T-01, T-03
**Parallel Group:** B

**Tasks:**
- [ ] Create `lib/data/datasources/country_local_datasource.dart`
- [ ] Implement `loadCountries()` method using `rootBundle`
- [ ] Parse local JSON file into `List<Country>`
- [ ] Handle file not found and parse errors
- [ ] Create template `assets/data/countries.json` with sample data

**Acceptance Criteria:**
- Successfully loads countries from local JSON
- Throws `CacheException` on file/parse errors
- Sample data contains at least 20 countries

---

#### T-06: Repository Implementation
**Phase:** 1 - Foundation
**Dependencies:** T-04, T-05
**Parallel Group:** C

**Tasks:**
- [ ] Create `lib/data/repositories/country_repository_impl.dart`
- [ ] Implement `CountryRepository` interface
- [ ] Add remote-first strategy with local fallback
- [ ] Implement in-memory caching of fetched countries
- [ ] Add error handling and logging

**Acceptance Criteria:**
- Returns countries from API when available
- Falls back to local data on API failure
- Caches results after first successful fetch
- Throws `NoDataException` if both sources fail

---

#### T-07: Domain Entity & Repository Interface
**Phase:** 2 - Domain Layer
**Dependencies:** T-03
**Parallel Group:** C

**Tasks:**
- [ ] Create `lib/domain/entities/country_entity.dart`
- [ ] Implement `CountryEntity` with `name` and `isoCode`
- [ ] Add `fromModel()` factory constructor
- [ ] Create `lib/domain/repositories/country_repository.dart`
- [ ] Define abstract `CountryRepository` interface with `getCountries()`

**Acceptance Criteria:**
- Entity is independent of data layer
- Repository interface is properly abstracted
- `flutter analyze` passes

---

#### T-08: GetCountries Use Case
**Phase:** 2 - Domain Layer
**Dependencies:** T-06, T-07
**Parallel Group:** D

**Tasks:**
- [ ] Create `lib/domain/usecases/get_countries.dart`
- [ ] Implement `GetCountries` class with `call()` method
- [ ] Inject `CountryRepository` via constructor
- [ ] Return `Future<List<CountryEntity>>`

**Acceptance Criteria:**
- Successfully retrieves countries from repository
- Returns empty list if no countries available
- Unit tests pass with mocked repository

---

#### T-09: GenerateQuestion Use Case
**Phase:** 2 - Domain Layer
**Dependencies:** T-07
**Parallel Group:** D

**Tasks:**
- [ ] Create `lib/domain/usecases/generate_question.dart`
- [ ] Define `Question` class with `correctCountry` and `options`
- [ ] Implement random country selection excluding recently used
- [ ] Implement distractor selection (3 random different countries)
- [ ] Shuffle options randomly
- [ ] Add `usedCountryCodes` parameter to avoid repeats

**Acceptance Criteria:**
- Always returns 4 unique options
- Correct answer is always in options
- No repeated questions in last 10 rounds
- Options are randomly shuffled

---

#### T-10: CheckAnswer Use Case
**Phase:** 2 - Domain Layer
**Dependencies:** T-07
**Parallel Group:** D

**Tasks:**
- [ ] Create `lib/domain/usecases/check_answer.dart`
- [ ] Define `AnswerResult` with `isCorrect`, `pointsEarned`, `attemptsRemaining`
- [ ] Implement answer validation logic
- [ ] Implement scoring: 10 pts (1st), 8 pts (2nd), 5 pts (3rd), 0 pts (fail)
- [ ] Return `AnswerResult` with all relevant data

**Acceptance Criteria:**
- Correct answer returns `isCorrect: true`
- Points awarded based on attempt number
- Attempts remaining decremented on wrong answer
- Returns 0 points when all attempts exhausted

---

#### T-11: Unit Tests - Models & Use Cases
**Phase:** 2 - Domain Layer
**Dependencies:** T-08, T-09, T-10
**Parallel Group:** E

**Tasks:**
- [ ] Create `test/unit/models/country_test.dart`
- [ ] Test JSON parsing for both API v5 and local formats
- [ ] Test `flagUrl` getter
- [ ] Test value equality
- [ ] Create `test/unit/usecases/generate_question_test.dart`
- [ ] Test question generation with mocked countries
- [ ] Test option uniqueness and count
- [ ] Test used country exclusion
- [ ] Create `test/unit/usecases/check_answer_test.dart`
- [ ] Test correct answer detection
- [ ] Test point calculation for each attempt
- [ ] Test attempts remaining logic

**Acceptance Criteria:**
- All unit tests pass
- Code coverage > 80% for models and use cases
- Edge cases covered (empty lists, duplicates, etc.)

---

#### T-12: GameViewModel Implementation
**Phase:** 3 - ViewModel
**Dependencies:** T-08, T-09, T-10
**Parallel Group:** E

**Tasks:**
- [ ] Create `lib/presentation/providers/game_provider.dart`
- [ ] Implement `GameViewModel` extending `ChangeNotifier`
- [ ] Add all state fields (status, score, attempts, question, etc.)
- [ ] Implement `initialize()` method
- [ ] Implement `answerQuestion()` method
- [ ] Implement `nextQuestion()` method
- [ ] Implement `resetGame()` method
- [ ] Add `GameStatus` enum
- [ ] Add proper `notifyListeners()` calls

**Acceptance Criteria:**
- All state transitions work correctly
- Score calculation is accurate
- Attempts decrement properly
- Game over triggers after 3 wrong answers
- `flutter analyze` passes

---

#### T-13: Unit Tests - ViewModel
**Phase:** 3 - ViewModel
**Dependencies:** T-12
**Parallel Group:** F

**Tasks:**
- [ ] Create `test/unit/viewmodels/game_viewmodel_test.dart`
- [ ] Test initial state
- [ ] Test `initialize()` with mocked use cases
- [ ] Test `answerQuestion()` for correct answer
- [ ] Test `answerQuestion()` for wrong answer
- [ ] Test attempts remaining after wrong answers
- [ ] Test game over after 3 wrong answers
- [ ] Test `nextQuestion()` generates new question
- [ ] Test `resetGame()` resets all state
- [ ] Test score accumulation across multiple questions

**Acceptance Criteria:**
- All ViewModel unit tests pass
- Code coverage > 80% for ViewModel
- All state transitions tested

---

#### T-14: Splash Screen
**Phase:** 4 - UI Core Game
**Dependencies:** T-02, T-12
**Parallel Group:** F

**Tasks:**
- [ ] Create `lib/presentation/screens/splash_screen.dart`
- [ ] Implement loading indicator with progress message
- [ ] Call `GameViewModel.initialize()` on init
- [ ] Navigate to Home on success
- [ ] Show error state with retry button on failure
- [ ] Add app logo/branding

**Acceptance Criteria:**
- Displays loading indicator while fetching data
- Navigates to Home screen automatically on success
- Shows error message and retry button on failure
- Smooth transition animation

---

#### T-15: Home Screen
**Phase:** 4 - UI Core Game
**Dependencies:** T-02, T-12
**Parallel Group:** F

**Tasks:**
- [ ] Create `lib/presentation/screens/home_screen.dart`
- [ ] Implement app title and branding
- [ ] Add "Start Game" button
- [ ] Display high score from SharedPreferences
- [ ] Add brief game instructions
- [ ] Navigate to GameScreen on start

**Acceptance Criteria:**
- Displays app title and logo
- Shows high score if available
- "Start Game" button navigates to GameScreen
- Clean, inviting UI

---

#### T-16: FlagDisplay Widget
**Phase:** 4 - UI Core Game
**Dependencies:** T-02
**Parallel Group:** F

**Tasks:**
- [ ] Create `lib/presentation/widgets/flag_display.dart`
- [ ] Use `CachedNetworkImage` for flag loading
- [ ] Implement loading state with `CircularProgressIndicator`
- [ ] Implement error state with placeholder icon
- [ ] Add rounded corners and shadow styling
- [ ] Make size configurable

**Acceptance Criteria:**
- Flag image loads from CDN URL
- Loading indicator shows while image loads
- Error state shows placeholder on failure
- Image is properly sized and styled

---

#### T-17: AnswerButton Widget
**Phase:** 4 - UI Core Game
**Dependencies:** T-02
**Parallel Group:** F

**Tasks:**
- [ ] Create `lib/presentation/widgets/answer_button.dart`
- [ ] Implement button with country name text
- [ ] Add states: default, correct, wrong, disabled
- [ ] Color-code: green (correct), red (wrong), gray (disabled)
- [ ] Add tap handler callback
- [ ] Add smooth color transition animation
- [ ] Make button size responsive

**Acceptance Criteria:**
- Displays country name correctly
- Shows correct color for each state
- Disabled state prevents tapping
- Animations are smooth

---

#### T-18: AnswerOptionsGrid Widget
**Phase:** 4 - UI Core Game
**Dependencies:** T-17
**Parallel Group:** G

**Tasks:**
- [ ] Create `lib/presentation/widgets/answer_options_grid.dart`
- [ ] Implement 2x2 grid layout
- [ ] Accept list of countries and selection state
- [ ] Handle answer selection callback
- [ ] Disable answered options
- [ ] Highlight correct/wrong selections

**Acceptance Criteria:**
- Displays 4 options in 2x2 grid
- Handles answer selection correctly
- Disables options after answering
- Highlights correct/wrong answers

---

#### T-19: ScoreBoard Widget
**Phase:** 4 - UI Core Game
**Dependencies:** T-02
**Parallel Group:** G

**Tasks:**
- [ ] Create `lib/presentation/widgets/score_board.dart`
- [ ] Display current score with icon
- [ ] Add animated score change effect
- [ ] Make score prominently visible
- [ ] Add question counter display

**Acceptance Criteria:**
- Score displays correctly
- Animates on score change
- Question number shows correctly
- Visually appealing design

---

#### T-20: AttemptsIndicator Widget
**Phase:** 4 - UI Core Game
**Dependencies:** T-02
**Parallel Group:** G

**Tasks:**
- [ ] Create `lib/presentation/widgets/attempts_indicator.dart`
- [ ] Display 3 visual indicators (dots/hearts/icons)
- [ ] Update indicators based on attempts remaining
- [ ] Add animation when attempt is lost
- [ ] Make visually clear and intuitive

**Acceptance Criteria:**
- Shows 3 indicators initially
- Decrements on wrong answer
- Animation plays on attempt loss
- Clear visual feedback

---

#### T-21: GameScreen Assembly
**Phase:** 4 - UI Core Game
**Dependencies:** T-14, T-15, T-16, T-18, T-19, T-20
**Parallel Group:** H

**Tasks:**
- [ ] Create `lib/presentation/screens/game_screen.dart`
- [ ] Assemble all game widgets (FlagDisplay, AnswerOptionsGrid, ScoreBoard, AttemptsIndicator)
- [ ] Wire up GameViewModel state
- [ ] Handle answer selection flow
- [ ] Show feedback overlay on answer
- [ ] Handle next question navigation
- [ ] Add "End Game" button in app bar

**Acceptance Criteria:**
- All widgets display correctly
- Answer selection works end-to-end
- Score updates in real-time
- Attempts indicator updates
- Smooth flow between questions

---

#### T-22: FeedbackOverlay Widget
**Phase:** 5 - UI Feedback & Polish
**Dependencies:** T-02
**Parallel Group:** H

**Tasks:**
- [ ] Create `lib/presentation/widgets/feedback_overlay.dart`
- [ ] Implement "Correct!" feedback with points earned
- [ ] Implement "Try again!" feedback
- [ ] Add slide/fade animation
- [ ] Auto-dismiss after configurable delay
- [ ] Show points earned animation

**Acceptance Criteria:**
- Shows correct feedback message
- Animates in and out smoothly
- Displays points earned
- Auto-dismisses after delay

---

#### T-23: RevealAnswer Widget
**Phase:** 5 - UI Feedback & Polish
**Dependencies:** T-02
**Parallel Group:** H

**Tasks:**
- [ ] Create `lib/presentation/widgets/reveal_answer.dart`
- [ ] Highlight correct answer in green
- [ ] Show "The correct answer is: [Country]" message
- [ ] Add "Next Question" button
- [ ] Add reveal animation

**Acceptance Criteria:**
- Correct answer is clearly highlighted
- Message displays correctly
- "Next Question" button appears
- Smooth reveal animation

---

#### T-24: GameOverScreen
**Phase:** 5 - UI Feedback & Polish
**Dependencies:** T-02, T-12
**Parallel Group:** H

**Tasks:**
- [ ] Create `lib/presentation/screens/game_over_screen.dart`
- [ ] Display final score prominently
- [ ] Show statistics (correct answers, total questions, accuracy)
- [ ] Add "Play Again" button
- [ ] Add "Home" button
- [ ] Save high score to SharedPreferences
- [ ] Add celebration animation for high scores

**Acceptance Criteria:**
- Final score displays correctly
- Statistics are accurate
- High score is saved
- Navigation works correctly

---

#### T-25: Screen Transitions & Navigation
**Phase:** 5 - UI Feedback & Polish
**Dependencies:** T-21, T-24
**Parallel Group:** I

**Tasks:**
- [ ] Configure named routes in `lib/app.dart`
- [ ] Add route generation logic
- [ ] Implement custom page transitions
- [ ] Add fade/slide transitions between screens
- [ ] Handle back button navigation
- [ ] Add navigation guards (prevent going back during game)

**Acceptance Criteria:**
- All routes work correctly
- Transitions are smooth
- Back button behavior is correct
- Navigation flow is intuitive

---

#### T-26: Local JSON Fallback Data
**Phase:** 6 - Data & API
**Dependencies:** T-05
**Parallel Group:** I

**Tasks:**
- [ ] Create comprehensive `assets/data/countries.json`
- [ ] Include at least 50 countries with accurate data
- [ ] Validate JSON format matches expected structure
- [ ] Test local data source with new file
- [ ] Add data validation in repository

**Acceptance Criteria:**
- JSON file contains 50+ countries
- All countries have valid ISO codes
- Local data source loads successfully
- Data matches API format

---

#### T-27: API Key Configuration
**Phase:** 6 - Data & API
**Dependencies:** T-04
**Parallel Group:** I

**Tasks:**
- [ ] Create `lib/core/constants/api_config.dart`
- [ ] Implement environment variable reading via `String.fromEnvironment`
- [ ] Add `--dart-define` support for API key
- [ ] Update API service to use configured key
- [ ] Add graceful fallback when no key is present
- [ ] Document API key setup in README

**Acceptance Criteria:**
- API key can be passed via `--dart-define`
- App works without API key (uses local data)
- API key is not hardcoded in source
- Documentation is clear

---

#### T-28: Error Handling & Retry Logic
**Phase:** 6 - Data & API
**Dependencies:** T-06, T-21
**Parallel Group:** J

**Tasks:**
- [ ] Add try-catch blocks in repository with fallback
- [ ] Implement retry logic with exponential backoff (3 retries)
- [ ] Add user-friendly error messages
- [ ] Show error banner/snackbar in UI
- [ ] Add "Retry" button for failed operations
- [ ] Log errors for debugging

**Acceptance Criteria:**
- API failures fall back to local data
- Retry logic works correctly
- User sees clear error messages
- App doesn't crash on errors

---

#### T-29: Connectivity Checking
**Phase:** 6 - Data & API
**Dependencies:** T-06
**Parallel Group:** J

**Tasks:**
- [ ] Add `connectivity_plus` dependency
- [ ] Create `lib/services/connectivity_service.dart`
- [ ] Implement network status checking
- [ ] Show offline indicator in UI
- [ ] Auto-retry when connection restored
- [ ] Cache data for offline play

**Acceptance Criteria:**
- Detects network connectivity changes
- Shows offline indicator when no connection
- Auto-retries when connection restored
- Works offline with cached/local data

---

#### T-30: Widget Tests
**Phase:** 7 - Testing & Quality
**Dependencies:** T-21, T-22, T-23
**Parallel Group:** K

**Tasks:**
- [ ] Create `test/widget/flag_display_test.dart`
- [ ] Test loading, loaded, and error states
- [ ] Create `test/widget/answer_button_test.dart`
- [ ] Test tap, disabled, and color states
- [ ] Create `test/widget/game_screen_test.dart`
- [ ] Test full game flow simulation
- [ ] Test answer selection and feedback
- [ ] Test score updates
- [ ] Test game over flow

**Acceptance Criteria:**
- All widget tests pass
- UI behaves as expected under test
- Animations don't break tests
- Test coverage > 70% for widgets

---

#### T-31: Integration Tests
**Phase:** 7 - Testing & Quality
**Dependencies:** T-25, T-28
**Parallel Group:** L

**Tasks:**
- [ ] Create `test/integration/game_flow_test.dart`
- [ ] Test complete game: Start → Answer → Next → Game Over → Replay
- [ ] Test API data fetching and parsing
- [ ] Test local fallback when API unavailable
- [ ] Test error handling and recovery
- [ ] Test navigation flow

**Acceptance Criteria:**
- Full game flow works end-to-end
- API integration works correctly
- Fallback mechanism works
- All navigation paths tested

---

#### T-32: Performance Optimization
**Phase:** 7 - Testing & Quality
**Dependencies:** T-31
**Parallel Group:** M

**Tasks:**
- [ ] Optimize image loading and caching
- [ ] Reduce widget rebuilds with `const` constructors
- [ ] Use `Consumer` instead of `context.watch` where appropriate
- [ ] Optimize list rendering
- [ ] Profile app performance with DevTools
- [ ] Fix any performance issues found

**Acceptance Criteria:**
- App runs at 60fps
- No unnecessary widget rebuilds
- Image loading is optimized
- Memory usage is reasonable

---

#### T-33: App Icon & Splash Screen
**Phase:** 8 - Final Polish
**Dependencies:** T-25
**Parallel Group:** M

**Tasks:**
- [ ] Design and add app icon (Android & iOS)
- [ ] Configure `flutter_launcher_icons`
- [ ] Create native splash screen
- [ ] Configure `flutter_native_splash`
- [ ] Update `AndroidManifest.xml` and `Info.plist`
- [ ] Test on both platforms

**Acceptance Criteria:**
- App icon displays correctly on both platforms
- Splash screen shows on app launch
- No default Flutter icon remains
- Looks professional

---

#### T-34: Sound Effects & Haptic Feedback
**Phase:** 8 - Final Polish
**Dependencies:** T-25
**Parallel Group:** M

**Tasks:**
- [ ] Add sound effect files (correct, wrong, game over)
- [ ] Create `lib/services/sound_service.dart`
- [ ] Play sound on correct answer
- [ ] Play sound on wrong answer
- [ ] Play sound on game over
- [ ] Add haptic feedback on answer selection
- [ ] Add mute toggle in settings

**Acceptance Criteria:**
- Sounds play at appropriate times
- Haptic feedback works
- Mute toggle works
- Sounds are not annoying or too loud

---

#### T-35: Accessibility Support
**Phase:** 8 - Final Polish
**Dependencies:** T-25
**Parallel Group:** M

**Tasks:**
- [ ] Add semantic labels to all widgets
- [ ] Add tooltips to icon buttons
- [ ] Ensure color contrast meets WCAG AA
- [ ] Support screen readers (TalkBack/VoiceOver)
- [ ] Add accessibility text for flag images
- [ ] Test with accessibility tools

**Acceptance Criteria:**
- All widgets have semantic labels
- Screen reader announces content correctly
- Color contrast is sufficient
- App is usable with accessibility tools

---

#### T-36: Final UI/UX Review & Polish
**Phase:** 8 - Final Polish
**Dependencies:** T-30, T-31, T-32, T-33, T-34, T-35
**Parallel Group:** N

**Tasks:**
- [ ] Review all screens for visual consistency
- [ ] Ensure consistent spacing and typography
- [ ] Add micro-interactions and polish
- [ ] Test on multiple screen sizes
- [ ] Test on both light and dark themes (if supported)
- [ ] Final `flutter analyze` check
- [ ] Update README with screenshots and instructions

**Acceptance Criteria:**
- UI is visually consistent across all screens
- No layout issues on different screen sizes
- All animations are smooth
- `flutter analyze` passes with no warnings
- README is complete and accurate

---

### Execution Order Summary

```
Week 1:  Group A (T-01, T-02, T-03)
Week 1:  Group B (T-04, T-05) [parallel with A if team allows]
Week 2:  Group C (T-06, T-07)
Week 2:  Group D (T-08, T-09, T-10)
Week 3:  Group E (T-11, T-12)
Week 3:  Group F (T-13, T-14, T-15, T-16, T-17)
Week 4:  Group G (T-18, T-19, T-20)
Week 4:  Group H (T-21, T-22, T-23, T-24)
Week 5:  Group I (T-25, T-26, T-27)
Week 5:  Group J (T-28, T-29)
Week 6:  Group K (T-30)
Week 6:  Group L (T-31)
Week 7:  Group M (T-32, T-33, T-34, T-35)
Week 7:  Group N (T-36)
```

### Critical Path

```
T-01 → T-03 → T-04 → T-06 → T-08 → T-12 → T-21 → T-25 → T-28 → T-31 → T-36
```

The critical path represents the minimum sequence of tickets that must be completed in order. All other tickets can be parallelized around this path.

---

*This document serves as the single source of truth for the Country Trivia app architecture and implementation plan.*
