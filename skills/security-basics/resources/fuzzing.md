# Fuzzing

Automated software testing technique that bombards a target with invalid/unexpected inputs to find crashes, memory leaks, or assertion failures.

## Fuzzer Types

| Type | How It Works | Best For |
|------|-------------|----------|
| **Dumb/mutation fuzzing** | Randomly mutate inputs byte-by-byte | Quick coverage of known file formats |
| **Generational fuzzing** | Generate inputs based on grammar/structure | Structured formats (JSON, XML, protocols) |
| **Coverage-guided (greybox)** | Use code coverage to guide mutations | Finding bugs in complex software |
| **Whitebox/Symbolic** | Solve constraints to reach new paths | Deep exploration of specific paths |
| **Grammatical** | Use context-free grammar to generate inputs | Language parsers, compilers |

## AFL++ (American Fuzzy Lop Plus)

Industry-standard coverage-guided fuzzer:

```bash
# 1. Build instrumented target
CC=afl-gcc-fast CXX=afl-g++-fast AFL_USE_ASAN=1 make
# or for LLVM mode (faster, better coverage):
CC=afl-clang-fast CXX=afl-clang-fast++ make

# 2. Create initial corpus (even 1 seed is fine)
mkdir input_corpus
echo "test input" > input_corpus/seed.txt

# 3. Run fuzzer
afl-fuzz -i input_corpus -o output_corpus -- ./target -f @@
# @@ is replaced by AFL with input file path

# 4. Monitor findings
ls output_corpus/default/crashes/
ls output_corpus/default/hangs/
```

**AFL++ options:**
```
afl-fuzz -i in -o out -x dictionary.dict -- ./target @@
# -x: use dictionary (helps for text formats)
# -m memory_limit (MB)
# -t timeout (ms per input)
# -M/-S: master/slave for parallel fuzzing
```

## LibFuzzer (Google's in-process fuzzer)

Integrated with Clang; great for C/C++ libraries:

```cpp
// my_fuzzer.cpp
#include <fuzzer/FuzzedDataProvider.h>

extern "C" int ProcessJSON(const char* data, size_t size);

extern "C" int LLVMFuzzerTestOneInput(const uint8_t* data, size_t size) {
  // Transform raw bytes into structured input
  FuzzedDataProvider provider(data, size);
  std::string json = provider.ConsumeRandomLengthString(1024);
  
  // Call the target function
  ProcessJSON(json.c_str(), json.size());
  return 0; // 0 = keep fuzzing, non-zero = stop
}
```

```bash
# Compile with sanitizers
clang -fsanitize=fuzzer,address,undefined -g my_fuzzer.cpp -o fuzzer target.o

# Run
./fuzzer
# or with corpus:
./fuzzer /path/to/corpus_dir
# Timeout:
./fuzzer -runs=1000000
```

## Fuzzing Web Targets

### HTTP Fuzzing with FFUF

```bash
# Directory discovery
ffuf -u https://target.com/FUZZ -w /usr/share/wordlists/seclists/Discovery/Web-Content/common.txt -mc 200,204,301,302,307,401,403

# Parameter fuzzing (GET)
ffuf -u "https://target.com/api?param=FUZZ" -w wordlist.txt -mc 200 -fr "error"

# POST fuzzing
ffuf -u "https://target.com/search" -X POST -d "q=FUZZ" -w wordlist.txt -fr "no results"

# Subdomain enumeration
ffuf -u https://FUZZ.target.com -w subdomains.txt -mc 200,403 -H "Host: FUZZ.target.com"

# vhost discovery
ffuf -u https://target.com/ -H "Host: FUZZ" -w vhosts.txt -mc 200
```

### API Fuzzing

```bash
# OpenAPI fuzzer
ffuf -u https://target.com/api/fuzz -w /usr/share/wordlists/params.txt -ms '{"code":"FUZZ"}'

# Using wfuzz format
wfuzz -z file,wordlist.txt -d "username=admin&password=FUZZ" http://target.com/login
```

