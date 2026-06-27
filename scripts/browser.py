"""
Robust Browser — CloakBrowser + Scrapling hybrid for OpenCode MCP
CLI interface: python browser.py <command> [args...]

Commands:
  navigate <url> [--timeout N]         Navigate to URL
  click <selector> [--timeout N]       Click element
  type <selector> <text>               Type text into element
  screenshot [path]                     Save screenshot (default: screenshot.png)
  html                                  Return page HTML
  text [selector]                       Get text content (optional: specific element)
  extract <prompt>                      AI extract structured data (uses page context)
  adaptive <selector>                   Scrapling adaptive selector (survives site changes)
  cookies [--domain]                    Get cookies
  close                                 Close browser
  reset                                 Reset browser (new context)
  auth save <profile>                   Save current session cookies as encrypted profile (auto-browser)
  auth load <profile>                   Load saved profile (logs in)
  auth list                              List available profiles
  auth delete <profile>                 Delete a profile

Auth profiles are encrypted with Fernet server-side by auto-browser
(http://127.0.0.1:8000). Set AUTO_BROWSER_API_BEARER_TOKEN env var
or fall back to a hardcoded dev token.

All commands return JSON: {"ok": true, "data": ...} or {"ok": false, "error": "..."}
"""

import argparse
import json
import sys
import os
import time
import traceback
from pathlib import Path

# ── Browser lifecycle ────────────────────────────────────────────────────────

_browser = None
_context = None
_page = None
_initialized = False


def _init():
    global _browser, _context, _page, _initialized
    if _initialized:
        return
    try:
        from cloakbrowser import launch
        _browser = launch()
        _context = _browser.new_context()
        _page = _context.new_page()
        _initialized = True
    except Exception as e:
        print(json.dumps({"ok": False, "error": f"init_failed: {e}"}))
        sys.exit(1)


def _ensure_page():
    global _page
    _init()
    if _page is None:
        raise RuntimeError("no page — call navigate first")


def _reset():
    global _context, _page
    _init()
    if _context:
        _context.close()
    _context = _browser.new_context()
    _page = _context.new_page()
    return {"ok": True, "data": "reset"}


def _close():
    global _browser, _context, _page, _initialized
    if _browser:
        _browser.close()
    _browser = _context = _page = None
    _initialized = False
    return {"ok": True, "data": "closed"}


# ── Core commands ───────────────────────────────────────────────────────────

def cmd_navigate(url, timeout=30000):
    _ensure_page()
    try:
        _page.goto(url, timeout=timeout)
        title = _page.title()
        return {"ok": True, "data": {"title": title, "url": url}}
    except Exception as e:
        return {"ok": False, "error": str(e)}


def cmd_click(selector, timeout=15000):
    _ensure_page()
    try:
        _page.click(selector, timeout=timeout)
        return {"ok": True, "data": "clicked"}
    except Exception as e:
        return {"ok": False, "error": str(e)}


def cmd_type(selector, text, timeout=10000):
    _ensure_page()
    try:
        _page.fill(selector, text)
        return {"ok": True, "data": "typed"}
    except Exception as e:
        return {"ok": False, "error": str(e)}


def cmd_screenshot(path="screenshot.png"):
    _ensure_page()
    try:
        _page.screenshot(path=path, full_page=False)
        return {"ok": True, "data": {"path": str(Path(path).resolve())}}
    except Exception as e:
        return {"ok": False, "error": str(e)}


def cmd_html():
    _ensure_page()
    try:
        return {"ok": True, "data": _page.content()}
    except Exception as e:
        return {"ok": False, "error": str(e)}


def cmd_text(selector=None):
    _ensure_page()
    try:
        if selector:
            el = _page.locator(selector).first
            return {"ok": True, "data": el.text_content()}
        else:
            return {"ok": True, "data": _page.text_content()}
    except Exception as e:
        return {"ok": False, "error": str(e)}


