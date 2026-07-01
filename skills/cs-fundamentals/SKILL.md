---
name: cs-fundamentals
description: "Computer Science fundamentals — Machine Learning, NLP, Computer Vision, Algorithms, Cryptography, Static Analysis, and Theoretical CS. Use when building ML pipelines, implementing NLP systems, designing CV solutions, or working on academic CS problems. Triggers: algorithms, Big O, complexity, data structures, ML, NLP, CV, static analysis, cryptography, concurrency, machine learning."
triggers:
  - "cs-fundamentals"
  - "cs fundamentals"
  - "when to use cs fundamentals"
  - "how to cs fundamentals"
  - "cs fundamentals examples"
  - "cs fundamentals pattern"
applies_to:
  - "main-coordinator"
---


# CS Fundamentals

## When to use this

Load this skill when implementing algorithms, designing data structures, building ML pipelines, reviewing code for performance, working with concurrency, or solving academic CS problems.

---

## Core Principles

1. **Big O notation for hot paths** — Measure complexity on the code paths that run most frequently. A 10x improvement in a hot path matters more than a 100x improvement in a cold path.

2. **Choose the right data structure** — The choice of data structure determines the complexity of every operation. HashMap for O(1) lookup, tree for sorted iteration, heap for priority queues.

3. **Concurrency primitives are not interchangeable** — A mutex and a channel serve different purposes. A spinlock and a blocking queue have different performance characteristics under load.

4. **Static analysis complements testing** — Testing cannot prove the absence of bugs. Static analysis can find entire classes of bugs (null dereferences, memory leaks, race conditions) automatically.

5. **ML is not magic — it is math** — Understanding the underlying math (gradients, loss functions, regularization) is what separates effective ML practitioners from cargo-cult users.

6. **Cryptography requires expertise** — Symmetric vs. asymmetric encryption, streaming vs. block ciphers, MAC vs. signature — these are not interchangeable. Use established protocols (TLS 1.3, Argon2, ChaCha20-Poly1305).

7. **Premature optimization is the root of all evil** — Measure before optimizing. Profile to find the hot path. Optimize the hot path with the best algorithm, not micro-optimizations.

---

## Patterns

### Algorithmic Complexity (Big O Quick Reference)

| Complexity | Name | Example | When to Use |
|------------|------|---------|-------------|
| O(1) | Constant | HashMap lookup, array index | Fastest possible |
| O(log n) | Logarithmic | Binary search, balanced tree | Searching sorted data |
| O(n) | Linear | Array scan, linked list | Simple iteration |
| O(n log n) | Linearithmic | Merge sort, quicksort (avg) | Sorting |
| O(n^2) | Quadratic | Nested loops over same array | Avoid for large n |
| O(2^n) | Exponential | Power set, recursive fib | Avoid — use DP |
| O(n!) | Factorial | Permutations | Avoid — use combinatorial |

```python
# Identifying complexity in code:

# O(1) — Hash lookup
def get_user(users, user_id):
    return users[user_id]  # Dict lookup is O(1)

# O(n) — Linear scan
def find_user(users, email):
    for user in users:  # O(n) — scans entire list
        if user.email == email:
            return user
    return None

# O(n^2) — Nested loops (often accidental)
def find_duplicates(items):
    duplicates = []
    for i in items:       # O(n)
        for j in items:   # O(n) — nested = O(n^2)
            if i == j and i not in duplicates:
                duplicates.append(i)
    return duplicates
# Better: use a set — O(n)

# O(n log n) — Sorting-based approach
def sorted_unique(items):
    return sorted(set(items))  # set O(n), sort O(n log n)
```

### Data Structure Selection Guide

```python
# When to use which data structure:

# Dict / HashMap: O(1) lookup, O(1) insertion
# Use when: Key-value lookup, deduplication, counting frequencies
user_by_id = {user.id: user for user in users}

# List / Array: O(1) index, O(n) insert/delete at arbitrary position
# Use when: Ordered collection, index-based access, FIFO queue

# Set: O(1) lookup, O(1) insertion, no duplicates
# Use when: Deduplication, membership testing
active_ids = set(user.id for user in active_users)

# Heap / PriorityQueue: O(log n) insert, O(1) max/min
# Use when: Priority queues, top-k problems, merging sorted streams
import heapq
top_5 = heapq.nlargest(5, items, key=lambda x: x.score)

# Tree (BST, AVL, Red-Black): O(log n) search, sorted iteration
# Use when: Sorted data with efficient search, range queries

# Bloom Filter: O(k) lookup, O(1) space, probabilistic
# Use when: Deduplication where false positives are acceptable
# (e.g., "have we seen this URL before?" — say yes might re-fetch, no = definitely new)

# LRU Cache: O(1) get/put, evicts least recently used
# Use when: Caching with limited size, memoization
from functools import lru_cache
@lru_cache(maxsize=1000)
def expensive_computation(x):
    return x * x
```

