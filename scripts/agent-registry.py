"""
Agent Registry — Inspired by SpecKit Integration Registry pattern.
Reads all agent YAML manifests, validates, generates unified view.

Usage:
  python agent-registry.py list                    # List all agents with stats
  python agent-registry.py validate                # Validate all manifests
  python agent-registry.py graph                   # Show agent dependency/capability graph
  python agent-registry.py report                  # Full registry report

All commands return JSON.
"""

import argparse
import json
import os
import sys
from pathlib import Path

AGENTS_DIR = Path.home() / ".config" / "opencode" / "agents"

# Schema: expected fields per agent type
AGENT_SCHEMA = {
    "required_fields": ["name", "description"],
    "optional_fields": ["triggers", "trigger_words", "color", "emoji", "vibe", "model", "skills", "tools", "duties", "guardrails"],
    "field_types": {
        "name": str,
        "description": str,
        "triggers": list,
        "trigger_words": list,
        "color": str,
        "emoji": str,
        "vibe": str,
        "model": str,
        "skills": list,
        "tools": list,
        "duties": list,
        "guardrails": list,
    },
    "validation_rules": [
        "name must match YAML filename (excluding .yaml extension)",
        "description must be a non-empty string",
        "triggers must be a list of strings if present",
        "skills must be a list of strings if present",
    ],
    "trigger_type": list,
}


def cmd_print_schema():
    """Print the AGENT_SCHEMA as JSON for consumption by external validators."""
    return {
        "ok": True,
        "schema": {
            "required_keys": AGENT_SCHEMA["required_fields"],
            "optional_keys": AGENT_SCHEMA["optional_fields"],
            "field_types": {k: str(v) for k, v in AGENT_SCHEMA["field_types"].items()},
            "validation_rules": AGENT_SCHEMA["validation_rules"],
        }
    }


def _load_agents():
    """Load all agent YAML files from the agents directory. Skip schema files."""
    agents = {}
    errors = []

    for f in sorted(AGENTS_DIR.glob("*.yaml")):
        name = f.stem
        # Skip schema/definition files that aren't actual agent manifests
        if name.endswith("-schema") or name == "agent_schema":
            continue
        import yaml
        try:
            with open(f, "r", encoding="utf-8-sig") as fh:
                data = yaml.safe_load(fh)
            if data and isinstance(data, dict):
                agents[name] = data
            else:
                errors.append({"file": str(f), "error": "empty or invalid YAML"})
        except yaml.YAMLError as e:
            errors.append({"file": str(f), "error": str(e)})

    return agents, errors


def cmd_list():
    agents, errors = _load_agents()
    result = []
    for name, data in agents.items():
        skills = data.get("skills", [])
        if isinstance(skills, str):
            skills = [skills]
        result.append({
            "name": name,
            "description": (lambda x: (x or "")[:80] if x else "")(data.get("description")),
            "triggers": data.get("triggers", [])[:3],
            "skills_count": len(skills) if skills else 0,
            "has_duties": "duties" in data,
            "has_guardrails": "guardrails" in data,
        })
    return {"ok": True, "data": {"agents": result, "total": len(result), "errors": errors}}


def cmd_validate():
    agents, load_errors = _load_agents()
    issues = []

    for name, data in agents.items():
        # Check required fields
        for field in AGENT_SCHEMA["required_fields"]:
            if field not in data:
                issues.append({"agent": name, "severity": "error", "field": field, "issue": "missing required field"})

        # Check trigger type
        triggers = data.get("triggers")
        if triggers is not None and not isinstance(triggers, list):
            issues.append({"agent": name, "severity": "warning", "field": "triggers", "issue": "triggers should be a list"})

        # Check skills
        skills = data.get("skills", [])
        if isinstance(skills, str):
            issues.append({"agent": name, "severity": "info", "field": "skills", "issue": "skills is a string, should be a list"})

    # Check for duplicate agent names (cross-reference with markdown files)
    md_files = list(AGENTS_DIR.glob("*.md"))
    md_names = {f.stem for f in md_files}
    yaml_names = set(agents.keys())
    only_md = md_names - yaml_names
    only_yaml = yaml_names - md_names
    if only_md:
        issues.append({"severity": "warning", "issue": f"agents with .md but no .yaml: {', '.join(only_md)}"})
    if only_yaml:
        issues.append({"severity": "info", "issue": f"agents with .yaml but no .md: {', '.join(only_yaml)}"})

    total_issues = len(issues)
    return {
        "ok": True,
        "data": {
            "validated": len(agents),
            "issues": total_issues,
            "errors": [i for i in issues if i.get("severity") == "error"],
            "warnings": [i for i in issues if i.get("severity") == "warning"],
            "infos": [i for i in issues if i.get("severity") == "info"],
            "load_errors": load_errors,
        }
    }


def cmd_graph():
    agents, errors = _load_agents()
    nodes = []
    edges = []

    for name, data in agents.items():
        # Each agent is a node
        nodes.append({
            "id": name,
            "type": data.get("name", name),
            "description": (data.get("description", "") or "")[:50],
            "skills": data.get("skills", []) if isinstance(data.get("skills", []), list) else [data.get("skills", "")],
        })

        # Check for cross-agent references in description/triggers
        desc = str(data.get("description", "")) + " " + str(data.get("triggers", ""))
        for other_name in agents:
            if other_name != name and other_name.replace("-", " ") in desc.lower():
                edges.append({"from": name, "to": other_name, "type": "references"})

    return {
        "ok": True,
        "data": {
            "nodes": nodes,
            "edges": edges,
            "total_agents": len(nodes),
            "total_references": len(edges),
        }
    }


def cmd_report():
    agents, load_errors = _load_agents()
    validation = cmd_validate()["data"]

    # Collect statistics
    total_triggers = sum(len(data.get("triggers", [])) if isinstance(data.get("triggers", []), list) else 1 for data in agents.values())
    total_skills = sum(len(data.get("skills", [])) if isinstance(data.get("skills", []), list) else 1 for data in agents.values() if data.get("skills"))
    agents_with_guardrails = sum(1 for data in agents.values() if "guardrails" in data)
    agents_with_duties = sum(1 for data in agents.values() if "duties" in data)

    return {
        "ok": True,
        "data": {
            "summary": {
                "total_agents": len(agents),
                "total_triggers": total_triggers,
                "total_skills": total_skills,
                "agents_with_guardrails": agents_with_guardrails,
                "agents_with_duties": agents_with_duties,
                "validation_issues": validation.get("issues", 0),
                "load_errors": len(load_errors),
            },
            "agents": {name: {"description": data.get("description", ""),
                              "triggers": len(data.get("triggers", [])) if isinstance(data.get("triggers", []), list) else 1,
                              "skills": data.get("skills", []),
                              "has_guardrails": "guardrails" in data} for name, data in agents.items()},
            "validation": validation,
        }
    }


def main():
    parser = argparse.ArgumentParser(description="Agent Registry — SpecKit-style integration registry")
    sub = parser.add_subparsers(dest="cmd", required=True)

    sub.add_parser("list")
    sub.add_parser("validate")
    sub.add_parser("graph")
    sub.add_parser("report")
    sub.add_parser("print-schema")

    args = parser.parse_args()

    cmd_map = {
        "list": cmd_list,
        "validate": cmd_validate,
        "graph": cmd_graph,
        "report": cmd_report,
        "print-schema": cmd_print_schema,
    }

    result = cmd_map[args.cmd]()
    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