def cmd_adaptive(selector, html=None):
    """
    Uses Scrapling adaptive selectors — survives site redesigns.
    Falls back to CloakBrowser locator if Scrapling is unavailable.
    """
    # Try Scrapling first
    try:
        from scrapling.fetchers import StealthyFetcher
        if html is None:
            html = _page.content()
        page = StealthyFetcher.adaptive_load(html)
        found = page.css(selector, first=False)
        return {
            "ok": True,
            "data": {
                "engine": "scrapling",
                "count": len(found),
                "texts": [el.text_content() for el in found[:10]]
            }
        }
    except Exception:
        pass

    # Fallback to CloakBrowser locator
    try:
        _ensure_page()
        locators = _page.locator(selector)
        count = locators.count()
        return {
            "ok": True,
            "data": {
                "engine": "cloakbrowser",
                "count": count,
                "texts": [locators.nth(i).text_content() for i in range(min(count, 10))]
            }
        }
    except Exception as e:
        return {"ok": False, "error": str(e)}


def cmd_cookies(domain=None):
    _ensure_page()
    try:
        cookies = _context.cookies() if domain is None else _context.cookies(domain=[domain])
        return {"ok": True, "data": cookies}
    except Exception as e:
        return {"ok": False, "error": str(e)}


def cmd_extract(prompt):
    """
    Uses the page's visible text + DOM context to extract structured data.
    Simple heuristic approach — no LLM required, just focused extraction.
    """
    _ensure_page()
    try:
        from scrapling.fetchers import StealthyFetcher
        html = _page.content()
        page = StealthyFetcher.adaptive_load(html)

        # Get all meaningful text content
        elements = page.css('p, h1, h2, h3, h4, li, td, th, span, a, label')
        texts = []
        for el in elements[:200]:
            t = el.text_content()
            if t and len(t.strip()) > 2:
                texts.append(t.strip())

        return {
            "ok": True,
            "data": {
                "extracted_texts": texts,
                "prompt_used": prompt
            }
        }
    except Exception as e:
        return {"ok": False, "error": str(e)}


# ── Auth profile bridge to auto-browser ────────────────────────────────────

import urllib.request
import urllib.error
import urllib.parse
import json as _json
import tempfile

AUTO_BROWSER_URL = os.environ.get("AUTO_BROWSER_URL", "http://127.0.0.1:8000")
AUTO_BROWSER_BEARER = os.environ.get(
    "AUTO_BROWSER_API_BEARER_TOKEN",
    "v+DMT50yu4YR8R/hBkzFX17C2koieuiazSAJFjwvdS4="  # dev fallback
)
AUTO_BROWSER_OPERATOR = os.environ.get("AUTO_BROWSER_OPERATOR_ID", "ruddy")


def _auto_browser_request(path, method="GET", data=None):
    """Make authenticated request to auto-browser REST API."""
    url = f"{AUTO_BROWSER_URL}{path}"
    headers = {
        "Authorization": f"Bearer {AUTO_BROWSER_BEARER}",
        "X-Operator-Id": AUTO_BROWSER_OPERATOR,
        "X-Operator-Name": "Ruddy Ribera",
        "Content-Type": "application/json",
    }
    body = _json.dumps(data).encode() if data is not None else None
    req = urllib.request.Request(url, data=body, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req, timeout=10) as resp:
            return {"ok": True, "status": resp.status, "data": resp.read().decode()}
    except urllib.error.HTTPError as e:
        body_text = e.read().decode() if e.fp else ""
        return {"ok": False, "status": e.code, "error": body_text}
    except Exception as e:
        return {"ok": False, "error": str(e)}


def cmd_auth_save(profile_name):
    """Save current session cookies + storage state to auto-browser as encrypted profile.

    Auto-browser encrypts with Fernet server-side. We just POST the storage state.
    """
    _ensure_page()
    try:
        # Export current context's storage state to a tempfile
        state = _context.storage_state()
        # POST to auto-browser
        result = _auto_browser_request(
            f"/auth-profiles/{urllib.parse.quote(profile_name)}/import",
            method="POST",
            data={"storage_state": state, "name": profile_name}
        )
        if result.get("ok"):
            return {"ok": True, "data": {"profile": profile_name, "saved": True}}
        return result
    except Exception as e:
        return {"ok": False, "error": str(e)}


def cmd_auth_load(profile_name):
    """Load a saved auth profile from auto-browser.

    Returns the storage state so the caller can apply it to a new context.
    Use via: python browser.py auth load <name> | jq -r .data.storage_state > /tmp/state.json
    """
    try:
        result = _auto_browser_request(f"/auth-profiles/{urllib.parse.quote(profile_name)}/export")
        if result.get("ok"):
            return {
                "ok": True,
                "data": {
                    "profile": profile_name,
                    "storage_state_raw": result.get("data", ""),
                }
            }
        return result
    except Exception as e:
        return {"ok": False, "error": str(e)}


