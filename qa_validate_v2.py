"""
Improved QA Validation for cruddy-v040 agent files.
- Properly handles multi-line `when:` quoted scalars.
- Verifies handoff order (I dispatch TO must precede Routes TO me when).
- Aggregates all triggers across all 21 agents for overlap detection.
- Runs 12-message dispatch simulation against the AGENTS.md routing table.
"""
import os
import re
import sys
from pathlib import Path
from collections import defaultdict

try:
    import yaml
except ImportError:
    os.system(f"{sys.executable} -m pip install pyyaml --quiet")
    import yaml

AGENTS_DIR = Path(r"D:\Temp\cruddy-v040\agents")
AGENTS_MD  = Path(r"D:\Temp\cruddy-v040\AGENTS.md")

REQUIRED_FIELDS = ["name", "description", "when", "do_not", "triggers", "forbidden_triggers"]
TRIGGER_REGEX = re.compile(r"^[a-z0-9 _-]+$")

# ---- per-file helpers ----

def parse_frontmatter(text: str):
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

def check_when_quoted_v2(raw_fm: str) -> dict:
    """Check `when:` wrapping across multiple lines. Value may span lines
    if the first non-space token is `"` (a YAML double-quoted scalar)."""
    result = {"quoted": False, "starts_with_quote": False, "closed_quote": False, "line_count": 0}
    lines = raw_fm.splitlines()
    for i, line in enumerate(lines):
        m = re.match(r"^when:\s*(.*)$", line)
        if m:
            first = m.group(1)
            result["line_count"] = i + 1
            # Look at the first character of the value (ignoring leading whitespace)
            stripped = first.lstrip()
            if stripped.startswith('"'):
                result["starts_with_quote"] = True
            # If we find a starting quote, scan subsequent lines for closing quote
            if result["starts_with_quote"]:
                # collect all continuation lines until we find a line ending with "
                # YAML folded/scalar continues on indented lines
                buf = first
                # If the first line ends with a closing quote already
                if first.rstrip().endswith('"') and not first.rstrip().endswith('\\"'):
                    result["closed_quote"] = True
                    result["quoted"] = True
                else:
                    # look at subsequent indented lines
                    for j in range(i + 1, len(lines)):
                        cont = lines[j]
                        if cont and not cont.startswith(" ") and not cont.startswith("\t"):
                            break
                        # If this line ends with " (possibly preceded by whitespace)
                        if cont.rstrip().endswith('"'):
                            result["closed_quote"] = True
                            result["quoted"] = True
                            break
            break
    return result

def check_handoff_order(text: str) -> dict:
    """Verify handoff section ordering per canonical schema.
    Expected: ## Handoff -> **I dispatch TO:** -> **Routes TO me when:**
    """
    result = {
        "has_handoff_heading": "## Handoff" in text,
        "has_dispatch_to": False,
        "has_routes_to_me": False,
        "position_ok": False,
        "actual_order": "unknown",
    }
    if not result["has_handoff_heading"]:
        return result
    handoff_pos = text.find("## Handoff")
    dispatch_pos = text.find("**I dispatch TO:**", handoff_pos)
    routes_pos   = text.find("**Routes TO me when:**", handoff_pos)
    if dispatch_pos > 0:
        result["has_dispatch_to"] = True
    if routes_pos > 0:
        result["has_routes_to_me"] = True
    if 0 < dispatch_pos < routes_pos:
        result["position_ok"] = True
        result["actual_order"] = "I-dispatch-first"
    elif 0 < routes_pos < dispatch_pos:
        result["actual_order"] = "routes-first (REVERSED)"
    elif dispatch_pos > 0 and routes_pos < 0:
        result["actual_order"] = "dispatch-only"
    elif routes_pos > 0 and dispatch_pos < 0:
        result["actual_order"] = "routes-only"
    return result

