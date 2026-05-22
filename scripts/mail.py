"""
Agent Mail System — Persistent Inter-Agent Communication
Inspired by GasTown nudge/mail pattern.

Usage:
  python mail.py send <to> [--subject "<subj>"] [--body "<msg>" or --stdin]
  python mail.py inbox [<agent>]
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


def cmd_send(to, subject="", body=""):
    to = to.replace("@", "").strip().lower()
    if to not in VALID_AGENTS:
        return {"ok": False, "error": f"unknown agent: {to}. Valid: {', '.join(VALID_AGENTS)}"}

    msgs = _load_mailbox(to)
    msg = {
        "id": f"{to}-{datetime.now().strftime('%Y%m%d%H%M%S%f')}",
        "from": "main-coordinator",
        "subject": subject or "(no subject)",
        "body": body,
        "timestamp": datetime.now().isoformat(),
        "read": False
    }
    msgs.append(msg)
    _save_mailbox(to, msgs)
    return {"ok": True, "data": {"id": msg["id"], "to": to}}


def cmd_inbox(agent):
    agent = agent.replace("@", "").strip().lower()
    msgs = _load_mailbox(agent)
    unread = sum(1 for m in msgs if not m.get("read"))
    summary = []
    for m in msgs[-20:]:  # last 20 messages
        summary.append({
            "id": m["id"],
            "from": m.get("from", "?"),
            "subject": m["subject"],
            "timestamp": m["timestamp"],
            "unread": not m.get("read", False)
        })
    return {"ok": True, "data": {"agent": agent, "total": len(msgs), "unread": unread, "messages": summary}}


def cmd_read(msg_id):
    for agent in VALID_AGENTS:
        msgs = _load_mailbox(agent)
        for m in msgs:
            if m["id"] == msg_id:
                m["read"] = True
                _save_mailbox(agent, msgs)
                return {"ok": True, "data": {"id": m["id"], "from": m.get("from"), "subject": m["subject"], "body": m["body"], "timestamp": m["timestamp"]}}
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

    p_inbox = sub.add_parser("inbox")
    p_inbox.add_argument("agent", nargs="?", default="main-coordinator")

    p_read = sub.add_parser("read")
    p_read.add_argument("msg_id")

    p_clear = sub.add_parser("clear")
    p_clear.add_argument("agent", nargs="?", default=None)

    args = parser.parse_args()

    if args.cmd == "send":
        body = args.body
        if args.stdin:
            body = sys.stdin.read().strip()
        result = cmd_send(args.to, args.subject, body)
    elif args.cmd == "inbox":
        result = cmd_inbox(args.agent)
    elif args.cmd == "read":
        result = cmd_read(args.msg_id)
    elif args.cmd == "clear":
        result = cmd_clear(args.agent)

    print(json.dumps(result))


if __name__ == "__main__":
    main()
