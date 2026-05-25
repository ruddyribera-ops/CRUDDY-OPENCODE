"""
Agent Rules Checker — Scan code against time-traveling rules.
Inspired by oh-my-pi's .omp/rules/ pattern.

Usage:
  python check-rules.py <path>              # Check file or directory against all rules
  python check-rules.py <path> --rule <name> # Check against specific rule
  python check-rules.py list                # List all available rules
  python check-rules.py validate            # Validate rule files

Returns JSON with violations found.
"""

import argparse
import json
import os
import re
import sys
from pathlib import Path

RULES_DIR = Path.home() / ".config" / "opencode" / "rules" / "agent_rules"

# File extensions each rule should be applied to (if scope says "tool:edit(**/*.py)")
EXT_MAP = {
    "py": [".py"],
    "ts": [".ts", ".tsx"],
    "js": [".js", ".jsx", ".mjs"],
    "tsx": [".tsx"],
    "jsx": [".jsx"],
    "toml": [".toml", ".cfg"],
    "txt": [".txt", ".md", ".env"],
    "go": [".go"],
    "rs": [".rs"],
    "php": [".php"],
    "java": [".java"],
}

# Known patterns that should NOT trigger rules
IGNORE_PATTERNS = [
    r"#\s*noqa",           # Python noqa comment
    r"//\s*noqa",           # JS noqa
    r"#\s*rule:ignore",     # Rule-specific ignore
    r"#\s*no-check",        # General ignore
    r"print\(.*#.*debug",   # Explicit debug comment
    r"console\.log\(.*//.*log",  # Explicit log comment
    r"__main__",            # Python main guard
    r"if\s+__name__",       # Python name check
]


def _load_rules():
    """Load all rule files from the rules directory. Returns list of rule dicts."""
    rules = []
    if not RULES_DIR.exists():
        return rules

    for f in sorted(RULES_DIR.glob("*.md")):
        content = f.read_text(encoding="utf-8", errors="ignore")
        rule = _parse_rule_frontmatter(content, f.stem)
        if rule:
            rules.append(rule)
    return rules


def _parse_rule_frontmatter(content, name):
    """Parse YAML frontmatter from rule markdown file."""
    rule = {"name": name, "file": str(name) + ".md"}

    # Extract frontmatter
    frontmatter_match = re.match(r"^---\s*\n(.*?)\n---", content, re.DOTALL)
    if not frontmatter_match:
        return None

    fm = frontmatter_match.group(1)
    for line in fm.split("\n"):
        line = line.strip()
        if ":" not in line:
            continue
        key, _, value = line.partition(":")
        key = key.strip()
        value = value.strip().strip('"').strip("'")

        if key == "condition":
            rule["condition"] = value
        elif key == "multiline":
            rule["multiline"] = value.lower() in ("true", "yes", "1")
        elif key == "severity":
            rule["severity"] = value
        elif key == "scope":
            rule["scope"] = value
        elif key == "description":
            rule["description"] = value
        elif key == "triggered_by":
            rule["triggered_by"] = value

    # Extract the fix instruction (first code block)
    fix_match = re.search(r"## Fix\s*\n(.*?)(?=\n##|\Z)", content, re.DOTALL)
    if fix_match:
        rule["fix"] = fix_match.group(1).strip()[:200]

    return rule


def _scope_matches(rule, filepath):
    """Check if a rule's scope applies to this file."""
    scope = rule.get("scope", "")
    if not scope:
        return True  # No scope = applies everywhere

    ext = Path(filepath).suffix.lower()
    if not ext:
        return False

    # Extract extension patterns from scope
    # Handle both: *.{ts,tsx} and *.py
    for match in re.finditer(r"\*\.(\{([^}]+)\}|(\w+))", scope):
        exts_str = match.group(2) or match.group(3)
        for e in exts_str.split(","):
            e = e.strip()
            if ext == f".{e}":
                return True

    return False


def _should_ignore(line):
    """Check if a line should be ignored (has noqa or similar markers)."""
    for pattern in IGNORE_PATTERNS:
        if re.search(pattern, line, re.IGNORECASE):
            return True
    return False


