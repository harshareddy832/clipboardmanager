# Clipboard Manager

A macOS menu bar app that keeps a history of everything you copy.

## Requirements

- macOS 13 (Ventura) or later
- Xcode Command Line Tools / Swift

## Run

```bash
swift run
```

First build takes ~30 seconds. After that a clipboard icon appears in your menu bar.

## Features

- **History** — tracks last 50–unlimited copied texts
- **Starred** — star items to save them permanently (persists across restarts)
- **Search** — filter through your history instantly
- **Auto-clear** — optionally clear history after 1 hour, 6 hours, 1 day, 1 week, or 30 days
- **Settings** — configure history limit and auto-clear from the gear icon

## Usage

| Action | How |
|---|---|
| Copy an item back | Click it |
| Star an item | Hover → click ★ |
| Delete an item | Hover → click trash |
| View starred items | Click the Starred tab |
| Change settings | Click the gear icon |
| Quit | Footer → Quit |

## Notes

- Lives only in the menu bar, no dock icon
- Regular history is cleared on quit; starred items are not
- Data is stored locally in UserDefaults, never leaves your machine
