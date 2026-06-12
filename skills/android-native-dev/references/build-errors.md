# Build Error Diagnosis & Fixes

## Common Error Quick Reference

| Error Keyword | Cause | Fix |
|---------------|-------|------|
| `Unresolved reference` | Missing import or undefined | Check imports, verify dependencies |
| `Type mismatch` | Type incompatibility | Check parameter types, add conversion |
| `Cannot access` | Visibility issue | Check public/private/internal |
| `@Composable invocations` | Composable context error | Ensure caller is also @Composable |
| `Duplicate class` | Dependency conflict | Use `./gradlew dependencies` to investigate |
| `AAPT: error` | Resource file error | Check XML syntax and resource references |

## Fix Best Practices

1. **Read the complete error message first**: Locate file and line number
2. **Check recent changes**: Problems usually in latest modifications
3. **Clean Build**: `./gradlew clean assembleDebug`
4. **Check dependency versions**: Version conflicts are common causes
5. **Refresh dependencies if needed**: Clear cache and rebuild

## Debugging Commands

```bash
# Clean and build
./gradlew clean assembleDebug

# View dependency tree (investigate conflicts)
./gradlew :app:dependencies

# View detailed errors
./gradlew assembleDebug --stacktrace

# Refresh dependencies
./gradlew --refresh-dependencies
```
