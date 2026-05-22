---
name: cs-fundamentals
description: Computer Science fundamentals — Machine Learning, NLP, Computer Vision, Algorithms, Cryptography, Quantum Computing, Static Analysis, and Theoretical CS
tags: [computer-science, algorithms, theory]
---

# Computer Science Fundamentals

Comprehensive reference for CS domains relevant to modern software development.

## When to Use
- Building ML pipelines (TensorFlow, PyTorch, JAX)
- Implementing NLP systems (transformers, speech processing)
- Designing CV solutions (OpenCV, deep vision)
- Working with algorithms, data structures, or cryptography
- Quantum computing, static code analysis, or academic CS theory

## Do Not Use
- Python-specific async patterns (use python-patterns)
- Database schema design (use database-patterns)
- Performance optimization (use performance-optimization)

## Machine Learning
| Framework | Use Case | Resource |
|-----------|----------|----------|
| TensorFlow | Production ML, mobile/browser | awesome-tensorflow |
| PyTorch | Research, rapid prototyping | pytorch.org |
| JAX | High-performance, XLA | awesome-jax |
| H2O | Enterprise ML, AutoML | awesome-h2o |

→ See `references/ml-nlp-cv.md` for training loops, JAX transformation, and ML resources.

## Natural Language Processing
**Key lib:** HuggingFace Transformers (`pipeline("sentiment-analysis")`), SpeechRecognition, awesome-spanish-nlp, awesome-qa, awesome-nlg.

→ See `references/ml-nlp-cv.md` for code examples and core areas.

## Computer Vision
**Key lib:** OpenCV (`cv2.Canny` for edge detection), awesome-computer-vision, awesome-deep-vision.

→ See `references/ml-nlp-cv.md` for code examples.

## Algorithms & Data Structures

| Category | Key Algorithms | Complexity |
|----------|---------------|------------|
| Sorting | Quick, Merge, Heap, Timsort | O(n log n) avg |
| Search | Binary, BFS, DFS, Dijkstra | O(log n) to O(V+E) |
| Structures | Arrays, Hash Tables, Trees, Heaps, Graphs | Varies |

→ See `references/ml-nlp-cv.md` for full algorithm tables and data structure characteristics.

## Cryptography
| Type | Algorithms | Rule |
|------|------------|------|
| Symmetric | AES, ChaCha20 | Never roll your own crypto |
| Asymmetric | RSA, ECC | Use proven libraries (libsodium, Tink) |
| Hashing | SHA-256, BLAKE2 | Salt all hashes |
| Signatures | ECDSA, EdDSA | Use AEAD modes (AES-GCM, ChaCha20-Poly1305) |
| Key Derivation | Argon2id (passwords), HKDF (key agreement) | Unique IV/nonce per encryption |

→ See `references/ml-nlp-cv.md` for detailed cryptography concepts.

## Quantum Computing
- Qubits: superposition, entanglement, measurement
- Gates: H, Pauli (X/Y/Z), CNOT, Toffoli
- Algorithms: Shor's (factoring), Grover's (search), QAOA (optimization)
- Frameworks: Qiskit (IBM), Cirq (Google), PennyLane (Xanadu)

## Static Analysis
- Compiler stages: Lexical → Parse → Semantic → IR → Optimize → Code gen
- Tools: LLVM, ANTLR, ESLint, Pyright/Pylint, Semgrep

## Theoretical CS
- Automata: DFA, NFA, PDA, Turing Machines
- Complexity: P, NP, NP-Complete, NP-Hard
- Computability: Halting Problem, Rice's Theorem
- Formal languages, lambda calculus, type theory

## Verification
- [ ] ML training loop converges (loss decreases over epochs)
- [ ] NLP pipeline produces correct classifications
- [ ] CV pipeline detects expected features
- [ ] Algorithm has correct time/space complexity analysis
- [ ] Cryptographic operations use proven libraries (not custom)
- [ ] All reference links resolve to existing files
