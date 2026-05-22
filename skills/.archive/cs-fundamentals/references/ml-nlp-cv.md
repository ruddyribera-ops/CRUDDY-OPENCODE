# ML, NLP & Computer Vision — Detailed Patterns

## Machine Learning

### Core Frameworks
| Framework | Use Case |
|-----------|----------|
| TensorFlow | Production ML, TF Lite, TF.js |
| PyTorch | Research, rapid prototyping, dynamic graphs |
| JAX | High-performance research, XLA compilation |
| H2O | Enterprise ML, AutoML |

### Training Loop (TensorFlow)
```python
model = tf.keras.Sequential([...])
model.compile(optimizer='adam', loss='sparse_categorical_crossentropy', metrics=['accuracy'])
model.fit(train_data, epochs=10, validation_split=0.2)
```

### JAX Transformation
```python
import jax.numpy as jnp
from jax import grad, jit

@jit
def loss(params, x, y): return cross_entropy(model(params, x), y)
grad_fn = grad(loss)
```

### Resources
- awesome-tensorflow, awesome-pytorch, awesome-jax
- awesome-seml (Software Engineering for ML)
- awesome-ai-in-finance, awesome-xai (Explainable AI)
- CoreML Models for iOS/macOS

## Natural Language Processing

### Key Libraries
```python
from transformers import pipeline
classifier = pipeline("sentiment-analysis")
result = classifier("This is great!")

import speech_recognition as sr
r = sr.Recognizer()
text = r.recognize_google(audio_data, language='es-ES')
```

### Core Areas
- Speech Processing (ASR, TTS, audio features)
- Spanish NLP: awesome-spanish-nlp
- Question Answering: awesome-qa
- Natural Language Generation: awesome-nlg

## Computer Vision

### Key Libraries
```python
import cv2
img = cv2.imread('photo.jpg')
gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
edges = cv2.Canny(gray, 100, 200)
```

### Core Resources
- awesome-computer-vision — comprehensive CV resources
- awesome-deep-vision — deep learning for CV
- Image classification, object detection, segmentation, GANs

## Algorithms & Data Structures

### Sorting
| Algorithm | Time | Space | Stable |
|-----------|------|-------|--------|
| Quick Sort | O(n log n) avg, O(n²) worst | O(log n) | No |
| Merge Sort | O(n log n) all cases | O(n) | Yes |
| Heap Sort | O(n log n) all cases | O(1) | No |
| Timsort | O(n log n) worst | O(n) | Yes |

### Search
| Algorithm | Structure | Time |
|-----------|-----------|------|
| Binary Search | Sorted array | O(log n) |
| BFS | Graph/Tree | O(V + E) |
| DFS | Graph/Tree | O(V + E) |
| Dijkstra | Weighted graph | O(E log V) |

### Data Structures
- Arrays/Lists: O(1) access, O(n) insert/delete
- Hash Tables: O(1) avg access, O(n) worst
- Binary Trees: O(log n) balanced, O(n) unbalanced
- Heaps: O(log n) insert/extract min
- Graphs: adjacency list (sparse) vs matrix (dense)

## Cryptography

### Key Concepts
| Concept | Description |
|---------|-------------|
| Symmetric (AES, ChaCha20) | Same key for encrypt/decrypt |
| Asymmetric (RSA, ECC) | Public/private key pair |
| Hashing (SHA-256, BLAKE2) | One-way, collision-resistant |
| Digital Signatures (ECDSA, EdDSA) | Authentication + non-repudiation |

### Rules
- Never roll your own crypto
- Use proven libraries (libsodium, Tink, BoringSSL)
- Use AEAD modes (AES-GCM, ChaCha20-Poly1305)
- Key derivation: Argon2id for passwords, HKDF for key agreement
- Salt all hashes, use unique IV/nonce per encryption

## Quantum Computing

### Key Concepts
- Qubits: superposition, entanglement, measurement
- Gates: Hadamard (H), Pauli (X, Y, Z), CNOT, Toffoli
- Algorithms: Shor's (factoring), Grover's (search), QAOA (optimization)
- Frameworks: Qiskit (IBM), Cirq (Google), PennyLane (Xanadu)

## Static Analysis

### Compiler Design Stages
1. Lexical analysis → 2. Parsing → 3. Semantic analysis → 4. IR gen → 5. Optimization → 6. Code gen

### Tools
| Tool | Type | Description |
|------|------|-------------|
| LLVM | Compiler infrastructure | IR, optimization, backends |
| ANTLR | Parser generator | LL(*) parsing, multi-language |
| ESLint | Linter | JS/TS static analysis |
| Pylint/Pyright | Linter/Type checker | Python analysis |
| Semgrep | SAST | Pattern-based code analysis |

## Theoretical CS

### Core Topics
- Automata: DFA, NFA, PDA, Turing Machines
- Complexity: P, NP, NP-Complete, NP-Hard
- Computability: Halting Problem, Rice's Theorem
- Formal languages: Regular, Context-Free, Context-Sensitive
- Lambda calculus: foundation of functional programming
- Type theory: simply typed, Hindley-Milner, dependent types

### Resources
- awesome-algorithms, awesome-algorithm-visualization
- SICP (Structure and Interpretation of Computer Programs)
- Introduction to Algorithms (CLRS)
- The Art of Computer Programming (Knuth)
