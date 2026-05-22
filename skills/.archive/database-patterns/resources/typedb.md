# TypeDB — Strongly-Typed Graph Database

Logical database with type system, inference, and conceptual modeling.

## Quick Reference

| Feature | Description |
|---------|-------------|
| **Type system** | Schema defines entity types and relations |
| **Inference** | Rule-based reasoning (like a theorem prover) |
| **Conceptual** | Model domain concepts, not tables |
| **Variety** | Handles complex, heterogeneous data |

## Schema Design

```typedef
# Define entity types
define
person sub entity,
    owns name,
    owns email,
    plays employment:employee;

company sub entity,
    owns name,
    plays employment:employer;

# Define relations
employment sub relation,
    relates employee,
    relates employer,
    owns since;

# Define attributes
name sub attribute, value string;
email sub attribute, value string;
since sub attribute, value datetime;

# Rules (inference)
rule novel-corner-case {
  when {
    (employee: $person, employer: $company) isa employment;
    $company has name "ACME Corp";
  } then {
    $person has attribute;
  }
}
```

## Python Client

```python
from typedb.driver import TypeDB

driver = TypeDB.core_driver("localhost:1729")

with driver.session("school", TypeDB.SessionType.DATA) as session:
    with session.transaction(TypeDB.TransactionType.WRITE) as tx:
        tx.query.insert('insert $p isa person, has name "Alice";')
        tx.commit()

# Read query
with driver.session("school", TypeDB.SessionType.DATA) as session:
    with session.transaction(TypeDB.TransactionType.READ) as tx:
        result = tx.query.get('match $p isa person, has name $n; get $n;')
        for r in result:
            print(r.get("n").get_value())
```

## Query (TypeQL)

```typescript
// Match complex pattern
match
$p isa person, has name $name;
($p, $c) isa employment;
$c isa company, has name "ACME Corp";
$emp isa employment, relates employee $p, has since $date;

get $name, $date;

// With inference (rules applied automatically)
match
$p isa developer;
$p has skill "Rust";
```

## TypeDB vs Neo4j

| Feature | TypeDB | Neo4j |
|---------|--------|-------|
| Type system | Strong, schema-based | Labels + properties |
| Inference | Native (rules engine) | Limited (APOC) |
| Schema | Conceptual model | Labels |
| Best for | Complex domains, KG | Operational graphs |
| Learning curve | Steeper | Moderate |

## Use Cases

- **Knowledge graphs:** Rich domain modeling with inference
- **Biomedical research:** Complex biological relationships
- **Enterprise data:** Schema-first, type-safe integration
- **Complex domains:** Finance (instruments, portfolios, risk)

## Resources

- [typedb-awesome](https://github.com/vaticle/typedb-awesome)
- [vaticle.com/docs](https://docs.vaticle.com/)