def cmd_auth_list():
    """List all auth profiles in auto-browser."""
    try:
        result = _auto_browser_request("/auth-profiles")
        if result.get("ok"):
            return {"ok": True, "data": result.get("data", "")}
        return result
    except Exception as e:
        return {"ok": False, "error": str(e)}


def cmd_auth_delete(profile_name):
    """Delete an auth profile from auto-browser."""
    try:
        result = _auto_browser_request(
            f"/auth-profiles/{urllib.parse.quote(profile_name)}",
            method="DELETE"
        )
        if result.get("ok"):
            return {"ok": True, "data": {"profile": profile_name, "deleted": True}}
        return result
    except Exception as e:
        return {"ok": False, "error": str(e)}


# ── CLI dispatch ────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(description="Robust Browser CLI (CloakBrowser + Scrapling)")
    sub = parser.add_subparsers(dest="cmd", required=True)

    # navigate
    p_nav = sub.add_parser("navigate")
    p_nav.add_argument("url")
    p_nav.add_argument("--timeout", type=int, default=30000)

    # click
    p_click = sub.add_parser("click")
    p_click.add_argument("selector")
    p_click.add_argument("--timeout", type=int, default=15000)

    # type
    p_type = sub.add_parser("type")
    p_type.add_argument("selector")
    p_type.add_argument("text")

    # screenshot
    p_ss = sub.add_parser("screenshot")
    p_ss.add_argument("path", nargs="?", default="screenshot.png")

    # html
    sub.add_parser("html")

    # text
    p_text = sub.add_parser("text")
    p_text.add_argument("selector", nargs="?", default=None)

    # adaptive
    p_ad = sub.add_parser("adaptive")
    p_ad.add_argument("selector")

    # cookies
    p_cook = sub.add_parser("cookies")
    p_cook.add_argument("--domain", default=None)

    # extract
    p_ext = sub.add_parser("extract")
    p_ext.add_argument("prompt")

    # close
    sub.add_parser("close")

    # reset
    sub.add_parser("reset")

    # auth subcommand group
    p_auth = sub.add_parser("auth")
    p_auth_sub = p_auth.add_subparsers(dest="auth_cmd", required=True)
    p_auth_save = p_auth_sub.add_parser("save")
    p_auth_save.add_argument("profile")
    p_auth_load = p_auth_sub.add_parser("load")
    p_auth_load.add_argument("profile")
    p_auth_sub.add_parser("list")
    p_auth_del = p_auth_sub.add_parser("delete")
    p_auth_del.add_argument("profile")

    args = parser.parse_args()

    # Handle commands that don't need page init
    if args.cmd == "close":
        print(json.dumps(_close()))
        return
    if args.cmd == "reset":
        print(json.dumps(_reset()))
        return

    # Auth commands — don't need browser init
    if args.cmd == "auth":
        if args.auth_cmd == "save":
            print(json.dumps(cmd_auth_save(args.profile)))
            return
        if args.auth_cmd == "load":
            print(json.dumps(cmd_auth_load(args.profile)))
            return
        if args.auth_cmd == "list":
            print(json.dumps(cmd_auth_list()))
            return
        if args.auth_cmd == "delete":
            print(json.dumps(cmd_auth_delete(args.profile)))
            return

    # All others need the browser
    cmd_map = {
        "navigate": lambda: cmd_navigate(args.url, args.timeout),
        "click":    lambda: cmd_click(args.selector, args.timeout),
        "type":     lambda: cmd_type(args.selector, args.text),
        "screenshot": lambda: cmd_screenshot(args.path),
        "html":     cmd_html,
        "text":     lambda: cmd_text(args.selector),
        "adaptive": lambda: cmd_adaptive(args.selector),
        "cookies":  lambda: cmd_cookies(args.domain),
        "extract":  lambda: cmd_extract(args.prompt),
    }

    result = cmd_map[args.cmd]()
    print(json.dumps(result))


if __name__ == "__main__":
    main()
