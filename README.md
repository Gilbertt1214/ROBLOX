# 🏠 Jawir Hangout

A feature-rich Roblox hangout game built with **Rojo** and **Roact**, featuring combat, social interactions, and a polished UI experience.

![Roblox](https://img.shields.io/badge/Platform-Roblox-00A2FF?style=for-the-badge&logo=roblox&logoColor=white)
![Lua](https://img.shields.io/badge/Language-Luau-2C2D72?style=for-the-badge&logo=lua&logoColor=white)
![Rojo](https://img.shields.io/badge/Tooling-Rojo%207.4-E13835?style=for-the-badge)

---

## ✨ Features

### ⚔️ Combat System
- Punch and block mechanics with hit detection
- Combat area restriction (arena-based)
- Block health system to prevent infinite blocking
- Auto shift-lock in combat zones
- Mobile-friendly combat buttons

### 💃 Sync Dance
- Synchronized dance system between players
- Instant sync for new participants joining ongoing dances
- Smooth animation transitions

### 🎒 Carry & Throw System
- Pick up and carry other players
- Throw system with physics-based mechanics

### 🎵 Music Player
- Built-in music player with next/previous controls
- In-game music streaming

### 🎨 Full UI System (Roact)
- **Loading Screen** — Animated loading experience
- **Left Sidebar** — Navigation menu
- **Top Right Status** — Status icons with active states
- **Hotbar** — Quick access toolbar
- **Custom Backpack** — Inventory management
- **Emotes View** — Emote selection panel
- **Player Dropdown** — Player list with popup menus
- **Player Interact Menu** — Interact with other players (carry, dance, donate)
- **Profile View** — Player profiles
- **Settings View** — In-game settings
- **Music View** — Music player interface
- **Donate View** — Donation system with notifications
- **Friends View** — Friends list
- **Quest View** — Quest tracker
- **Shop View** — In-game shop
- **Stats View** — Player statistics

### 🌗 Day/Night Cycle
- Dynamic day/night cycle system

### 🎯 Other Features
- Custom cursor system
- Item pickup & giver system
- Player overhead display
- Responsive UI (mobile & desktop)
- UI animations & sound effects
- Theming system (dark mode support)

---

## 📁 Project Structure

```
jawir-hangout/
├── default.project.json     # Rojo project configuration
├── aftman.toml              # Toolchain manager (Rojo 7.4.4)
└── src/
    ├── client/              # Client-side scripts
    │   ├── init.client.lua            # Main client entry point
    │   ├── CombatController.client.lua
    │   ├── CustomCursor.client.lua
    │   ├── ItemPickup.client.lua
    │   └── SyncDanceController.client.lua
    ├── server/              # Server-side scripts
    │   ├── init.server.lua            # Main server entry point
    │   ├── CarrySystem.server.lua
    │   ├── CombatHandler.server.lua
    │   ├── DayNightCycle.server.lua
    │   ├── DonationHandler.server.lua
    │   ├── ItemGiver.server.lua
    │   ├── PlayerOverhead.server.lua
    │   ├── SyncDanceHandler.server.lua
    │   ├── ThrowSystem.server.lua
    │   └── ToolsSetup.server.lua
    └── shared/              # Shared modules & UI
        ├── Components/      # Roact UI components (24 components)
        ├── Roact.lua        # Roact library
        ├── Theme.lua        # UI theming
        ├── UIAnimations.lua # Animation utilities
        ├── UISounds.lua     # Sound effects
        ├── PlayerData.lua   # Player data management
        ├── DayNightCycle.lua
        ├── Icons.lua
        ├── Logger.lua
        ├── ResponsiveUtil.lua
        └── ZIndex.lua
```

---

## 🚀 Getting Started

### Prerequisites

- [Roblox Studio](https://www.roblox.com/create)
- [Aftman](https://github.com/LPGhatguy/aftman) (toolchain manager)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/Gilbertt1214/jawir-hangout.git
   cd jawir-hangout
   ```

2. **Install tools via Aftman**
   ```bash
   aftman install
   ```

3. **Serve with Rojo**
   ```bash
   rojo serve
   ```

4. **Connect in Roblox Studio**
   - Open Roblox Studio
   - Install the [Rojo plugin](https://www.roblox.com/library/13916111004/Rojo)
   - Click **Connect** in the Rojo plugin panel

---

## 🛠️ Tech Stack

| Technology | Purpose |
|------------|---------|
| **Luau** | Programming language |
| **Rojo 7.4** | Sync between filesystem and Roblox Studio |
| **Roact** | Declarative UI framework |
| **Aftman** | Toolchain management |

---

## 📄 License

This project is for personal/educational use.

---

<p align="center">Made with ❤️ for Roblox</p>
