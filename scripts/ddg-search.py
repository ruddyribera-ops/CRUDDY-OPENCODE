#!/usr/bin/env python3
"""Minimal MCP server: DuckDuckGo web search. Free, no API key needed."""

import json
import sys
from ddgs import DDGS

def emit(msg: dict):
    body = json.dumps(msg, ensure_ascii=False)
    sys.stdout.buffer.write(f"Content-Length: {len(body.encode())}\r\n\r\n{body}".encode())
    sys.stdout.buffer.flush()

def read_msg() -> dict | None:
    raw = sys.stdin.buffer
    header = b""
    while b"\r\n\r\n" not in header:
        ch = raw.read(1)
        if not ch:
            return None
        header += ch
    clen_line = header.decode()
    for line in clen_line.split("\r\n"):
        if line.lower().startswith("content-length:"):
            clen = int(line.split(":")[1].strip())
            break
    else:
        return None
    body = raw.read(clen)
    return json.loads(body) if body else None

def handle_request(msg: dict) -> dict | None:
    method = msg.get("method")
    req_id = msg.get("id")
    params = msg.get("params", {})

    if method == "initialize":
        return {
            "jsonrpc": "2.0", "id": req_id,
            "result": {
                "protocolVersion": "2025-03-26",
                "capabilities": {"tools": {}},
                "serverInfo": {"name": "ddg-search", "version": "1.0.0"}
            }
        }

    if method == "notifications/initialized":
        return None  

    if method == "tools/list":
        return {
            "jsonrpc": "2.0", "id": req_id,
            "result": {
                "tools": [
                    {
                        "name": "web_search",
                        "description": "Search the web using DuckDuckGo. Free and open source. Returns up to 10 results with title, URL, and snippet.",
                        "inputSchema": {
                            "type": "object",
                            "properties": {
                                "query": {"type": "string", "description": "Search query"},
                                "max_results": {"type": "integer", "description": "Max results (1-20, default 10)", "default": 10}
                            },
                            "required": ["query"]
                        }
                    },
                    {
                        "name": "web_search_news",
                        "description": "Search recent news using DuckDuckGo.",
                        "inputSchema": {
                            "type": "object",
                            "properties": {
                                "query": {"type": "string", "description": "News search query"},
                                "max_results": {"type": "integer", "description": "Max results (1-20, default 10)", "default": 10}
                            },
                            "required": ["query"]
                        }
                    }
                ]
            }
        }

    if method == "tools/call":
        tool = params.get("name", "")
        args = params.get("arguments", {})
        query = args.get("query", "")
        max_r = min(args.get("max_results", 10), 20)

        try:
            results = []
            with DDGS() as ddgs:

                if tool == "web_search":
                    gen = ddgs.text(query, max_results=max_r)
                elif tool == "web_search_news":
                    gen = ddgs.news(query, max_results=max_r)
                else:
                    return {
                        "jsonrpc": "2.0", "id": req_id,
                        "error": {"code": -32601, "message": f"Unknown tool: {tool}"}
                    }
                for r in gen:
                    title = r.get("title", "")
                    link = r.get("href", r.get("link", r.get("url", "")))
                    snippet = r.get("body", r.get("snippet", ""))
                    results.append(f"[{title}]({link})\n{snippet}\n")
                    if len(results) >= max_r:
                        break

            text = "\n---\n".join(results) if results else "No results found."

            return {
                "jsonrpc": "2.0", "id": req_id,
                "result": {
                    "content": [{"type": "text", "text": text}]
                }
            }
        except Exception as e:
            return {
                "jsonrpc": "2.0", "id": req_id,
                "error": {"code": -32000, "message": f"Search failed: {str(e)}"}
            }

    return {
        "jsonrpc": "2.0", "id": req_id,
        "error": {"code": -32601, "message": f"Unknown method: {method}"}
    }

def main():
    while True:
        msg = read_msg()
        if msg is None:
            break
        try:
            resp = handle_request(msg)
            if resp:
                emit(resp)
        except Exception as e:
            emit({"jsonrpc": "2.0", "id": msg.get("id"), "error": {"code": -32000, "message": str(e)}})

if __name__ == "__main__":
    main()





