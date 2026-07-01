# Kotlin Development Standards

## Naming Conventions

| Type | Convention | Example |
|------|------------|---------|
| Class/Interface | PascalCase | `UserRepository`, `MainActivity` |
| Function/Variable | camelCase | `getUserName()`, `isLoading` |
| Constant | SCREAMING_SNAKE | `MAX_RETRY_COUNT` |
| Package | lowercase | `com.example.myapp` |
| Composable | PascalCase | `@Composable fun UserCard()` |

## Null Safety
```kotlin
// ❌ Avoid: Non-null assertion !! (may crash)
val name = user!!.name

// ✅ Recommended: Safe call + default value
val name = user?.name ?: "Unknown"

// ✅ Recommended: let handling
user?.let { processUser(it) }
```

## Exception Handling
```kotlin
// ❌ Avoid: Random try-catch swallowing exceptions
fun loadData() { try { api.fetch() } catch (e: Exception) { } }

// ✅ Recommended: Wrap and propagate
suspend fun loadData(): Result<Data> {
    return try { Result.success(api.fetch()) }
    catch (e: Exception) { Result.failure(e) }
}

// ✅ Recommended: Unified handling in ViewModel
viewModelScope.launch {
    runCatching { repository.loadData() }
        .onSuccess { _uiState.value = UiState.Success(it) }
        .onFailure { _uiState.value = UiState.Error(it.message) }
}
```

## Threading & Coroutines

| Operation Type | Thread | Description |
|----------------|--------|-------------|
| UI Updates | `Dispatchers.Main` | Update View, State, LiveData |
| Network Requests | `Dispatchers.IO` | HTTP calls, API requests |
| File I/O | `Dispatchers.IO` | Local storage, database operations |
| Compute Intensive | `Dispatchers.Default` | JSON parsing, sorting, encryption |

```kotlin
// In ViewModel
viewModelScope.launch {
    _uiState.value = UiState.Loading
    val result = withContext(Dispatchers.IO) { repository.fetchData() }
    _uiState.value = UiState.Success(result)
}

// In Repository — suspend functions should be main-safe
suspend fun fetchData(): Data = withContext(Dispatchers.IO) { api.getData() }
```

**Common Mistakes:**
```kotlin
// ❌ Wrong: Updating UI on IO thread
viewModelScope.launch(Dispatchers.IO) { _uiState.value = data }

// ❌ Wrong: Time-consuming operation on Main thread
viewModelScope.launch { val data = api.fetch() }  // ANR risk

// ✅ Correct
viewModelScope.launch { val data = withContext(Dispatchers.IO) { api.fetch() }; _uiState.value = data }
```

## Visibility Rules
```kotlin
class UserRepository {           // public
    private val cache = mutableMapOf<String, User>()  // Within class only
    internal fun clearCache() {} // Within module only
}
```

## Common Syntax Pitfalls
```kotlin
// ❌ Wrong: Accessing uninitialized lateinit
class MyVM : ViewModel() { lateinit var data: String; fun process() = data.length }

// ✅ Correct: Use nullable or default value
class MyVM : ViewModel() { var data: String? = null; fun process() = data?.length ?: 0 }

// ❌ Wrong: return in lambda (returns from outer function!)
list.forEach { item -> if (item.isEmpty()) return }

// ✅ Correct: Use return@forEach
list.forEach { item -> if (item.isEmpty()) return@forEach }
```

## Server Response Data Class Fields Must Be Nullable
```kotlin
// ❌ Wrong: Non-null fields (server may not return them)
data class UserResponse(val id: String = "", val name: String = "", val avatar: String = "")

// ✅ Correct: All fields nullable
data class UserResponse(
    @SerializedName("id") val id: String? = null,
    @SerializedName("name") val name: String? = null,
    @SerializedName("avatar") val avatar: String? = null
)
```

## Lifecycle Resource Management
```kotlin
// ❌ Wrong: Only adding Observer, not removing (memory leak!)
class MyView : View {
    override fun onAttachedToWindow() { activity?.lifecycle?.addObserver(this) }
}

// ✅ Correct: Paired add and remove
class MyView : View {
    override fun onAttachedToWindow() { activity?.lifecycle?.addObserver(this) }
    override fun onDetachedFromWindow() { activity?.lifecycle?.removeObserver(this) }
}
```

## Logging Level Usage
```kotlin
Log.i(TAG, "loadData: started, userId = $userId")       // Normal flow
Log.w(TAG, "loadData: cache miss, fallback to network")  // Recoverable
Log.e(TAG, "loadData failed: ${error.message}")          // Failure/error
```
