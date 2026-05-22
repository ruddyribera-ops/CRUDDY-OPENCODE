---
name: react-native-dev
description: Cross-platform mobile development with React Native, JavaScript/TypeScript, and native module integration.
tags: [mobile, react-native, javascript, frontend]
---

# React Native & Expo Development Guide

## When to Use
- Build cross-platform mobile apps with React Native
- Implement React Native UI, navigation, or state management
- Debug React Native build or runtime issues
- Integrate native modules with React Native

## Do Not Use
- Native Android development (use android-native-dev)
- Native iOS development (use ios-application-dev)
- Flutter development (use flutter-dev)
- Web-only React development (use frontend-dev)

A practical guide for building production-ready React Native and Expo applications.

## References
Consult these as needed:
- `references/navigation.md` — Expo Router: Stack, Tabs, NativeTabs, modals, sheets
- `references/components.md` — FlashList, expo-image, safe areas, native controls
- `references/styling.md` — StyleSheet, NativeWind, theming, dark mode
- `references/animations.md` — Reanimated 3: entering/exiting, gestures, scroll-driven
- `references/state-management.md` — Zustand, Jotai, React Query, Context
- `references/forms.md` — React Hook Form + Zod
- `references/networking.md` — fetch, React Query, auth tokens, offline
- `references/performance.md` — profiling, FlashList, bundle analysis
- `references/testing.md` — Jest, RNTL, Maestro
- `references/native-capabilities.md` — Camera, location, permissions, biometrics
- `references/engineering.md` — project layout, SDK upgrades, EAS, CI/CD
- `references/ecosystem.md` — full library ecosystem listing

## Quick Reference

### Component Preferences
| Purpose | Use | Instead of |
|---------|-----|------------|
| Lists | `FlashList` + `memo` | `FlatList` |
| Images | `expo-image` | RN `<Image>` |
| Press | `Pressable` | `TouchableOpacity` |
| Audio | `expo-audio` | `expo-av` (deprecated) |
| Video | `expo-video` | `expo-av` (deprecated) |
| Animations | Reanimated 3 | RN Animated API |
| Gestures | Gesture Handler | PanResponder |
| Platform check | `process.env.EXPO_OS` | `Platform.OS` |
| Safe area scroll | `contentInsetAdjustmentBehavior="automatic"` | `<SafeAreaView>` |

### State Management
| State Type | Solution |
|------------|----------|
| Local UI state | `useState` / `useReducer` |
| Shared app state | Zustand or Jotai |
| Server / async data | React Query |
| Form state | React Hook Form + Zod |

### Performance Priorities
| Priority | Issue | Fix |
|----------|-------|-----|
| CRITICAL | Long list jank | `FlashList` + memoized items |
| CRITICAL | Large bundle | Avoid barrel imports, enable R8 |
| HIGH | Too many re-renders | Zustand selectors, React Compiler |
| HIGH | Slow startup | Disable bundle compression, native nav |
| MEDIUM | Animation drops | Only animate `transform`/`opacity` |

## New Project Init
```bash
npx create-expo-app@latest my-app --template blank-typescript
cd my-app
npx expo install expo-router react-native-safe-area-context react-native-screens
```

See `references/engineering.md` for full setup.

## Core Principles
- **Consult references before writing** — read matching reference file for patterns and pitfalls
- **Try Expo Go first** (`npx expo start`). Custom builds only when needed
- **Animation rule**: only animate `transform` and `opacity`
- **Imports**: always import directly from source, not barrel files
- **Lists**: `FlashList` and `expo-image` are almost always the right choice
- **Route files**: kebab-case, never co-locate components in `app/`

## Checklist
- [ ] `tsconfig.json` path aliases configured
- [ ] `EXPO_PUBLIC_API_URL` env var set per environment
- [ ] Root layout has `GestureHandlerRootView` (if gestures)
- [ ] `contentInsetAdjustmentBehavior="automatic"` on scroll views
- [ ] `FlashList` instead of `FlatList` for lists > 20 items
- [ ] Profile in `--profile` mode, fix frames > 16ms
- [ ] Bundle analyzed, no barrel imports
- [ ] E2E flows for login, core feature
