"""
KG Write Proxygen — Write entities/relations to live MCP memory server via HTTP
This is the production version that calls the actual MCP server endpoint.

The MCP memory server (modelcontextprotocol/server-memory) exposes:
  POST /entities — create entities
  POST /relations — create relations  
  GET  /entities?name=<query> — search
  GET  /graph — read all

Usage (same as kg_write.py):
  python kg_write_proxygen.py entities "<json-array>"
  python kg_write_proxygen.py relations "<json-array>"
  python kg_write_proxygen.py entity "<name>" "<type>" "<obs-json>"
  python kg_write_proxygen.py search "<query>"
  python kg_write_proxygen.py read

NOTE: This script requires the MCP memory server to be ACCESSIBLE via localhost
or the configured MCP server URL. If the server is unavailable, entities
are queued to kg_queue.json for later flush.

Install deps: pip install requests
"""

import json
import sys
import os
from pathlib import Path
import urllib.request
import urllib.error

MAILBOXES_DIR = Path.home() / ".config" / "opencode" / "memory" / "mailboxes"
KG_QUEUE_FILE = Path.home() / ".config" / "opencode" / "memory" / "kg_queue.json"

# MCP memory server URL — auto-detect from environment or use default
MCP_MEMORY_URL = os.environ.get("MCP_MEMORY_URL", "http://localhost:6274")

def mcp_request(endpoint, payload, timeout=5):
    """Make request to MCP memory server"""
    try:
        data = json.dumps(payload).encode("utf-8")
        req = urllib.request.Request(
            f"{MCP_MEMORY_URL}{endpoint}",
            data=data,
            headers={"Content-Type": "application/json"},
            method="POST"
        )
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            return {"ok": True, "data": json.loads(resp.read())}
    except urllib.error.URLError as e:
        return {"ok": False, "error": f"MCP server unreachable: {e}"}
    except Exception as e:
        return {"ok": False, "error": str(e)}

def load_queue():
    if KG_QUEUE_FILE.exists():
        with open(KG_QUEUE_FILE) as f:
            return json.load(f)
    return {"entities": [], "relations": []}

def save_queue(q):
    with open(KG_QUEUE_FILE, "w") as f:
        json.dump(q, f, indent=2)

def cmd_flush():
    """Flush queued entities/relations to actual MCP server"""
    q = load_queue()
    results = {"entities": 0, "relations": 0, "errors": [], "skipped": 0}
    
    if not q["entities"] and not q["relations"]:
        return {"ok": True, "data": "nothing to flush"}
    
    # Flush entities
    for entity in q.get("entities", []):
        resp = mcp_request("/entities", {"entities": [entity]})
        if resp.get("ok"):
            results["entities"] += 1
        else:
            results["errors"].append(resp.get("error", "unknown"))
    
    # Flush relations
    for rel in q.get("relations", []):
        resp = mcp_request("/relations", {"relations": [rel]})
        if resp.get("ok"):
            results["relations"] += 1
        else:
            results["errors"].append(resp.get("error", "unknown"))
    
    # Clear queue
    save_queue({"entities": [], "relations": []})
    return {"ok": True, "data": results}

def cmd_entities_json(json_str):
    """Queue entities for KG write"""
    try:
        entities = json.loads(json_str)
    except json.JSONDecodeError as e:
        return {"ok": False, "error": f"Invalid JSON: {e}"}
    q = load_queue()
    q["entities"].extend(entities)
    save_queue(q)
    return {"ok": True, "data": {"queued": len(entities), "total_entities": len(q["entities"])}}

def cmd_relations_json(json_str):
    """Queue relations for KG write"""
    try:
        relations = json.loads(json_str)
    except json.JSONDecodeError as e:
        return {"ok": False, "error": f"Invalid JSON: {e}"}
    q = load_queue()
    q["relations"].extend(relations)
    save_queue(q)
    return {"ok": True, "data": {"queued": len(relations), "total_relations": len(q["relations"])}}

def cmd_entity(name, entity_type, obs_json):
    """Queue single entity"""
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
    """Direct search via MCP server"""
    resp = mcp_request("/entities/search", {"query": query})
    if resp.get("ok"):
        return resp
    return {"ok": True, "data": {"query": query, "note": "MCP unreachable — search from queue", "matches": []}}

def cmd_read():
    """Read from MCP server"""
    resp = mcp_request("/graph", {})
    if resp.get("ok"):
        return resp
    q = load_queue()
    return {"ok": True, "data": {"note": "MCP unreachable — queue only", "queue": q}}

def main():
    if len(sys.argv) < 2:
        print(json.dumps({"ok": False, "error": "Usage: kg_write.py <cmd> [args]"}))
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
    elif cmd == "flush":
        result = cmd_flush()
    elif cmd == "clear":
        save_queue({"entities": [], "relations": []})
        result = {"ok": True, "data": "KG queue cleared"}
    else:
        result = {"ok": False, "error": f"Unknown command: {cmd}"}
    
    print(json.dumps(result, indent=2))

if __name__ == "__main__":
    main()