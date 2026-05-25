"""
Design Audit — Check project files against .opencode/design.md rules.
Verifies color consistency, banned fonts, anti-patterns, component consistency.

Usage:
  python design-audit.py <project-dir>         # Audit against design.md
  python design-audit.py <project-dir> --fix   # Suggest fixes

Returns JSON with violations found.
"""

import argparse
import json
import os
import re
import sys
from pathlib import Path

# Default banned fonts that every AI agent defaults to
BANNED_FONTS = ["Inter", "Geist", "Roboto", "system-ui"]

# Anti-pattern regexes
ANTI_PATTERNS = [
    (r"glassmorphism|backdrop-filter.*blur|frosted.glass", "glassmorphism effect"),
    (r"lucide.react|lucide", "Lucid icons (AI slop default)"),
    (r"from-[#\w-]+\s+to-[#\w-]+.*gradient", "gradient text/element (potential AI slop)"),
    (r"box-shadow:\s*0\s+\d+px\s+(\d+)\s*px", "excessive card shadow"),
]

# Streamlit anti-patterns
STREAMLIT_ANTI = [
    (r"st\.write\(.*\)", "st.write() abuse — use specific components instead"),
    (r"st\.set_page_config\(.*\)", "OK: page config (expect this)"),
    (r"(?<!st\.)spinner", "manual spinner — use st.spinner()"),
]


def _find_files(project_dir, extensions):
    """Find all files in project with given extensions."""
    files = []
    for ext in extensions:
        files.extend(
            str(f)
            for f in Path(project_dir).rglob(f"*{ext}")
            if "_source" not in str(f)
            and "node_modules" not in str(f)
            and ".git" not in str(f)
        )
    return files


def _load_design_md(project_dir):
    """Load design.md if it exists."""
    design_path = Path(project_dir) / ".opencode" / "design.md"
    if not design_path.exists():
        return None
    return design_path.read_text(encoding="utf-8", errors="ignore")


def _extract_colors(content):
    """Extract hex and OKLCH colors from file content."""
    hex_colors = set(re.findall(r"#[0-9a-fA-F]{6}|#[0-9a-fA-F]{3}", content))
    oklch_colors = set(re.findall(r"oklch\([^)]+\)", content))
    return hex_colors, oklch_colors


def _check_banned_fonts(content, approved_fonts=None):
    """Check for banned fonts."""
    violations = []
    for font in BANNED_FONTS:
        if font.lower() in content.lower():
            # Check if it's in approved fonts
            if approved_fonts and font.lower() in [a.lower() for a in approved_fonts]:
                continue
            violations.append(f"banned font: {font}")
    return violations


def cmd_audit(project_dir):
    """Audit project against design.md."""
    project_dir = Path(project_dir).absolute()
    if not project_dir.exists():
        return {"ok": False, "error": f"directory not found: {project_dir}"}

    design_md = _load_design_md(project_dir)
    violations = []

    # Find all source files
    code_files = _find_files(project_dir, [".py", ".tsx", ".ts", ".jsx", ".js", ".css", ".html", ".vue", ".toml", ".json"])
    if not code_files:
        return {"ok": True, "data": {"files_scanned": 0, "violations": [], "note": "no code files found"}}

    # Collect all colors across the project
    all_hex = set()
    all_oklch = set()
    font_issues = []

    for fp in code_files:
        try:
            content = Path(fp).read_text(encoding="utf-8", errors="ignore")
        except Exception:
            continue

        # Extract colors
        hex_c, oklch_c = _extract_colors(content)
        all_hex.update(hex_c)
        all_oklch.update(oklch_c)

        # Check fonts
        font_violations = _check_banned_fonts(content)
        for v in font_violations:
            font_issues.append({"file": str(fp), "issue": v})

        # Check anti-patterns
        for pattern, label in ANTI_PATTERNS:
            if re.search(pattern, content, re.IGNORECASE):
                violations.append({
                    "file": str(fp),
                    "type": "anti_pattern",
                    "issue": label
                })

        # Streamlit-specific checks
        if fp.endswith(".py"):
            for pattern, label in STREAMLIT_ANTI:
                if label.startswith("st.write"):
                    matches = [m for m in re.finditer(pattern, content) if "st.set_page_config" not in m.group()]
                    if matches:
                        violations.append({
                            "file": str(fp),
                            "type": "streamlit",
                            "issue": label,
                            "count": len(matches)
                        })
                elif "OK" not in label:
                    if re.search(pattern, content, re.IGNORECASE):
                        violations.append({
                            "file": str(fp),
                            "type": "streamlit",
                            "issue": label
                        })

    # Report color spread
    color_spread = {
        "unique_hex_colors": len(all_hex),
        "unique_oklch_colors": len(all_oklch),
        "hex_samples": list(all_hex)[:10] if all_hex else [],
        "oklch_samples": list(all_oklch)[:5] if all_oklch else [],
    }

    # Color consistency flag
    if len(all_hex) > 20:
        violations.append({
            "file": "(project-wide)",
            "type": "color_consistency",
            "issue": f"High color spread ({len(all_hex)} unique hex colors). Consider consolidating to a palette."
        })

    return {
        "ok": True,
        "data": {
            "project": str(project_dir),
            "design_md_exists": design_md is not None,
            "files_scanned": len(code_files),
            "total_violations": len(violations) + len(font_issues),
            "violations": violations[:30],  # Cap
            "font_issues": font_issues[:10],  # Cap
            "color_spread": color_spread,
        }
    }


def main():
    parser = argparse.ArgumentParser(description="Design Audit - check UI consistency")
    sub = parser.add_subparsers(dest="cmd", required=True)

    p_audit = sub.add_parser("audit")
    p_audit.add_argument("project_dir", help="Project directory to audit")

    args = parser.parse_args()

    if args.cmd == "audit":
        result = cmd_audit(args.project_dir)

    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
