"""
Train.py — Pointer/Import to the Actual Config File Being Improved
=================================================================
This is the ONE file the agent modifies during autoresearch.

In Karpathy's original pattern, train.py is the file that gets edited.
For our use case, this file is a POINTER/IMPORT that references the
actual config file being improved.

The agent should:
1. Read this file to understand what target is being improved
2. Read the target file directly
3. Make changes to the TARGET file (not to train.py)
4. The iterate.py loop handles read → change → eval → keep/revert

If you need to change WHICH file is being improved, edit the TARGET_PATH below.
"""

from pathlib import Path

# =============================================================================
# CONFIGURATION — EDIT THIS TO CHANGE THE TARGET FILE
# =============================================================================

# The actual config file being improved
TARGET_PATH = Path(__file__).parent / "program.md"

# Alternative: uncomment and set to a specific file
# TARGET_PATH = Path.home() / ".config" / "opencode" / "rules" / "challenger-rule.md"

# =============================================================================
# HELPER FUNCTIONS — DO NOT MODIFY
# =============================================================================

def get_target_path() -> Path:
    """Get the current target path."""
    return TARGET_PATH


def get_target_content() -> str:
    """Read the current target content."""
    path = get_target_path()
    if path.exists():
        return path.read_text(encoding="utf-8", errors="ignore")
    return ""


def get_program_content() -> str:
    """Get the program.md content (the skill/instructions for the agent)."""
    program_path = Path(__file__).parent / "program.md"
    if program_path.exists():
        return program_path.read_text(encoding="utf-8", errors="ignore")
    return ""


# =============================================================================
# MAIN — for testing
# =============================================================================

if __name__ == "__main__":
    print(f"Target: {get_target_path()}")
    print(f"Exists: {get_target_path().exists()}")
    if get_target_path().exists():
        content = get_target_content()
        print(f"Size: {len(content)} chars")
        print("---")
        print(content[:500])
