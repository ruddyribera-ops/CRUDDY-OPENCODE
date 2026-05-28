"""
Agent Mail System — Persistent Inter-Agent Communication
Inspired by GasTown nudge/mail pattern.

Usage:
  python mail.py send <to> [--subject "<subj>"] [--body "<msg>" or --stdin] [--urgent] [--ref <msg-id>]
  python mail.py inbox [<agent>]
  python mail.py list
  python mail.py count
  python mail.py read <msg-id>
  python mail.py clear [<agent>]

All commands return JSON: {"ok": true, "data": ...} or {"ok": false, "error": "..."}
"""

import argparse
import json
import os
import sys
from datetime import datetime
from pathlib import Path

MAIL_DIR = Path.home() / ".config" / "opencode" / "memory" / "mailboxes"
MAIL_DIR.mkdir(parents=True, exist_ok=True)

VALID_AGENTS = [
    "main-coordinator", "code-builder", "bug-fixer", "code-analyzer",
    "code-explainer", "architecture-advisor", "project-generator",
    "standup-summary", "evolution-agent", "skill-manager"
]


def _agent_file(agent):
    agent = agent.replace("@", "").strip().lower()
    return MAIL_DIR / f"{agent}.yaml"


def _load_mailbox(agent):
    f = _agent_file(agent)
    if not f.exists():
        return []
    import yaml
    with open(f, "r") as fh:
        data = yaml.safe_load(fh)
        return data if data else []


def _save_mailbox(agent, messages):
    import yaml
    f = _agent_file(agent)
    with open(f, "w") as fh:
        yaml.dump(messages, fh, default_flow_style=False)


def _list_mailbox_files():
    """Return all mailbox files that exist."""
    files = []
    for f in MAIL_DIR.iterdir():
        if f.suffix in (".yaml", ".yml") and f.stem in VALID_AGENTS:
            files.append(f)
    return files


def _deduplicate_msg(to, subject, from_agent):
    """Check for exact (to, subject, from) match with read=False. Returns (index, msg) or (None, None)."""
    msgs = _load_mailbox(to)
    for i, m in enumerate(msgs):
        if m.get("to") == to and m.get("from") == from_agent and m.get("subject") == subject and not m.get("read"):
            return i, m
    return None, None


def _enforce_max_unread(to):
    """If mailbox has >50 unread messages, delete oldest 10 unread before adding new."""
    msgs = _load_mailbox(to)
    unread_msgs = [m for m in msgs if not m.get("read")]
    if len(unread_msgs) > 50:
        # Get the 10 oldest unread messages (by timestamp)
        oldest_unread = sorted(unread_msgs, key=lambda m: m.get("timestamp", ""))[:10]
        oldest_ids = {m["id"] for m in oldest_unread}
        msgs = [m for m in msgs if m["id"] not in oldest_ids]
        _save_mailbox(to, msgs)


def cmd_send(to, subject="", body="", urgent=False, ref=None):
    to = to.replace("@", "").strip().lower()
    if to not in VALID_AGENTS:
        return {"ok": False, "error": f"unknown agent: {to}. Valid: {', '.join(VALID_AGENTS)}"}

    from_agent = "main-coordinator"

    # Deduplication: check for exact (to, subject, from) match with read=False
    dup_idx, dup_msg = _deduplicate_msg(to, subject, from_agent)
    msgs = _load_mailbox(to)

    if dup_idx is not None:
        # Update existing unread message instead of creating new one
        msgs[dup_idx]["timestamp"] = datetime.now().isoformat()
        msgs[dup_idx]["body"] = body
        if urgent:
            msgs[dup_idx]["urgent"] = urgent
        if ref:
            msgs[dup_idx]["ref"] = ref
        _save_mailbox(to, msgs)
        return {"ok": True, "data": {"id": msgs[dup_idx]["id"], "to": to, "deduplicated": True}}

    msg = {
        "id": f"{to}-{datetime.now().strftime('%Y%m%d%H%M%S%f')}",
        "from": from_agent,
        "to": to,
        "subject": subject or "(no subject)",
        "body": body,
        "timestamp": datetime.now().isoformat(),
        "read": False,
        "urgent": urgent,
        "ref": ref
    }
    msgs.append(msg)

    # Enforce max unread: if >50 unread, prune oldest 10 before saving
    _enforce_max_unread(to)
    _save_mailbox(to, msgs)
    return {"ok": True, "data": {"id": msg["id"], "to": to}}


