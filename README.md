# Territory Game

A massive-scale persistent territory control game with strategic rally points, 2:1 combat mechanics, and smart bot AI.

**Repository**: https://github.com/zrandles/territory_game  
**Status**: Playable prototype (v0.1.0)

---

## Quick Start

```bash
git clone git@github.com:zrandles/territory_game.git
cd territory_game
bundle install
bin/rails db:setup
bin/dev           # Start Rails + Tailwind
bin/tick_loop     # Start game loop (separate terminal)
```

Visit **http://localhost:3000/territory_game**

---

## Gameplay

- **2 Factions** (Red vs Blue), 10 players each
- **Arrow keys** to move on 10×20 grid
- **Capture rally points** (★) worth 3x
- **First to 60% control wins**
- **2:1 combat**: Outnumbered? Respawn at rally point
- **Smart bots**: Prioritize rally points automatically

See [docs/SESSION_2025_10_22.md](docs/SESSION_2025_10_22.md) for full details and roadmap.

---

## Tech Stack

Rails 8 • Ruby 3.3.4 • Tailwind CSS • Solid Queue • SQLite

---

## License

MIT