### Concurrency Patterns

```python
import asyncio
import threading
from concurrent.futures import ThreadPoolExecutor, ProcessPoolExecutor

# Threading vs Multiprocessing:
# - Threading: Shared memory, GIL-bound (Python), good for I/O
# - Multiprocessing: Separate memory, good for CPU-bound

# Pattern 1: ThreadPoolExecutor for I/O-bound tasks
def fetch_url(url):
    import requests
    return requests.get(url).text

with ThreadPoolExecutor(max_workers=10) as executor:
    futures = [executor.submit(fetch_url, url) for url in urls]
    results = [f.result() for f in futures]

# Pattern 2: Async/Await for high-concurrency I/O (Python)
async def fetch_all(urls):
    async with asyncio.TaskGroup() as tg:
        tasks = [tg.create_task(fetch_async(url)) for url in urls]
    return [task.result() for task in tasks]

# Pattern 3: ProcessPoolExecutor for CPU-bound tasks
def compute-heavy(x):
    return sum(i * i for i in range(x))

with ProcessPoolExecutor(max_workers=4) as executor:
    results = list(executor.map(compute-heavy, large_inputs))

# Pattern 4: Producer-Consumer with Queue
from queue import Queue
from threading import Thread

def producer(q, items):
    for item in items:
        q.put(item)  # Blocks when queue is full

def consumer(q):
    while True:
        item = q.get()
        if item is None:  # Sentinel to stop
            break
        process(item)
        q.task_done()

q = Queue(maxsize=100)
Thread(target=producer, args=(q, items)).start()
Thread(target=consumer, args=(q,)).start()

# Pattern 5: RWLock (reader-writer lock)
# Multiple readers OR one writer — use when read-heavy workload
import threading

class RWLock:
    def __init__(self):
        self._read_ready = threading.Condition(threading.Lock())
        self._readers = 0

    def acquire_read(self):
        with self._read_ready:
            self._readers += 1

    def release_read(self):
        with self._read_ready:
            self._readers -= 1
            if self._readers == 0:
                self._read_ready.notify_all()

    def acquire_write(self):
        self._read_ready.acquire()
        while self._readers > 0:
            self._read_ready.wait()

    def release_write(self):
        self._read_ready.release()
```

### ML Fundamentals

```python
# Machine Learning pipeline patterns:

# 1. Train/Val/Test split — never train on test data
from sklearn.model_selection import train_test_split

X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.2, random_state=42, stratify=y
)
X_train, X_val, y_train, y_val = train_test_split(
    X_train, y_train, test_size=0.25, random_state=42, stratify=y_train
)
# Result: 60% train, 20% val, 20% test

# 2. Cross-validation — for hyperparameter tuning
from sklearn.model_selection import cross_val_score

scores = cross_val_score(
    model, X_train, y_train, cv=5, scoring="accuracy"
)
# Reports accuracy across 5 folds — more robust than single split

# 3. Overfitting detection — train vs val loss
# If train loss << val loss: overfitting
# Fix: more data, regularization, early stopping, simpler model

# 4. Regularization — prevent overfitting
# L1 (Lasso): pushes coefficients to zero (feature selection)
# L2 (Ridge): shrinks coefficients (all features, smaller values)
# ElasticNet: combination of L1 and L2

# 5. Classification metrics
from sklearn.metrics import precision_score, recall_score, f1_score

precision = precision_score(y_true, y_pred)  # TP / (TP + FP)
recall = recall_score(y_true, y_pred)        # TP / (TP + FN)
f1 = f1_score(y_true, y_pred)                  # Harmonic mean of P and R

# 6. Feature engineering — most impactful ML step
# Domain knowledge + feature engineering >> model choice
# Examples:
# - Date features: day_of_week, is_weekend, hour
# - Text: TF-IDF, word embeddings, character n-grams
# - Categorical: one-hot, target encoding, embeddings

# 7. Pipelines — automate preprocessing
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import StandardScaler
from sklearn.linear_model import LogisticRegression

pipeline = Pipeline([
    ("scaler", StandardScaler()),       # Normalize features
    ("classifier", LogisticRegression()) # Then classify
])
pipeline.fit(X_train, y_train)
predictions = pipeline.predict(X_test)
```

### Static Analysis Patterns

