# AGENTS.md

## Repo

Flutter country trivia game. MVVM + Provider. SDK `^3.12.2`.

## Commands

```bash
flutter pub get          # install deps
flutter analyze          # lint (zero issues expected)
flutter test             # all tests
flutter test test/path/  # single test file
```

## Branching & PRs

- Feature branches target `develop` (not `master`)
- PRs created via `gh pr create --base develop --head feature/T-XX-...`
- Git auth configured via `gh auth setup-git`

## Key Files

- `docs/master_plan.md` — architecture, 36 execution tickets, parallel groups
- `lib/main.dart` — app entry point
- `pubspec.yaml` — dependencies, assets

## Architecture

MVVM with Provider. Layers: `data/` (models, datasources, repositories) → `domain/` (entities, usecases) → `presentation/` (ViewModels, screens, widgets). See master plan for full structure.

## Data

- Countries: REST Countries v5 API (`api.restcountries.com/countries/v5`) or local JSON fallback
- Flags: `https://flagcdn.com/w320/{iso}.png`
- API key via `--dart-define=REST_COUNTRIES_API_KEY=...` (falls back to local data if unset)

## Conventions

- Linting: `flutter_lints` (no custom rules yet)
- Tests mirror `lib/` structure under `test/`
