---
name: naming_standards
description: Cross-language naming conventions for variables, functions, files, and branches
type: rules
source: js-modern-patterns/SKILL.md + python-patterns/SKILL.md + best practices
---

# Naming Standards

## Files

| Language | Convention | Example |
|----------|------------|---------|
| JavaScript/TypeScript | kebab-case | `user-profile.ts`, `api-utils.js` |
| Python | snake_case | `user_profile.py`, `api_utils.py` |
| Go | snake_case or PascalCase | `user_profile.go`, `UserService.go` |
| Markdown / Config | kebab-case | `project-overview.md`, `.env.example` |
| React Components | PascalCase | `UserProfile.tsx`, `TaskList.jsx` |
| Tests | co-located with source, suffixed `.test` | `auth.test.ts` next to `auth.ts` |

**Rules:**
- Never use spaces or special characters in filenames
- Index files: `index.ts`, `__init__.py` (language convention)
- Configuration files: dot-prefixed (`.env`, `.gitignore`, `.eslintrc`)

---

## Variables & Functions

### JavaScript / TypeScript

```
// Variables: camelCase
const userProfile = ...
const isAuthenticated = ...
const taskList = []

// Functions: camelCase verb phrase
function getUserById(id) { ... }
function validateEmail(email) { ... }
async function fetchTasks() { ... }

// Constants: SCREAMING_SNAKE_CASE
const MAX_RETRY_COUNT = 3
const API_BASE_URL = 'https://api.example.com'

// Classes/Types/Interfaces: PascalCase
interface UserProfile { ... }
type TaskStatus = 'pending' | 'completed'
class TaskService { ... }
```

### Python

```
# Variables and functions: snake_case
user_profile = ...
is_authenticated = ...
task_list = []

def get_user_by_id(user_id):
    ...

async def fetch_tasks():
    ...

# Classes: PascalCase
class UserProfile:
    ...

# Constants: SCREAMING_SNAKE_CASE
MAX_RETRY_COUNT = 3
API_BASE_URL = 'https://api.example.com'
```

---

## Git Branches

```
feature/short-description
fix/issue-number-short-description
chore/task-description
release/v1.2.0
hotfix/critical-bug
```

**Rules:**
- All lowercase, kebab-case
- Include issue number for fixes when available
- No spaces, no camelCase, no underscores as separators

---

## API Endpoints

```
# RESTful: kebab-case, plural nouns
POST   /task-list          (create)
GET    /task-list          (list)
GET    /task-list/{id}      (get one)
PUT    /task-list/{id}      (update)
DELETE /task-list/{id}      (delete)

# NOT:
/createTask
/GetTasks
/taskList
```

---

## Database Tables & Columns

```
-- Tables: plural snake_case
CREATE TABLE user_profiles (...);
CREATE TABLE task_lists (...);

-- Columns: snake_case
user_id, created_at, is_active, task_status
```

---

## Why

Consistent naming makes code scannable. `git log --oneline` and grep become useful when conventions are predictable.

---

## How to Apply

1. Before writing any code, check the convention for the language/role
2. Linters (ESLint, flake8) should be configured to enforce naming
3. If a linter rule conflicts with this standard, surface the conflict and ask
4. For new languages not in this guide, default to the dominant convention in the project
