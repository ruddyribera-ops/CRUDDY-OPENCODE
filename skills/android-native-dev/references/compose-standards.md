# Jetpack Compose Standards

## @Composable Context Rules
```kotlin
// ❌ Wrong: Calling Composable from non-Composable function
fun showError(message: String) { Text(message) }  // Compile error!

// ✅ Correct: Mark as @Composable
@Composable fun ErrorMessage(message: String) { Text(message) }

// ❌ Wrong: Using suspend outside LaunchedEffect
@Composable fun MyScreen() { val data = fetchData() }  // Error!

// ✅ Correct: Use LaunchedEffect
@Composable fun MyScreen() {
    var data by remember { mutableStateOf<Data?>(null) }
    LaunchedEffect(Unit) { data = fetchData() }
}
```

## State Management
```kotlin
// Basic State
var count by remember { mutableStateOf(0) }

// Derived State (avoid redundant computation)
val isEven by remember { derivedStateOf { count % 2 == 0 } }

// Persist across recomposition
val scrollState = rememberScrollState()

// State in ViewModel
class MyViewModel : ViewModel() {
    private val _uiState = MutableStateFlow(UiState())
    val uiState: StateFlow<UiState> = _uiState.asStateFlow()
}
```

## Common Compose Mistakes
```kotlin
// ❌ Wrong: Creating objects in Composable (created on every recomposition)
@Composable fun MyScreen() { val viewModel = MyViewModel() }

// ✅ Correct: Use viewModel() or remember
@Composable fun MyScreen(viewModel: MyViewModel = viewModel()) { }
```
