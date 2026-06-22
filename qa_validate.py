"""
QA Validation for cruddy-v040 agent files.
Parses YAML frontmatter, validates schema, runs cross-cutting checks.
"""
import os
import re
import sys
from pathlib import Path

try:
    import yaml
except ImportError:
    print("PyYAML not available, trying to install...")
    os.system(f"{sys.executable} -m pip install pyyaml --quiet")
    import yaml

AGENTS_DIR = Path(r"D:\Temp\cruddy-v040\agents")

# Canonical schema from rules/common.md §3
REQUIRED_FIELDS = ["name", "description", "when", "do_not", "triggers", "forbidden_triggers"]

# Trigger format rule from rules/common.md §3:
#   lowercase + only [a-z0-9 _-] chars
TRIGGER_REGEX = re.compile(r"^[a-z0-9 _-]+$")

def parse_frontmatter(text: str):
    """Extract and parse YAML frontmatter. Returns (fm_dict, error_or_None)."""
    if not text.startswith("---"):
        return None, "File does not start with ---"
    end = text.find("\n---", 3)
    if end < 0:
        return None, "No closing --- found"
    fm_raw = text[3:end].lstrip("\n")
    try:
        fm = yaml.safe_load(fm_raw)
        if not isinstance(fm, dict):
            return None, "Frontmatter is not a mapping"
        return fm, None
    except yaml.YAMLError as e:
        return None, f"YAML parse error: {e}"

def check_trigger_chars(trigger: str) -> bool:
    return bool(TRIGGER_REGEX.match(trigger))

def check_when_quoted(raw_fm: str) -> dict:
    """Check whether `when:` field is wrapped in double quotes in raw YAML.
    Returns {quoted: bool, has_colon: bool, line: str}.
    """
    result = {"quoted": False, "has_colon": False, "line": ""}
    for line in raw_fm.splitlines():
        m = re.match(r"^when:\s*(.*)$", line)
        if m:
            value = m.group(1).strip()
            result["line"] = line
            result["has_colon"] = ":" in value
            # Check for double-quote wrap
            if value.startswith('"') and value.endswith('"'):
                result["quoted"] = True
            break
    return result

def check_handoff(text: str) -> dict:
    """Verify the Handoff section per rules/common.md §4.
    Required:
      - `## Handoff` heading
      - `**I dispatch TO:**` subsection
      - `**Routes TO me when:**` subsection
    """
    result = {"has_handoff_heading": False, "has_dispatch_to": False, "has_routes_to_me": False, "position_ok": False}
    if "## Handoff" not in text:
        return result
    result["has_handoff_heading"] = True

    if "**I dispatch TO:**" in text:
        result["has_dispatch_to"] = True
    if "**Routes TO me when:**" in text:
        result["has_routes_to_me"] = True

    # Find positions and check order
    handoff_pos = text.find("## Handoff")
    dispatch_pos = text.find("**I dispatch TO:**", handoff_pos)
    routes_pos = text.find("**Routes TO me when:**", handoff_pos)
    if handoff_pos > 0 and 0 < dispatch_pos < routes_pos:
        result["position_ok"] = True
    return result

def validate_agent(filepath: Path) -> dict:
    """Run all per-file checks against an agent file."""
    text = filepath.read_text(encoding="utf-8")
    raw = text
    fm, err = parse_frontmatter(text)
    result = {
        "file": filepath.name,
        "parse_ok": err is None,
        "parse_error": err,
        "fields_present": [],
        "fields_missing": [],
        "trigger_count": 0,
        "triggers_bad_format": [],
        "forbidden_trigger_count": 0,
        "forbidden_triggers_bad_format": [],
        "when_quoted": False,
        "when_has_colon": False,
        "handoff": check_handoff(text),
        "line_count": text.count("\n") + 1,
        "raw_when_line": "",
    }

    if err:
        return result

    # Required fields
    for field in REQUIRED_FIELDS:
        if field in fm and fm[field] is not None:
            result["fields_present"].append(field)
        else:
            result["fields_missing"].append(field)

    # Trigger checks
    triggers = fm.get("triggers", [])
    if isinstance(triggers, list):
        result["trigger_count"] = len(triggers)
        for t in triggers:
            if not check_trigger_chars(str(t)):
                result["triggers_bad_format"].append(str(t))
    forbidden = fm.get("forbidden_triggers", [])
    if isinstance(forbidden, list):
        result["forbidden_trigger_count"] = len(forbidden)
        for t in forbidden:
            if not check_trigger_chars(str(t)):
                result["forbidden_triggers_bad_format"].append(str(t))

    # when: field quoting
    raw_fm = raw.split("\n---")[0]
    when_info = check_when_quoted(raw_fm)
    result["when_quoted"] = when_info["quoted"]
    result["when_has_colon"] = when_info["has_colon"]
    result["raw_when_line"] = when_info["line"]

    return result

def main():
    files = sorted(AGENTS_DIR.glob("*.md"))
    print(f"Found {len(files)} agent files\n")
    print("=" * 80)
    print("PER-FILE VALIDATION RESULTS")
    print("=" * 80)

    all_results = []
    for f in files:
        r = validate_agent(f)
        all_results.append(r)
        status = "PASS" if r["parse_ok"] and not r["fields_missing"] and not r["triggers_bad_format"] and not r["forbidden_triggers_bad_format"] and r["when_quoted"] and r["handoff"]["has_handoff_heading"] and r["handoff"]["has_dispatch_to"] and r["handoff"]["has_routes_to_me"] else "FAIL"
        print(f"\n[{status}] {r['file']} ({r['line_count']} lines)")
        print(f"  Parse OK: {r['parse_ok']}")
        if r["parse_error"]:
            print(f"  ERROR: {r['parse_error']}")
        print(f"  Fields present: {r['fields_present']}")
        print(f"  Fields missing: {r['fields_missing']}")
        print(f"  Triggers: {r['trigger_count']} (bad format: {r['triggers_bad_format']})")
        print(f"  Forbidden triggers: {r['forbidden_trigger_count']} (bad format: {r['forbidden_triggers_bad_format']})")
        print(f"  when: quoted={r['when_quoted']} has_colon={r['when_has_colon']}")
        print(f"  raw `when:` line: {r['raw_when_line']}")
        print(f"  Handoff: heading={r['handoff']['has_handoff_heading']}, dispatch_to={r['handoff']['has_dispatch_to']}, routes_to_me={r['handoff']['has_routes_to_me']}, position_ok={r['handoff']['position_ok']}")

    # Dump as machine-readable JSON for later analysis
    import json
    out_path = Path(r"D:\Temp\cruddy-v040\qa_validation_results.json")
    out_path.write_text(json.dumps(all_results, indent=2, default=str))
    print(f"\nMachine-readable results: {out_path}")

if __name__ == "__main__":
    main()