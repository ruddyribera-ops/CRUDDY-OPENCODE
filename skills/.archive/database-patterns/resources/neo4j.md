# Neo4j — Graph Database

NoSQL graph database for connected data: social networks, recommendations, knowledge graphs.

## Quick Reference

| Concept | Description |
|---------|-------------|
| **Node** | Entity (like a row in SQL) |
| **Relationship** | Edge between nodes |
| **Label** | Node type (e.g., Person, Product) |
| **Property** | Node/relationship attributes |
| **Cypher** | Query language for Neo4j |

## Connection

```python
from neo4j import GraphDatabase

driver = GraphDatabase.driver(
    "neo4j://localhost:7687",
    auth=("neo4j", "password")
)

def query(tx, cypher, **params):
    result = tx.run(cypher, **params)
    return [dict(record) for record in result]

with driver.session() as session:
    data = session.execute_read(query, "MATCH (p:Person) RETURN p.name", limit=10)
```

## Cypher Basics

```cypher
-- Create nodes
CREATE (alice:Person {name: 'Alice', age: 30})
CREATE (bob:Person {name: 'Bob', age: 25})

-- Create relationship
CREATE (alice)-[:KNOWS {since: 2020}]->(bob)

-- Match with pattern
MATCH (a:Person)-[:KNOWS]->(b:Person)
WHERE a.name = 'Alice'
RETURN b.name, b.age

-- Friends of friends
MATCH (me:Person {name: 'Alice'})-[:KNOWS*1..2]->(friend)
RETURN DISTINCT friend.name

-- Shortest path
MATCH path = shortestPath((a:Person {name:'Alice'})-[*]-(b:Person {name:'Bob'}))
RETURN path
```

## Python Patterns

### Knowledge Graph

```python
def add_knowledge_triple(subject, predicate, obj):
    with driver.session() as session:
        session.run("""
            MERGE (s:Entity {name: $subject})
            MERGE (o:Entity {name: $obj})
            MERGE (s)-[:REL {type: $predicate}]->(o)
        """, subject=subject, predicate=predicate, obj=obj)

# Add: "Python is a programming language"
add_knowledge_triple("Python", "is_a", "programming_language")
add_knowledge_triple("Python", "created_by", "Guido van Rossum")
```

### Recommendation Engine

```cypher
// "Users who bought this also bought"
MATCH (buyer:Person {user_id: 123})-[:PURCHASED]->(product:Product)<-[:PURCHASED]-(similar_buyer:Person)
WHERE buyer <> similar_buyer
WITH similar_buyer, count(*) as common_purchases
ORDER BY common_purchases DESC
LIMIT 5
MATCH (similar_buyer)-[:PURCHASED]->(recommended:Product)
WHERE recommended <> product
RETURN recommended.name, count(*) as score
ORDER BY score DESC
LIMIT 5
```

## Import Data

```python
# Import CSV
with driver.session() as session:
    session.run("""
        LOAD CSV WITH HEADERS FROM 'file:///users.csv'
        AS row
        CREATE (u:User {
            id: toInteger(row.id),
            name: row.name,
            email: row.email
        })
    """)
```

## Indexing

```cypher
-- Create index
CREATE INDEX FOR (p:Person) ON (p.name)

-- Composite index
CREATE INDEX FOR (p:Person) ON (p.name, p.email)

-- Full-text search index
CREATE FULLTEXT INDEX FOR (p:Person) ON EACH [p.name, p.bio]
```

## GraphQL (via Neo4j GraphQL Library)

```python
from neo4j_graphql import Neo4jGraphQL

schema = Neo4jGraphQL.type_defs"""
type User {
  name: String!
  friends: [User] @relationship(type: "KNOWS", direction: OUT)
  purchases: [Product] @relationship(type: "PURCHASED", direction: OUT)
}

type Product {
  name: String!
  category: String
  boughtBy: [User] @relationship(type: "PURCHASED", direction: IN)
}
"""

# Auto-generate resolvers
graphql_schema = Neo4jGraphQL(schema, driver)
```

## Comparison

| Feature | Neo4j | TypeDB | PostgreSQL (JSON) |
|---------|-------|--------|-------------------|
| Graph traversal | Native | Native | Recursive CTEs |
| Type system | Labels + properties | Strong types | Schema-free |
| Inference | Limited | Yes (reasoning) | ❌ |
| Best for | Operational | Knowledge graphs | Simple hierarchies |

## Use Cases

- **Social networks:** Friends, followers, recommendations
- **Fraud detection:** Pattern matching across transactions
- **Knowledge graphs:** Entities, relationships, hierarchies
- **Supply chain:** Routing, dependencies, impact analysis

## Resources

- [awesome-neo4j](https://github.com/neueda/awesome-neo4j)
- [neo4j.com/docs](https://neo4j.com/docs/)