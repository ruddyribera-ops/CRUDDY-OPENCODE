## Graph-First DAG Reasoning Loop (PRIMARY — v2.0)

**For ANY task rated Complexity 4+ (Moderate or Complex), you MUST generate a `task_graph` in scratchpad memory BEFORE routing. This is NOT optional — it replaces flat parallel dispatch with dependency-aware orchestration.**

### The Graph-First Flow

```
User request arrives
  ↑ Classify complexity (0-10)
  ↑ IF score < 4: route fast (standard routing table)
  ↑ IF score â‰¥ 4: ENTER GRAPH-FIRST MODE
      â”œâ”€â”€ Step 1: DECOMPOSE ↑ parse task into 3-5 sub-tasks
      â”œâ”€â”€ Step 2: MAP DEPENDENCIES ↑ which sub-tasks are independent? which wait?
      â”œâ”€â”€ Step 3: BUILD task_graph ↑ identify parallel batches
      â”œâ”€â”€ Step 4: EXECUTE ↑ batch 1 â€– batch 2 ↑ batch 3 (sequential between batches)
      â”œâ”€â”€ Step 5: FAN-IN VERIFY ↑ merge results, audit consistency
      â””â”€â”€ Step 6: AGGREGATE ↑ ONE consolidated report to user
```

### task_graph Format (Scratchpad)

```
task_graph:
  sub_tasks:
    - id: "auth-module"
      agent: code-builder
      depends_on: []
      description: "Login + register + sessions"
    - id: "product-module"
      agent: code-builder
      depends_on: []
      description: "CRUD + search + images"
    - id: "db-schema"
      agent: architecture-advisor
      depends_on: []
      description: "Database schema design"
    - id: "cart-checkout"
      agent: code-builder
      depends_on: [auth-module, product-module]
      description: "Cart + checkout flow"
  
  execution_plan:
    batch_1: [auth-module, product-module, db-schema]  # parallel
    batch_2: [cart-checkout]  # after batch 1
  
  fan_in:
    - verify: auth-module outputs match product-module user model
    - verify: cart-checkout queries match db-schema columns
    - audit: all POA items checked, no empty files
```

### DAG Patterns

| Pattern | When | Execution |
|---------|------|-----------|
| **Fan-out** | 3+ independent sub-tasks | All in parallel (batch 1) |
| **Pipeline** | A ↑ B ↑ C (linear dependency) | Sequential, one at a time |
| **Fan-in** | A + B ↑ C (multiple sources, one consumer) | A â€– B ↑ C after both done |
| **Branch** | If condition ↑ path X, else ↑ path Y | Decision gate, then one path |

### Fan-In Verification (MANDATORY before reporting)

After ALL batches complete and BEFORE reporting to user:

1. **Merge audit:** Do outputs from parallel agents reference consistent schemas/types?
2. **Gap check:** Does any sub-task have missing files, placeholder stubs, or empty folders?
3. **Conflict detection:** Did two agents produce incompatible assumptions?
4. **POA cross-reference:** Every POA item from every agent accounted for.

**If Fan-In fails:** flag the specific inconsistency, re-route affected sub-task for fix, re-verify.

### DAG Rules

1. **Max 3 batches** — don't over-decompose. 5 sub-tasks max total.
2. **Each batch is a parallel dispatch** — launch all sub-tasks within a batch simultaneously via `task` tool.
3. **Wait-for-batch** — don't proceed to next batch until current batch fully completes.
4. **Failed sub-task ↑ pause batch** — flag it, don't cancel siblings. Offer "retry / skip / fallback" to user.
5. **Fallback to linear** — if DAG too complex or dependencies unclear, route to single specialist (safe).
6. **Task graph is scratchpad** — write it as reasoning output, not a file. Brief, disposable.

---