```python
# Static analysis: analyze code without running it
# Used for: bug detection, security auditing, code quality

# 1. Type checking (Python: mypy)
# pip install mypy
# mypy src/

# 2. Security linting (Python: Bandit)
# pip install bandit
# bandit -r src/

# 3. Code complexity analysis
# radon: measure cyclomatic complexity
# pip install radon
# radon cc src/ -a  # Show complexity for all methods
# radon cc src/ -a -nb  # No branch points (just show total)

# 4. Pattern: Finding null dereferences (simplified)
# In Python, static analysis for None checks:
def find_potential_None_errors(func_body):
    """
    Find places where a variable is used without a None check,
    after being assigned None or returned from a function that returns Optional.
    """
    # This is a simplified example — real static analysis uses AST
    # Python's type system with mypy catches most of these
    pass

# 5. Regex-based pattern finding (simple static analysis)
# grep for dangerous patterns:
# r"eval\s*\("           — code injection
# r"pickle\.loads"       — arbitrary code execution
# r"os\.system"          — shell injection
# r"subprocess\.Popen"  — command injection
# r"exec\s*\("           — code injection

# 6. AST-based analysis (Python)
import ast

class SecurityChecker(ast.NodeVisitor):
    def visit_Call(self, node):
        if isinstance(node.func, ast.Name):
            if node.func.id in ["eval", "exec", "compile"]:
                print(f"Potential code injection at line {node.lineno}")
        self.generic_visit(node)

# Usage:
tree = ast.parse(open("user_code.py").read())
SecurityChecker().visit(tree)
```

### Cryptography Fundamentals

```python
# Cryptography patterns — use established libraries

# 1. Symmetric encryption — for data at rest
from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes
from cryptography.hazmat.backends import default_backend
import os

key = os.urandom(32)  # 256-bit key for AES-256
iv = os.urandom(16)   # 128-bit IV for CBC mode

cipher = Cipher(
    algorithms.AES(key),
    modes.CBC(iv),
    backend=default_backend()
)
encryptor = cipher.encryptor()
ciphertext = encryptor.update(b"secret message") + encryptor.finalize()

# 2. Authenticated encryption (recommended) — Encrypt + MAC in one
from cryptography.hazmat.primitives.ciphers.aead import ChaCha20Poly1305

key = os.urandom(32)  # 256-bit key
nonce = os.urandom(12)  # 96-bit nonce (unique per message)
aead = ChaCha20Poly1305(key)
# aead.seal returns ciphertext + tag (authentication)
ciphertext = aead.seal(nonce, plaintext, associated_data)

# 3. Hashing — for integrity, not encryption
import hashlib
# SHA-256: good for integrity, not for passwords
digest = hashlib.sha256(b"data").hexdigest()

# 4. Password hashing — use bcrypt or Argon2 (see security-basics skill)
# 5. Digital signatures — use Ed25519 or RSA-PSS (see security-basics skill)
# 6. HMAC — for message authentication with a shared key (see security-basics skill)

# What NOT to do:
# - AES-ECB (deterministic, leaks patterns)
# - MD5 for anything security-related (broken)
# - SHA1 for anything security-related (broken)
# - Rolling your own crypto
# - Using encryption without authentication (padding oracle attacks)
```

---

## Anti-Patterns

- **Premature optimization** — Micro-optimizations that hurt readability without measurable impact. Always profile first.

- **Using the wrong data structure** — ArrayList for frequent insertions at arbitrary positions (should be LinkedList). HashMap when you need sorted iteration (should be TreeMap).

- **Ignoring algorithmic complexity** — O(n^2) code that should be O(n log n). Always check the complexity of hot paths.

- **Not understanding the ML model's assumptions** — Linear regression assumes linear relationships. K-means assumes spherical clusters. Using the wrong model produces wrong results.

- **Treating ML as a black box** — Not understanding gradient descent, loss functions, or regularization leads to misdiagnosing model failures.

- **Rolling your own cryptography** — The details of crypto are subtle. Use established libraries and protocols.

- **Using MD5/SHA1 for security purposes** — These are broken checksums. Use SHA-256+ for integrity, bcrypt/Argon2 for passwords.

---

## Quick Reference

| Problem | Best Data Structure | Complexity |
|---------|-------------------|------------|
| Fast lookup by key | Dict/HashMap | O(1) |
| Sorted iteration | Tree/BST | O(log n) insert, O(log n) search |
| Priority queue | Heap | O(log n) insert, O(1) max |
| Deduplication | Set | O(n) |
| LRU cache | OrderedDict / LinkedHashMap | O(1) |
| String pattern matching | Trie / Suffix tree | O(m+n) |
| Graph shortest path | Dijkstra (weighted), BFS (unweighted) | O(V+E) or O(E log V) |

### Big O Quick Cards

```
O(1)       → HashMap get/put, array index
O(log n)   → Binary search, balanced tree operations
O(n)       → Linear scan, single loop
O(n log n) → Sorting (merge sort, quicksort avg case)
O(n^2)     → Nested loops over same collection
O(2^n)     → Recursive power set, recursive Fibonacci
O(n!)      → Permutations (avoid)
```