## Fuzzing Frameworks (Advanced)

### Echidna (Ethereum smart contracts)

```bash
# Install
npm install -g ethabi-cli
pip install echidna

# Write a property test
function test_sender_balance() public {
  assert(balanceOf(msg.sender) <= 1000000);
}

// echidna.yaml
project: MyToken
coverage: true
testMode: fuzzing
timeout: 3600
```

### BOOFuzz (protocol fuzzing)

```python
from boofuzz import *

session = Session(target=Target(connection=SocketConnection("10.0.0.1", 9000, proto="tcp")))

s_initialize(name="login")
with s_block("header"):
    s_static(b"LOGN")  # 4-byte header
    s_size("body", length=4, endian=BIG_ENDIAN)
with s_block("body"):
    s_string("admin")  # username
    s_delim(b" ")
    s_string("password")  # password

session.connect(s_get("login"))
session.fuzz()
```

## Corpus Minimization

```bash
# After finding crashes, minimize input corpus
afl-cmin -i large_corpus -o minimized_corpus -- ./target @@

# For LibFuzzer:
ls corpus/ | head -1000 | while read f; do echo "$f"; done > corpus_1k.txt
# then re-run with new corpus
```

## Coverage Analysis

```bash
# Generate coverage report with lcov/genhtml
make clean
CC=afl-gcc-fast CXX=afl-g++-fast AFL_DUMP_COV=1 make
afl-fuzz -i in -o out ./target @@
gcov -o . *.o  # generates coverage data

# Visualize with GCOV
lcov --capture --directory . --output-file coverage.info
genhtml coverage.info --output-directory coverage_html
```

## Sanitizers (Crash Detection)

| Sanitizer | Detects | Compiler Flag |
|-----------|---------|---------------|
| AddressSanitizer (ASAN) | Heap/stack/global buffer overflow, use-after-free, double-free | `-fsanitize=address` |
| UndefinedBehaviorSanitizer (UBSAN) | Undefined behavior (null deref, signed overflow) | `-fsanitize=undefined` |
| MemorySanitizer (MSAN) | Use of uninitialized memory | `-fsanitize=memory` |
| ThreadSanitizer (TSAN) | Race conditions, deadlocks | `-fsanitize=thread` |

**AFL with ASAN:**
```bash
AFL_USE_ASAN=1 CC=afl-gcc-fast make
# or for LLVM mode:
AFL_USE_ASAN=1 CC=afl-clang-fast make
```

## Finding Crashes in CI/CD

```yaml
# GitHub Actions — automated fuzzing
- name: Run AFL++ Fuzzer
  run: |
    mkdir -p corpus
    echo "seed" > corpus/seed
   afl-fuzz -i corpus -o findings -m 2G -- ./target @@
  timeout-minutes: 60

- name: Triage Crashes
  run: |
    for crash in findings/default/crashes/*; do
      echo "Crash: $crash" 
      ./target "$crash" 2>&1 | head -20
    done
```

## Seed Selection Strategies

1. **Hand-crafted minimal inputs** — cover basic parsing paths
2. **Existing test suite** — convert unit tests to corpus
3. **Differential fuzzing** — compare two implementations for divergence
4. **Grammar-based generation** — cover deep syntactic complexity
5. **Minimized corpus** — run `afl-cmin` regularly to keep corpus tight

## Fuzzing Checklist

- [ ] Instrument target with AFL++ or LibFuzzer
- [ ] Enable ASAN/UBSAN for crash detection
- [ ] Build initial corpus (seed minimal valid inputs)
- [ ] Run with timeout and memory limits
- [ ] Monitor crashes — reproduce deterministically
- [ ] Triage: is it a real bug or just a benign abort?
- [ ] File bug report with crash input + reproduction steps
- [ ] Minimize crash input for easier debugging