def cmd_inbox(agent):
    agent = agent.replace("@", "").strip().lower()
    msgs = _load_mailbox(agent)
    unread = sum(1 for m in msgs if not m.get("read"))
    # Sort: unread first (desc), then by timestamp desc
    sorted_msgs = sorted(msgs, key=lambda m: (m.get("read", False), m.get("timestamp", "")))
    summary = []
    for m in sorted_msgs[-20:]:  # last 20 messages after sorting
        summary.append({
            "id": m["id"],
            "from": m.get("from", "?"),
            "subject": m["subject"],
            "timestamp": m["timestamp"],
            "unread": not m.get("read", False)
        })
    return {"ok": True, "data": {"agent": agent, "total": len(msgs), "unread": unread, "messages": summary}}


def cmd_list():
    """Show all mailboxes with unread counts summary table."""
    rows = []
    total_unread = 0
    for f in _list_mailbox_files():
        agent = f.stem
        msgs = _load_mailbox(agent)
        unread = sum(1 for m in msgs if not m.get("read"))
        total_unread += unread
        rows.append({"agent": agent, "total": len(msgs), "unread": unread})
    return {"ok": True, "data": {"total_unread": total_unread, "mailboxes": rows}}


def cmd_count():
    """Return only total unread across all mailboxes."""
    total_unread = 0
    for f in _list_mailbox_files():
        agent = f.stem
        msgs = _load_mailbox(agent)
        total_unread += sum(1 for m in msgs if not m.get("read"))
    return total_unread


def cmd_read(msg_id):
    for agent in VALID_AGENTS:
        msgs = _load_mailbox(agent)
        for m in msgs:
            if m["id"] == msg_id:
                m["read"] = True
                _save_mailbox(agent, msgs)
                return {"ok": True, "data": {"id": m["id"], "from": m.get("from"), "subject": m["subject"], "body": m["body"], "timestamp": m["timestamp"], "urgent": m.get("urgent", False), "ref": m.get("ref")}}
    return {"ok": False, "error": f"message {msg_id} not found"}


def cmd_clear(agent=None):
    if agent:
        agent = agent.replace("@", "").strip().lower()
        f = _agent_file(agent)
        if f.exists():
            _save_mailbox(agent, [])
        return {"ok": True, "data": f"cleared {agent} mailbox"}
    else:
        for a in VALID_AGENTS:
            f = _agent_file(a)
            if f.exists():
                _save_mailbox(a, [])
        return {"ok": True, "data": "cleared all mailboxes"}


def main():
    parser = argparse.ArgumentParser(description="Agent Mail System")
    sub = parser.add_subparsers(dest="cmd", required=True)

    p_send = sub.add_parser("send")
    p_send.add_argument("to", help="Agent to send to (e.g., code-builder)")
    p_send.add_argument("--subject", "-s", default="")
    p_send.add_argument("--body", "-b", default="")
    p_send.add_argument("--stdin", action="store_true", help="Read body from stdin")
    p_send.add_argument("--urgent", action="store_true", help="Mark message as urgent")
    p_send.add_argument("--ref", default=None, help="Reference a previous message being replied-to (msg-id)")

    p_inbox = sub.add_parser("inbox")
    p_inbox.add_argument("agent", nargs="?", default="main-coordinator")

    p_list = sub.add_parser("list", help="Show all mailboxes with unread counts")

    p_count = sub.add_parser("count", help="Return total unread count across all mailboxes")

    p_read = sub.add_parser("read")
    p_read.add_argument("msg_id")

    p_clear = sub.add_parser("clear")
    p_clear.add_argument("agent", nargs="?", default=None)

    args = parser.parse_args()

    if args.cmd == "send":
        body = args.body
        if args.stdin:
            body = sys.stdin.read().strip()
        result = cmd_send(args.to, args.subject, body, urgent=args.urgent, ref=args.ref)
    elif args.cmd == "inbox":
        result = cmd_inbox(args.agent)
    elif args.cmd == "list":
        result = cmd_list()
    elif args.cmd == "count":
        result = cmd_count()
        print(result)
        return
    elif args.cmd == "read":
        result = cmd_read(args.msg_id)
    elif args.cmd == "clear":
        result = cmd_clear(args.agent)

    print(json.dumps(result))


if __name__ == "__main__":
    main()
