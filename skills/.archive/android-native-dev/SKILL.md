---
name: android-native-dev
description: Android native application development and UI design guide. Covers Material Design 3, Kotlin/Compose development, project configuration, accessibility, and build troubleshooting. Read this before Android native application development.
tags: [mobile, android, kotlin, compose]
tags: [android, kotlin, compose, material-design, mobile, gradle]
---

## When to Use

- Building Android native applications with Kotlin
- Implementing Jetpack Compose UI components
- Configuring Gradle build variants and product flavors
- Applying Material Design 3 guidelines and specifications
- Setting up Android testing with JUnit, Espresso, or Compose UI Test
- Scaffolding a new Android project from scratch
- Debugging build errors and dependency conflicts

## Do Not Use

- Cross-platform projects (use Flutter, React Native, or Compose Multiplatform)
- iOS-only or web-only projects
- Backend/server-side Kotlin development (use Ktor, Spring Boot)
- Generic UI/UX design without Android-specific context
- Low-level Android NDK/C++ development without Kotlin/Compose

# Android Native Development

## 1. Project Scenario Assessment

| Scenario | Characteristics | Approach |
|----------|-----------------|----------|
| Empty Directory | No files present | Full init including Gradle Wrapper |
| Has Gradle Wrapper | `gradlew` exists | Use `./gradlew` directly |
| Android Studio Project | Complete structure | Check wrapper, run `gradle wrapper` if needed |
| Incomplete Project | Partial files | Check missing files, complete configuration |

**Key:** Before business logic, ensure `./gradlew assembleDebug` succeeds.

### Required Files Checklist
```
MyApp/
├── gradle.properties          # Configure AndroidX
├── settings.gradle.kts
├── build.gradle.kts           # Root level
├── gradle/wrapper/gradle-wrapper.properties
├── app/
│   ├── build.gradle.kts       # Module level
│   └── src/main/
│       ├── AndroidManifest.xml
│       ├── java/com/example/myapp/MainActivity.kt
│       └── res/values/{strings,colors,themes}.xml
```

## 2. Project Configuration

### gradle.properties
```properties
android.useAndroidX=true
android.enableJetifier=true
org.gradle.parallel=true
kotlin.code.style=official
# org.gradle.jvmargs=-Xmx4096m -Dfile.encoding=UTF-8
```

### Dependency Declaration
```kotlin
dependencies {
    implementation(platform("androidx.compose:compose-bom:2024.02.00"))
    implementation("androidx.compose.ui:ui")
    implementation("androidx.compose.material3:material3")
    implementation("androidx.activity:activity-compose:1.8.2")
    implementation("androidx.lifecycle:lifecycle-viewmodel-compose:2.7.0")
}
```

### Build Variants & Product Flavors
→ See `references/build-variants.md` for flavors, build commands, BuildConfig access, and source sets.

## 3. Kotlin Development Standards
→ See `references/kotlin-standards.md` for:
- Naming conventions, null safety, exception handling
- Threading & coroutines (Dispatchers, ViewModel patterns)
- Visibility rules, common syntax pitfalls
- Server response data class rules, lifecycle management, logging

## 4. Jetpack Compose Standards
→ See `references/compose-standards.md` for:
- `@Composable` context rules, LaunchedEffect
- State management (mutableStateOf, StateFlow, derivedStateOf)
- Common Compose mistakes

## 5. Resources & Icons
→ See `references/resources-icons.md` for:
- Multi-resolution icon requirements (mdpi→xxxhdpi)
- Adaptive icon XML, resource naming conventions
- Android reserved names to avoid

## 6. Build Error Diagnosis & Fixes
→ See `references/build-errors.md` for:
- Common error table (Unresolved reference, Type mismatch, etc.)
- Fix best practices and debugging commands

## 7. Material Design 3 Guidelines

### Core Principles: Personal, Adaptive, Expressive, Accessible

### Quick Specifications

