"""
Intervention Tracker — Count human interventions per session.
Ryan Leopo: "Every time I have to type 'continue' is a failure of the harness."

Usage:
  python intervene.py log "<reason>"        # Log an intervention
  python intervene.py stats [--days 7]      # Show stats for last N days
  python intervene.py today                 # Show today's count
  python intervene.py reset                 # Reset today's counter

Returns JSON with intervention data.
"""

import argparse
import json
import os
from datetime import datetime, timedelta
from pathlib import Path

TRACKER_DIR = Path.home() / ".config" / "opencode" / "memory"
TRACKER_FILE = TRACKER_DIR / "interventions.json"


def _load():
    if TRACKER_FILE.exists():
        try:
            return json.loads(TRACKER_FILE.read_text())
        except Exception:
            pass
    return {"interventions": []}


def _save(data):
    TRACKER_FILE.write_text(json.dumps(data, indent=2))


def cmd_log(reason):
    data = _load()
    now = datetime.now()
    data["interventions"].append({
        "timestamp": now.isoformat(),
        "date": now.strftime("%Y-%m-%d"),
        "reason": reason,
    })
    _save(data)
    today_count = sum(1 for i in data["interventions"] if i["date"] == now.strftime("%Y-%m-%d"))
    return {
        "ok": True,
        "data": {
            "logged": reason,
            "today_total": today_count,
            "all_time_total": len(data["interventions"]),
        }
    }


def cmd_stats(days=7):
    data = _load()
    cutoff = (datetime.now() - timedelta(days=days)).strftime("%Y-%m-%d")

    by_day = {}
    total = 0
    for i in data["interventions"]:
        total += 1
        if i["date"] >= cutoff:
            by_day[i["date"]] = by_day.get(i["date"], 0) + 1

    # Top reasons
    reasons = {}
    for i in data["interventions"]:
        reasons[i["reason"]] = reasons.get(i["reason"], 0) + 1
    top_reasons = sorted(reasons.items(), key=lambda x: x[1], reverse=True)[:5]

    return {
        "ok": True,
        "data": {
            "days_scanned": days,
            "total_interventions": total,
            "by_day": dict(sorted(by_day.items())),
            "daily_average": round(total / max(days, 1), 1),
            "top_reasons": [{"reason": r, "count": c} for r, c in top_reasons],
        }
    }


def cmd_today():
    data = _load()
    today = datetime.now().strftime("%Y-%m-%d")
    today_items = [i for i in data["interventions"] if i["date"] == today]
    return {
        "ok": True,
        "data": {
            "date": today,
            "count": len(today_items),
            "interventions": [
                {"time": i["timestamp"].split("T")[1][:5], "reason": i["reason"]}
                for i in today_items[-20:]
            ],
        }
    }


def cmd_reset():
    today = datetime.now().strftime("%Y-%m-%d")
    data = _load()
    data["interventions"] = [i for i in data["interventions"] if i["date"] != today]
    _save(data)
    return {"ok": True, "data": {"message": f"Cleared {today}'s interventions"}}


def main():
    parser = argparse.ArgumentParser(description="Intervention Tracker")
    sub = parser.add_subparsers(dest="cmd", required=True)

    p_log = sub.add_parser("log")
    p_log.add_argument("reason", help="Why did the human intervene?")

    p_stats = sub.add_parser("stats")
    p_stats.add_argument("--days", type=int, default=7)

    sub.add_parser("today")
    sub.add_parser("reset")

    args = parser.parse_args()

    cmd_map = {
        "log": lambda: cmd_log(args.reason),
        "stats": lambda: cmd_stats(args.days),
        "today": lambda: cmd_today(),
        "reset": lambda: cmd_reset(),
    }

    result = cmd_map[args.cmd]()
    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
