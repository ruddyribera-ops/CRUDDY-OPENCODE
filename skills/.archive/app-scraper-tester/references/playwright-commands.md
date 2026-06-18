# Playwright MCP Command Reference

## Navigation
| Command | Use |
|---------|-----|
| `playwright_browser_navigate(url)` | Go to URL (use for MPA) |
| `playwright_browser_snapshot(depth, boxes)` | Capture accessibility tree |
| `playwright_browser_wait_for(text, time)` | Wait for element or time |
| `playwright_browser_evaluate(function)` | Run JS to detect framework/state |

## Interaction
| Command | Use |
|---------|-----|
| `playwright_browser_click(target, element)` | Click link/button |
| `playwright_browser_fill_form(fields)` | Fill form fields |
| `playwright_browser_type(target, text, slowly)` | Type into input |
| `playwright_browser_select_option(target, values)` | Select dropdown option |

## Capture
| Command | Use |
|---------|-----|
| `playwright_browser_network_requests(static)` | Get all requests |
| `playwright_browser_network_request(index, part)` | Get request details |
| `playwright_browser_take_screenshot(type, filename, fullPage)` | Screenshot |
| `playwright_browser_console_messages(level)` | Capture JS console |

## State
| Command | Use |
|---------|-----|
| `playwright_browser_tabs(action)` | List/create/close tabs |
| `playwright_browser_handle_dialog(accept, promptText)` | Handle alert/confirm |