**Color Contrast:** Body text ≥4.5:1, Large text ≥3:1, UI components ≥3:1
**Touch Targets:** Minimum 48×48dp, Recommended 56×56dp, Kids 56dp+
**8dp Grid:** xs=4dp, sm=8dp, md=16dp, lg=24dp, xl=32dp, xxl=48dp
**Animation:** Micro 50-100ms, Short 100-200ms, Medium 200-300ms, Long 300-500ms

### Review Checklist
- [ ] 8dp spacing grid compliance
- [ ] 48dp minimum touch targets
- [ ] Proper typography scale usage
- [ ] Color contrast compliance (4.5:1+ for text)
- [ ] Dark theme support
- [ ] `contentDescription` on all interactive elements
- [ ] Startup < 2 seconds or shows progress
- [ ] Visual style matches app category

### Detailed References

| Topic | Reference |
|-------|-----------|
| Colors, Typography, Spacing, Shapes | [references/visual-design.md](references/visual-design.md) |
| Animation & Transitions | [references/motion-system.md](references/motion-system.md) |
| Accessibility Guidelines | [references/accessibility.md](references/accessibility.md) |
| Large Screens & Foldables | [references/adaptive-screens.md](references/adaptive-screens.md) |
| Performance & Stability | [references/performance-stability.md](references/performance-stability.md) |
| Privacy & Security | [references/privacy-security.md](references/privacy-security.md) |
| Audio, Video, Notifications | [references/functional-requirements.md](references/functional-requirements.md) |
| App Style by Category | [references/design-style-guide.md](references/design-style-guide.md) |

### App Style Selection

| App Category | Visual Style | Key Characteristics |
|---|---|---|
| Utility/Tool | Minimalist | Clean, neutral colors |
| Finance/Banking | Professional Trust | Conservative, security-focused |
| Health/Wellness | Calm & Natural | Soft colors, organic shapes |
| Kids (3-5) | Playful Simple | Bright colors, large targets (56dp+) |
| Kids (6-12) | Fun & Engaging | Vibrant, gamified feedback |
| Social/Entertainment | Expressive | Brand-driven, gesture-rich |
| Productivity | Clean & Focused | Minimal, high contrast |
| E-commerce | Conversion-focused | Clear CTAs, scannable |

## 8. Testing

> **Note**: Add test dependencies only when explicitly requested.

A well-tested Android app uses layered testing: fast local unit tests for logic, instrumentation tests for UI and integration, and Gradle Managed Devices for CI.

### Version Alignment Rules
| Test Dependency | Must Align With |
|---|---|
| `kotlinx-coroutines-test` | Project's `kotlinx-coroutines-core` version |
| `compose-ui-test-junit4` | Project's Compose BOM |
| `espresso-*` | All Espresso artifacts same version |
| `mockk` | Project's Kotlin version |

### Test Commands
```bash
./gradlew testDebugUnitTest                    # Local unit tests
./gradlew connectedDebugAndroidTest            # On connected device
./gradlew test connectedDebugAndroidTest       # Both
```

### Detailed References
- [references/testing.md](references/testing.md) — Full dependency reference, test types by layer, code patterns, Gradle Managed Device config
- [references/kotlin-standards.md](references/kotlin-standards.md) — Coroutines, null safety, lifecycle patterns

### Android Ecosystem
- **DI**: Hilt, Koin, Kodein
- **Networking**: Retrofit, Ktor, OkHttp, Apollo GraphQL
- **Storage**: Room, DataStore, Realm, SQLDelight
- **Compose**: material3, compose-navigation, compose-animation
- **Image**: Coil, Glide, Picasso, Landscapist
- **Testing**: JUnit, MockK, Espresso, Compose UI Test, Robolectric
- **Architecture**: MVI, MVVM, Clean Architecture, UseCases, Repository

## Verification

- [ ] `./gradlew assembleDebug` succeeds
- [ ] Generated app installs and runs on device/emulator
- [ ] Build variants compile individually (`assembleDevDebug`, `assembleProdRelease`)
- [ ] All reference links in this file resolve to existing files
