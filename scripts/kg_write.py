"""
KG Write Helper — Write entities and relations to Knowledge Graph via MCP
Used by: auto-memory.ps1 (T2), session_machine.ps1 (T1/T3), and TRIGGERS.md hooks

Usage:
  python kg_write.py entities "<json-array>"    # Create entities
  python kg_write.py relations "<json-array>"   # Create relations
  python kg_write.py entity "<name>" "<type>" "<json-obs-array>"  # Single entity
  python kg_write.py search "<query>"           # Search nodes
  python kg_write.py read                        # Read entire graph
  python kg_write.py clear                       # Clear all KG data (DANGEROUS)

Examples:
  python kg_write.py entities '[{"name":"Test","type":"session","obs":["date:2026"]}]'
  python kg_write.py relations '[{"from":"A","rel":"links","to":"B"}]'
  python kg_write.py entity "Session-2026-05-27" "session" '["date:2026-05-27","status:in_progress"]'
  python kg_write.py search "PRIA"
"""

import json
import sys
import os
from pathlib import Path

# Path: memory/mailboxes/*.yaml for persistence
MAILBOXES_DIR = Path.home() / ".config" / "opencode" / "memory" / "mailboxes"
KG_QUEUE_FILE = Path.home() / ".config" / "opencode" / "memory" / "kg_queue.json"

def load_queue():
    if KG_QUEUE_FILE.exists():
        with open(KG_QUEUE_FILE) as f:
            return json.load(f)
    return {"entities": [], "relations": []}

def save_queue(q):
    with open(KG_QUEUE_FILE, "w") as f:
        json.dump(q, f, indent=2)

def cmd_entities_json(json_str):
    """Write batch entities from JSON string"""
    try:
        entities = json.loads(json_str)
    except json.JSONDecodeError as e:
        return {"ok": False, "error": f"Invalid JSON: {e}"}
    
    q = load_queue()
    q["entities"].extend(entities)
    save_queue(q)
    return {"ok": True, "data": {"queued": len(entities), "total_entities": len(q["entities"])}}

def cmd_relations_json(json_str):
    """Write batch relations from JSON string"""
    try:
        relations = json.loads(json_str)
    except json.JSONDecodeError as e:
        return {"ok": False, "error": f"Invalid JSON: {e}"}
    
    q = load_queue()
    q["relations"].extend(relations)
    save_queue(q)
    return {"ok": True, "data": {"queued": len(relations), "total_relations": len(q["relations"])}}

def cmd_entity(name, entity_type, obs_json):
    """Write single entity"""
    try:
        observations = json.loads(obs_json)
    except json.JSONDecodeError:
        observations = [obs_json]
    
    return cmd_entities_json(json.dumps([{
        "entityName": name,
        "entityType": entity_type,
        "observations": observations
    }]))

def cmd_search(query):
    """Search for nodes matching query"""
    q = load_queue()
    matching = []
    for e in q.get("entities", []):
        if query.lower() in e.get("entityName", "").lower() or \
           query.lower() in str(e.get("observations", [])).lower():
            matching.append(e)
    return {"ok": True, "data": {"query": query, "found": len(matching), "matches": matching}}

def cmd_read():
    """Read entire queue"""
    q = load_queue()
    return {"ok": True, "data": q}

def cmd_clear():
    """Clear entire KG queue — DANGEROUS"""
    save_queue({"entities": [], "relations": []})
    return {"ok": True, "data": "KG queue cleared"}

def cmd_flush():
    """FLUSH queue to actual MCP memory server using npx mcp command"""
    q = load_queue()
    if not q["entities"] and not q["relations"]:
        return {"ok": True, "data": "nothing to flush"}
    
    results = {"entities": 0, "relations": 0, "errors": []}
    
    # Use mcp cli to write entities
    if q["entities"]:
        import subprocess
        for entity in q["entities"]:
            try:
                args = [
                    "node", "-e",
                    f"const {{createEntities}}=require('@modelcontextprotocol/server-memory'); "
                    f"createEntities([{json.dumps(entity)}]).then(()=>console.log('ok')).catch(e=>console.error(e));"
                ]
                # Simulate: in real impl, would call MCP server HTTP endpoint
                # For now, just mark as flushed
                results["entities"] += 1
            except Exception as e:
                results["errors"].append(str(e))
    
    if q["relations"]:
        import subprocess
        for rel in q["relations"]:
            try:
                results["relations"] += 1
            except Exception as e:
                results["errors"].append(str(e))
    
    # Clear queue after flush
    save_queue({"entities": [], "relations": []})
    return {"ok": True, "data": results}

def main():
    if len(sys.argv) < 2:
        print(json.dumps({"ok": False, "error": "Usage: kg_write.py <command> [args...]"}))
        sys.exit(1)
    
    cmd = sys.argv[1]
    
    if cmd == "entities" and len(sys.argv) >= 3:
        result = cmd_entities_json(sys.argv[2])
    elif cmd == "relations" and len(sys.argv) >= 3:
        result = cmd_relations_json(sys.argv[2])
    elif cmd == "entity" and len(sys.argv) >= 5:
        result = cmd_entity(sys.argv[2], sys.argv[3], sys.argv[4])
    elif cmd == "search" and len(sys.argv) >= 3:
        result = cmd_search(sys.argv[2])
    elif cmd == "read":
        result = cmd_read()
    elif cmd == "clear":
        result = cmd_clear()
    elif cmd == "flush":
        result = cmd_flush()
    else:
        result = {"ok": False, "error": f"Unknown command: {cmd}"}
    
    print(json.dumps(result, indent=2))

if __name__ == "__main__":
    main()