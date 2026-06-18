---
name: flutter-dev
description: Flutter and Dart development — cross-platform mobile UI, widgets, state management, layouts, and debugging.
tags: [mobile, flutter, dart, frontend]
---

# Flutter Development Guide

## When to Use
- Build mobile apps using Flutter and Dart
- Create cross-platform UI with Flutter widgets
- Implement Flutter layouts, navigation, or state management
- Debug Flutter build issues or rendering problems

## Do Not Use
- Native Android development (use android-native-dev)
- Native iOS development (use ios-application-dev)
- React Native development (use react-native-dev)
- Web-only frontend development (use frontend-dev)

A practical guide for building cross-platform applications with Flutter 3 and Dart.

## Quick Reference

### Widget Patterns
| Purpose | Component |
|---------|-----------|
| State management (simple) | `StateProvider` + `ConsumerWidget` |
| State management (complex) | `NotifierProvider` / `Bloc` |
| Async data | `FutureProvider` / `AsyncNotifierProvider` |
| Real-time streams | `StreamProvider` |
| Navigation | `GoRouter` + `context.go/push` |
| Responsive layout | `LayoutBuilder` + breakpoints |
| List display | `ListView.builder` |
| Complex scrolling | `CustomScrollView` + Slivers |
| Hooks | `HookWidget` + `useState/useEffect` |
| Forms | `Form` + `TextFormField` + validation |

### Performance Patterns
| Purpose | Solution |
|---------|----------|
| Prevent rebuilds | `const` constructors |
| Selective updates | `ref.watch(provider.select(...))` |
| Isolate repaints | `RepaintBoundary` |
| Lazy lists | `ListView.builder` |
| Heavy computation | `compute()` isolate |
| Image caching | `cached_network_image` |

## Core Principles

### Widget Optimization
- Use `const` constructors wherever possible
- Extract static widgets to separate const classes
- Use `Key` for list items (ValueKey, ObjectKey)
- Prefer `ConsumerWidget` over `StatefulWidget` for state

### State Management
- Riverpod for dependency injection and simple state
- Bloc/Cubit for event-driven workflows and complex logic
- Never mutate state directly (create new instances)
- Use `select()` to minimize rebuilds

### Layout
- 8pt spacing increments (8, 16, 24, 32, 48)
- Responsive breakpoints: mobile (<650), tablet (650-1100), desktop (>1100)
- Support all screen sizes with flexible layouts
- Follow Material 3 / Cupertino design guidelines

### Performance
- Profile with DevTools before optimizing
- Target <16ms frame time for 60fps
- Use `RepaintBoundary` for complex animations
- Offload heavy work with `compute()`

## Checklist
- [ ] `const` constructors on all static widgets
- [ ] Proper `Key` on list items
- [ ] `ConsumerWidget` for state-dependent widgets
- [ ] Immutable state objects, `select()` for granular rebuilds
- [ ] GoRouter with typed routes + auth guards
- [ ] Profile mode testing (`flutter run --profile`)
- [ ] <16ms frame rendering time
- [ ] Widget tests + unit tests + integration tests

## References

| Topic | Reference |
|-------|-----------|
| Widget patterns, const optimization, responsive layout | `references/widget-patterns.md` |
| Riverpod providers, notifiers, async state | `references/riverpod-state.md` |
| Bloc, Cubit, event-driven state | `references/bloc-state.md` |
| GoRouter setup, routes, deep linking | `references/gorouter-navigation.md` |
| Feature-based structure, dependencies | `references/project-structure.md` |
| Profiling, const optimization, DevTools | `references/performance.md` |
| Widget tests, integration tests, mocking | `references/testing.md` |
| iOS/Android/Web specific implementations | `references/platform-specific.md` |
| Implicit/explicit animations, Hero, transitions | `references/animations.md` |
| Dio, interceptors, error handling, caching | `references/networking.md` |
| Form validation, FormField, input formatters | `references/forms.md` |
| i18n, flutter_localizations, intl | `references/localization.md` |
| Ecosystem library listing | `references/ecosystem.md` |

## See Also
- [Flutter Documentation](https://docs.flutter.dev)
- [Dart Documentation](https://dart.dev/guides)
- [pub.dev](https://pub.dev) — Flutter/Dart package repository
- [awesome-flutter](https://github.com/Solido/awesome-flutter)