def validate_agent(filepath: Path) -> dict:
    text = filepath.read_text(encoding="utf-8")
    raw_fm = text.split("\n---")[0]
    fm, err = parse_frontmatter(text)
    r = {
        "file": filepath.name,
        "parse_ok": err is None,
        "parse_error": err,
        "fields_present": [], "fields_missing": [],
        "trigger_count": 0, "triggers_bad_format": [], "triggers": [],
        "forbidden_trigger_count": 0, "forbidden_triggers_bad_format": [], "forbidden_triggers": [],
        "when_quoted": False, "when_starts_with_quote": False, "when_closed_quote": False,
        "handoff": check_handoff_order(text),
        "line_count": text.count("\n") + 1,
    }
    if err:
        return r
    for field in REQUIRED_FIELDS:
        if field in fm and fm[field] is not None:
            r["fields_present"].append(field)
        else:
            r["fields_missing"].append(field)
    triggers = fm.get("triggers", [])
    if isinstance(triggers, list):
        r["trigger_count"] = len(triggers)
        r["triggers"] = [str(t) for t in triggers]
        for t in triggers:
            if not TRIGGER_REGEX.match(str(t)):
                r["triggers_bad_format"].append(str(t))
    forbidden = fm.get("forbidden_triggers", [])
    if isinstance(forbidden, list):
        r["forbidden_trigger_count"] = len(forbidden)
        r["forbidden_triggers"] = [str(t) for t in forbidden]
        for t in forbidden:
            if not TRIGGER_REGEX.match(str(t)):
                r["forbidden_triggers_bad_format"].append(str(t))
    qinfo = check_when_quoted_v2(raw_fm)
    r["when_quoted"] = qinfo["quoted"]
    r["when_starts_with_quote"] = qinfo["starts_with_quote"]
    r["when_closed_quote"] = qinfo["closed_quote"]
    return r

# ---- cross-cutting helpers ----

def aggregate_triggers(results):
    """Build trigger -> [agents] mapping and detect overlaps."""
    by_trigger = defaultdict(list)
    for r in results:
        for t in r.get("triggers", []):
            by_trigger[t].append(r["file"])
    # find overlaps: any trigger that maps to >1 agent
    overlaps = {t: agents for t, agents in by_trigger.items() if len(agents) > 1}
    return by_trigger, overlaps

def cross_reference_agents_md(results, agents_md_path):
    """Compare files-on-disk against AGENTS.md identity map."""
    md_text = agents_md_path.read_text(encoding="utf-8")
    files_on_disk = {r["file"].replace(".md", "") for r in results}
    # Identity map section is between Agent Identity Map heading and Handoff Rules
    sec_start = md_text.find("## Agent Identity Map")
    sec_end = md_text.find("---", sec_start)
    sec_end = md_text.find("##", sec_start + 1)
    identity_section = md_text[sec_start:sec_end] if sec_end > 0 else md_text[sec_start:]
    # extract every `| `<name>` |` from identity map
    listed = set(re.findall(r"^\|\s*`?([a-z][a-z0-9-]+)`?\s*\|", identity_section, flags=re.MULTILINE))
    # filter to only valid agent names (lowercase hyphenated)
    listed = {n for n in listed if re.match(r"^[a-z][a-z0-9-]+$", n)}
    on_disk_not_in_md = files_on_disk - listed
    in_md_not_on_disk = listed - files_on_disk
    return {
        "files_on_disk": sorted(files_on_disk),
        "agents_in_md": sorted(listed),
        "on_disk_not_in_md": sorted(on_disk_not_in_md),
        "in_md_not_on_disk": sorted(in_md_not_on_disk),
        "match_count": len(files_on_disk & listed),
        "disk_count": len(files_on_disk),
        "md_count": len(listed),
    }

# ---- dispatch simulation ----

def simulate_dispatch(messages, agents_md_path):
    """For each natural-language message, find all trigger substrings (case-insensitive)
    in AGENTS.md routing table and predict the handler. Flag ambiguity."""
    md_text = agents_md_path.read_text(encoding="utf-8").lower()
    # Build mapping of trigger phrase -> [agents] from the Intent Routing Table.
    # IMPORTANT: use \n---\n (with newlines) to skip column dividers like |---|---|
    table_section_start = md_text.find("## intent")
    table_section_end = md_text.find("\n---\n", table_section_start)
    if table_section_end < 0:
        # fallback: next standalone "---" line
        m = re.search(r"\n---\s*\n", md_text[table_section_start:])
        table_section_end = table_section_start + m.start() if m else len(md_text)
    table_text = md_text[table_section_start:table_section_end]
    # Each row: | Intent | `agent` | trigger words |
    trigger_to_agents = defaultdict(set)
    intent_to_agent = {}
    for line in table_text.splitlines():
        m = re.match(r"^\|\s*([^|]+?)\s*\|\s*`?([a-z][a-z0-9-]+)`?\s*\|\s*([^|]+?)\s*\|\s*$", line)
        if m:
            intent, agent, triggers = m.group(1).strip(), m.group(2).strip(), m.group(3).strip()
            intent_to_agent[intent] = agent
            # parse comma-separated triggers
            for t in re.split(r",\s*", triggers):
                t = t.strip().strip("`")
                if t:
                    trigger_to_agents[t].add(agent)

    results = []
    for msg in messages:
        msg_lower = msg.lower()
        hits = []
        for trig, agents in trigger_to_agents.items():
            if trig and trig in msg_lower:
                hits.append((trig, sorted(agents)))
        # Aggregate predicted agents
        all_agents = set()
        for _, ag in hits:
            all_agents.update(ag)
        # check for ambiguity: are all hits mapping to the same agent?
        unique_agents = sorted(all_agents)
        results.append({
            "message": msg,
            "trigger_hits": hits,
            "predicted_agents": unique_agents,
            "ambiguous": len(unique_agents) > 1,
            "no_match": len(unique_agents) == 0,
        })
    return results

