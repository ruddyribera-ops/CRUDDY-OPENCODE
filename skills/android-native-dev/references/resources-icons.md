# Resources & Icons

## App Icon Requirements

| Directory | Size | Purpose |
|-----------|------|---------|
| mipmap-mdpi | 48x48 | Baseline |
| mipmap-hdpi | 72x72 | 1.5x |
| mipmap-xhdpi | 96x96 | 2x |
| mipmap-xxhdpi | 144x144 | 3x |
| mipmap-xxxhdpi | 192x192 | 4x |

### Adaptive Icons (Android 8+)
```xml
<!-- res/mipmap-anydpi-v26/ic_launcher.xml -->
<adaptive-icon>
    <background android:drawable="@color/ic_launcher_background"/>
    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>
</adaptive-icon>
```

## Resource Naming Conventions

| Type | Prefix | Example |
|------|--------|---------|
| Layout | layout_ | `layout_main.xml` |
| Image | ic_, img_, bg_ | `ic_user.png` |
| Color | color_ | `color_primary` |
| String | - | `app_name`, `btn_submit` |

## Avoid Android Reserved Names

Variable names, resource IDs, colors, icons, and XML elements **must not** use Android reserved words.

| Category | Avoid These |
|----------|-------------|
| Colors | `background`, `foreground`, `transparent`, `white`, `black` |
| Icons/Drawables | `icon`, `logo`, `image`, `drawable` |
| Views | `view`, `text`, `button`, `layout`, `container` |
| Attributes | `id`, `name`, `type`, `style`, `theme`, `color` |
| System | `app`, `android`, `content`, `data`, `action` |

```xml
<!-- ❌ Wrong: Using reserved names -->
<color name="background">#FFFFFF</color>
<!-- ✅ Correct: Add prefix -->
<color name="app_background">#FFFFFF</color>
```

```kotlin
// ❌ Wrong: Variable names conflict with system
val icon = R.drawable.my_icon
// ✅ Correct: Use descriptive names
val appIcon = R.drawable.my_icon
```
