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
  python mail.py reserve <agent> --paths "src/auth/*,src/lib/*" [--exclusive 0|1] [--reason "<reason>"]
  python mail.py release <agent> --paths "src/auth/*"
  python mail.py reservations [<agent>]

New commands for swarm mail:
  python mail.py reserve   — claim exclusive edit access to paths
  python mail.py release   — release previously reserved paths
  python mail.py reservations — list active reservations (all or for one agent)

All commands return JSON: {"ok": true, "data": ...} or {"ok": false, "error": "..."}
"""

import argparse
import json
import os
import sys
import uuid
from datetime import datetime
from pathlib import Path

MAIL_DIR = Path.home() / ".config" / "opencode" / "memory" / "mailboxes"
RESERVATIONS_FILE = Path.home() / ".config" / "opencode" / "memory" / "reservations.jsonl"
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
        oldest_unread = sorted(unread_msgs, key=lambda m: m.get("timestamp", ""))[:10]
        oldest_ids = {m["id"] for m in oldest_unread}
        msgs = [m for m in msgs if m["id"] not in oldest_ids]
        _save_mailbox(to, msgs)


# ── File Reservation System ───────────────────────────────────────

def _load_reservations():
    """Load all reservations from the JSONL file."""
    if not RESERVATIONS_FILE.exists():
        return []
    try:
        with open(RESERVATIONS_FILE, "r") as f:
            lines = f.readlines()
        result = []
        for line in lines:
            line = line.strip()
            if line:
                try:
                    result.append(json.loads(line))
                except json.JSONDecodeError:
                    pass
        return result
    except Exception:
        return []


def _save_reservation_entry(entry):
    """Append a single reservation entry to the JSONL file."""
    with open(RESERVATIONS_FILE, "a") as f:
        f.write(json.dumps(entry, ensure_ascii=False) + "\n")


def _path_matches_pattern(reserved_path, requested_path):
    """Check if a requested path matches a reserved path pattern (simple glob-like)."""
    import fnmatch
    # Normalize
    rp = reserved_path.replace("\\", "/").rstrip("/")
    rq = requested_path.replace("\\", "/").rstrip("/")

    # Exact match
    if rp == rq:
        return True
    # Glob pattern (contains * or ?)
    if "*" in rp or "?" in rp:
        return fnmatch.fnmatch(rq, rp)
    # Directory prefix (reserved "src/auth/*" matches "src/auth/login.ts")
    if rp.endswith("/*"):
        base = rp[:-2]
        return rq.startswith(base + "/") or rq == base
    return False


def _check_conflict(agent, paths, exclusive=True):
    """Check if any of the paths are already reserved by another agent."""
    reservations = _load_reservations()
    conflicts = []
    for res in reservations:
        if res.get("released_at"):
            continue  # already released
        if exclusive and not res.get("exclusive", True):
            continue  # non-exclusive reservation, skip
        for rp in res.get("paths", []):
            for qp in paths:
                if _path_matches_pattern(rp, qp):
                    conflicts.append({
                        "agent": res.get("agent"),
                        "path": rp,
                        "reserved_at": res.get("created_at")
                    })
    return conflicts


def cmd_reserve(agent, paths, exclusive=True, reason=""):
    """Reserve paths for exclusive access by an agent."""
    agent = agent.replace("@", "").strip().lower()
    paths_list = [p.strip() for p in paths.split(",") if p.strip()]
    if not paths_list:
        return {"ok": False, "error": "no paths provided"}

    # Check for conflicts
    conflicts = _check_conflict(agent, paths_list, exclusive)
    if conflicts:
        return {
            "ok": False,
            "error": "path conflict",
            "conflicts": conflicts
        }

    entry = {
        "id": str(uuid.uuid4())[:8],
        "agent": agent,
        "paths": paths_list,
        "exclusive": exclusive,
        "created_at": datetime.now().isoformat(),
        "released_at": None,
        "reason": reason
    }
    _save_reservation_entry(entry)

    return {
        "ok": True,
        "data": {
            "id": entry["id"],
            "agent": agent,
            "paths": paths_list,
            "exclusive": exclusive,
            "reserved_at": entry["created_at"]
        }
    }


def cmd_release(agent, paths=None):
    """Release previously reserved paths (or all paths for an agent if no paths specified)."""
    agent = agent.replace("@", "").strip().lower()
    reservations = _load_reservations()
    now = datetime.now().isoformat()
    released = []

    if paths:
        paths_list = [p.strip() for p in paths.split(",") if p.strip()]
    else:
        paths_list = None  # release all

    for res in reservations:
        if res.get("released_at"):
            continue
        if res.get("agent") != agent:
            continue

        if paths_list is None:
            # Release all for this agent
            res["released_at"] = now
            released.append({"id": res["id"], "paths": res.get("paths", [])})
        else:
            # Release only matching paths
            still_reserved = []
            for rp in res.get("paths", []):
                matched = any(_path_matches_pattern(rp, qp) for qp in paths_list)
                if matched:
                    released.append({"id": res["id"], "path": rp})
                else:
                    still_reserved.append(rp)
            if still_reserved:
                res["paths"] = still_reserved
            else:
                res["released_at"] = now

    # Rewrite the file with updated reservations
    with open(RESERVATIONS_FILE, "w") as f:
        for res in reservations:
            f.write(json.dumps(res, ensure_ascii=False) + "\n")

    if not released:
        return {"ok": True, "data": {"released": 0, "message": "no matching reservations found"}}
    return {
        "ok": True,
        "data": {"released": len(released), "items": released}
    }


def cmd_reservations(agent=None):
    """List active reservations (all or for a specific agent)."""
    reservations = _load_reservations()
    active = [r for r in reservations if not r.get("released_at")]

    if agent:
        agent = agent.replace("@", "").strip().lower()
        active = [r for r in active if r.get("agent") == agent]

    items = []
    for r in active:
        items.append({
            "id": r["id"],
            "agent": r.get("agent"),
            "paths": r.get("paths", []),
            "exclusive": r.get("exclusive", True),
            "reserved_at": r.get("created_at"),
            "reason": r.get("reason", "")
        })

    return {"ok": True, "data": {"count": len(items), "reservations": items}}


# ── Original Mail Commands ────────────────────────────────────────

def cmd_send(to, subject="", body="", urgent=False, ref=None):
    to = to.replace("@", "").strip().lower()
    if to not in VALID_AGENTS:
        return {"ok": False, "error": f"unknown agent: {to}. Valid: {', '.join(VALID_AGENTS)}"}

    from_agent = "main-coordinator"

    dup_idx, dup_msg = _deduplicate_msg(to, subject, from_agent)
    msgs = _load_mailbox(to)

    if dup_idx is not None:
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
    _enforce_max_unread(to)
    _save_mailbox(to, msgs)
    return {"ok": True, "data": {"id": msg["id"], "to": to}}


def cmd_inbox(agent):
    agent = agent.replace("@", "").strip().lower()
    msgs = _load_mailbox(agent)
    unread = sum(1 for m in msgs if not m.get("read"))
    sorted_msgs = sorted(msgs, key=lambda m: (m.get("read", False), m.get("timestamp", "")))
    summary = []
    for m in sorted_msgs[-20:]:
        summary.append({
            "id": m["id"],
            "from": m.get("from", "?"),
            "subject": m["subject"],
            "timestamp": m["timestamp"],
            "unread": not m.get("read", False)
        })
    return {"ok": True, "data": {"agent": agent, "total": len(msgs), "unread": unread, "messages": summary}}


def cmd_list():
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
    p_send.add_argument("--ref", default=None, help="Reference a previous message (msg-id)")

    p_inbox = sub.add_parser("inbox")
    p_inbox.add_argument("agent", nargs="?", default="main-coordinator")

    p_list = sub.add_parser("list", help="Show all mailboxes with unread counts")
    p_count = sub.add_parser("count", help="Return total unread count across all mailboxes")
    p_read = sub.add_parser("read")
    p_read.add_argument("msg_id")
    p_clear = sub.add_parser("clear")
    p_clear.add_argument("agent", nargs="?", default=None)

    # Swarm mail: reservation commands
    p_reserve = sub.add_parser("reserve")
    p_reserve.add_argument("agent", help="Agent reserving the paths")
    p_reserve.add_argument("--paths", required=True, help="Comma-separated paths (supports * glob)")
    p_reserve.add_argument("--exclusive", type=int, default=1, choices=[0, 1], help="Exclusive lock (default: 1)")
    p_reserve.add_argument("--reason", "-r", default="", help="Reason for reservation")

    p_release = sub.add_parser("release")
    p_release.add_argument("agent", help="Agent releasing paths")
    p_release.add_argument("--paths", help="Comma-separated paths to release (omit to release all)")

    p_reservations = sub.add_parser("reservations")
    p_reservations.add_argument("agent", nargs="?", default=None, help="Filter by agent (omit for all)")

    args = parser.parse_args()
    result = None

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
    elif args.cmd == "reserve":
        result = cmd_reserve(args.agent, args.paths, exclusive=(args.exclusive == 1), reason=args.reason)
    elif args.cmd == "release":
        result = cmd_release(args.agent, getattr(args, "paths", None))
    elif args.cmd == "reservations":
        result = cmd_reservations(getattr(args, "agent", None))

    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()