def _check_file(filepath, rules):
    """Check a single file against all matching rules."""
    violations = []
    try:
        with open(filepath, "r", encoding="utf-8", errors="ignore") as f:
            content = f.read()
    except Exception:
        return violations

    lines = content.split("\n")

    for rule in rules:
        if not _scope_matches(rule, filepath):
            continue

        condition = rule.get("condition")
        if not condition:
            continue

        try:
            flags = 0
            if rule.get("multiline"):
                flags = re.DOTALL
            pattern = re.compile(condition, flags)
        except re.error:
            continue

        # Multi-line matching: search entire file content
        if rule.get("multiline"):
            for match in pattern.finditer(content):
                if _should_ignore(match.group()):
                    continue
                # Find line number from position
                line_num = content[:match.start()].count("\n") + 1
                violations.append({
                    "file": filepath,
                    "line": line_num,
                    "rule": rule["name"],
                    "severity": rule.get("severity", "warning"),
                    "message": rule.get("triggered_by", rule.get("description", "")),
                    "fix_hint": rule.get("fix", "")[:100],
                })
            continue

        # Line-by-line matching (default)
        for i, line in enumerate(lines, 1):
            if _should_ignore(line):
                continue
            if pattern.search(line):
                violations.append({
                    "file": filepath,
                    "line": i,
                    "rule": rule["name"],
                    "severity": rule.get("severity", "warning"),
                    "message": rule.get("triggered_by", rule.get("description", "")),
                    "fix_hint": rule.get("fix", "")[:100],
                })

    return violations


def cmd_check(path, rule_name=None):
    p = Path(path)
    if p.is_file():
        files = [str(p)]
    elif p.is_dir():
        files = []
        for ext_set in EXT_MAP.values():
            for ext in ext_set:
                files.extend(str(f) for f in p.rglob(f"*{ext}"))
    else:
        return {"ok": False, "error": f"path not found: {path}"}

    rules = _load_rules()
    if rule_name:
        rules = [r for r in rules if r["name"] == rule_name]
    if not rules:
        return {"ok": True, "data": {"files": len(files), "violations": [], "rules_active": 0}}

    all_violations = []
    for f in files:
        all_violations.extend(_check_file(f, rules))

    errors = [v for v in all_violations if v.get("severity") == "error"]
    warnings = [v for v in all_violations if v.get("severity") == "warning"]
    infos = [v for v in all_violations if v.get("severity") == "info"]

    return {
        "ok": True,
        "data": {
            "files_scanned": len(files),
            "rules_active": len(rules),
            "total_violations": len(all_violations),
            "errors": len(errors),
            "warnings": len(warnings),
            "infos": len(infos),
            "violations_summary": [f"{v['rule']}:{v['line']} {v['message']}" for v in all_violations],
        }
    }


def cmd_list():
    rules = _load_rules()
    return {
        "ok": True,
        "data": {
            "rules": [
                {
                    "name": r["name"],
                    "description": r.get("description", ""),
                    "severity": r.get("severity", "?"),
                    "condition": r.get("condition", "")[:60],
                }
                for r in rules
            ],
            "total": len(rules),
        }
    }


def cmd_validate():
    rules = _load_rules()
    issues = []
    for r in rules:
        if not r.get("condition"):
            issues.append(f"{r['name']}: missing condition")
        elif r.get("condition"):
            try:
                re.compile(r["condition"])
            except re.error as e:
                issues.append(f"{r['name']}: invalid regex: {e}")

    return {
        "ok": len(issues) == 0,
        "data": {
            "rules_loaded": len(rules),
            "issues": issues,
        }
    }


def main():
    parser = argparse.ArgumentParser(description="Agent Rules Checker")
    sub = parser.add_subparsers(dest="cmd")

    p_check = sub.add_parser("check")
    p_check.add_argument("path", help="File or directory to check")
    p_check.add_argument("--rule", default=None, help="Specific rule to check")

    sub.add_parser("list")
    sub.add_parser("validate")

    args = parser.parse_args()

    if args.cmd == "check":
        result = cmd_check(args.path, args.rule)
    elif args.cmd == "list":
        result = cmd_list()
    elif args.cmd == "validate":
        result = cmd_validate()
    else:
        if not args.cmd:
            parser.print_help()
            return
        result = {"ok": False, "error": f"unknown command: {args.cmd}"}

    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