# ---- main ----

def main():
    files = sorted(AGENTS_DIR.glob("*.md"))
    print(f"Found {len(files)} agent files\n")
    results = [validate_agent(f) for f in files]

    # ----- per-file print -----
    print("=" * 80)
    print("PER-FILE VALIDATION")
    print("=" * 80)
    for r in results:
        fail_reasons = []
        if not r["parse_ok"]:
            fail_reasons.append(f"parse: {r['parse_error']}")
        if r["fields_missing"]:
            fail_reasons.append(f"missing fields: {r['fields_missing']}")
        if r["triggers_bad_format"]:
            fail_reasons.append(f"bad triggers: {r['triggers_bad_format']}")
        if r["forbidden_triggers_bad_format"]:
            fail_reasons.append(f"bad forbidden: {r['forbidden_triggers_bad_format']}")
        if not r["when_quoted"]:
            fail_reasons.append("when: NOT double-quoted")
        if not r["handoff"]["has_handoff_heading"]:
            fail_reasons.append("no ## Handoff")
        if not r["handoff"]["has_dispatch_to"]:
            fail_reasons.append("no **I dispatch TO:**")
        if not r["handoff"]["has_routes_to_me"]:
            fail_reasons.append("no **Routes TO me when:**")
        if r["handoff"]["has_dispatch_to"] and r["handoff"]["has_routes_to_me"] and not r["handoff"]["position_ok"]:
            fail_reasons.append(f"handoff order: {r['handoff']['actual_order']}")
        status = "PASS" if not fail_reasons else "FAIL"
        print(f"\n[{status}] {r['file']}  ({r['line_count']} lines)")
        if fail_reasons:
            for x in fail_reasons:
                print(f"   - {x}")

    # ----- trigger overlap -----
    print("\n" + "=" * 80)
    print("TRIGGER OVERLAP DETECTION (across all 21 agents)")
    print("=" * 80)
    by_trigger, overlaps = aggregate_triggers(results)
    if not overlaps:
        print("No exact-string trigger overlaps detected.")
    else:
        print(f"{len(overlaps)} exact trigger overlaps found:")
        for t, agents in sorted(overlaps.items()):
            print(f"  '{t}' -> {agents}")

    # ----- AGENTS.md coverage -----
    print("\n" + "=" * 80)
    print("AGENTS.md CROSS-REFERENCE")
    print("=" * 80)
    xref = cross_reference_agents_md(results, AGENTS_MD)
    print(f"On-disk agents: {xref['disk_count']} / AGENTS.md agents: {xref['md_count']} / matched: {xref['match_count']}")
    if xref["on_disk_not_in_md"]:
        print(f"On disk but missing from AGENTS.md: {xref['on_disk_not_in_md']}")
    if xref["in_md_not_on_disk"]:
        print(f"In AGENTS.md but missing from disk: {xref['in_md_not_on_disk']}")

    # ----- dispatch simulation -----
    print("\n" + "=" * 80)
    print("DISPATCH SIMULATION (12 sample messages)")
    print("=" * 80)
    messages = [
        "save this as a skill for future use",
        "daily standup, what changed",
        "analyze performance of last sprint",
        "design a landing page for our product",
        "deploy to staging and verify",
        "fix the broken login button",
        "explain how this code works",
        "review my pull request",
        "test plan for the new feature",
        "security audit on the API",
        "create a README with setup instructions",
        "what's the architecture tradeoff",
    ]
    sim = simulate_dispatch(messages, AGENTS_MD)
    for s in sim:
        flag = "AMBIGUOUS" if s["ambiguous"] else ("NO-MATCH" if s["no_match"] else "OK")
        print(f"\n[{flag}] \"{s['message']}\"")
        print(f"   Predicted: {s['predicted_agents']}")
        for trig, ag in s["trigger_hits"]:
            print(f"     hit '{trig}' -> {ag}")

    # ----- write JSON for later use -----
    import json
    out = {
        "per_file": results,
        "trigger_overlaps": overlaps,
        "agents_md_xref": xref,
        "dispatch_simulation": sim,
    }
    Path(r"D:\Temp\cruddy-v040\qa_validation_v2.json").write_text(json.dumps(out, indent=2, default=str))
    print(f"\nWrote D:\\Temp\\cruddy-v040\\qa_validation_v2.json")

if __name__ == "__main__":
    main()