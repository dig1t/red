[![Linter](https://github.com/dig1t/red/actions/workflows/linter.yml/badge.svg?branch=main)](https://github.com/dig1t/red/actions/workflows/linter.yml)

## What is red?
red is a lightweight, easy-to-use, and efficient event-driven library for Roblox.
red provides a simple API that allows you to create and manage events and actions in your game.

## Benefits
- **Simple API**: red is designed to be easy to use and understand, making it perfect for developers of all skill levels.
- **Lightweight**: red is a lightweight library, meaning that it won't slow down your game or take up unnecessary resources.
- **Type Safety**: red is typed and provides type safety, making it easier to catch errors and bugs in your code.

## Features
- **Stores**: The store is how you will dispatch and listen for events in your game.
- **Actions**: Actions are a way to perform side effects in response to events.
- **Middleware**: Middleware allows you to intercept and modify events before they are dispatched.

## Getting Started
### Installing as a wally dependency
Add the below line to your wally.toml file
```toml
red = "dig1t/red@2.2.5"
```
### Roblox Studio
Download the rbxl file from the [releases](https://github.com/dig1t/red/releases) tab.

Once the place file is open, you can find the package inside `ReplicatedStorage.Packages`.
