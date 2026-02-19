[![Linter](https://github.com/dig1t/red/actions/workflows/linter.yml/badge.svg?branch=main)](https://github.com/dig1t/red/actions/workflows/linter.yml)

# red

A **lightweight, type-safe event system** for Roblox. Build scalable games with predictable state management and clean event handling.

## Why red?

Managing events across your Roblox game can get messy fast. red gives you a structured, type-safe way to handle events, actions, and side effects — without the bloat.

- **Dead simple API** — Dispatch events and listen for them in seconds. No boilerplate.
- **Type safe** — Catch bugs at edit time with full Luau type support.
- **Lightweight** — Minimal overhead. Your game stays fast.
- **Middleware support** — Intercept, log, and transform events before they're processed.

## Quick Start

### Install with Wally
Add this to your `wally.toml`:
```toml
red = "dig1t/red@2.2.10"
```

### Or download from Roblox Studio
Grab the `.rbxl` file from [releases](https://github.com/dig1t/red/releases) and extract the package from `ReplicatedStorage.Packages`.

## How it works

**Stores** hold your event listeners. **Actions** let you respond to events with side effects. **Middleware** gives you control over the event pipeline.

```lua
local store = red.createStore()

-- Listen for events
store:on("playerJoined", function(player)
  print(player.Name .. " joined!")
end)

-- Dispatch events
store:dispatch("playerJoined", player)
```

## Features

- **Stores** — Central hub for dispatching and listening to events
- **Actions** — Run side effects in response to events
- **Middleware** — Intercept and modify events before dispatch

---

Built for developers who want their event system to stay out of the way.
