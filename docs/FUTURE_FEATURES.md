# Future Features for Territory Game

## Offline Mechanics (High Priority)

### Concept: Persistent Presence
Players contribute even when offline by delegating to a captain.

### Mechanics:

**1. Offline Power Delegation**
- When you log off, you stay on your current tile
- Your power delegates to the highest-ranked player on that tile (the "Captain")
- Captain shows as having +1, +2, etc. indicating delegated players
- Offline players contribute just as much as online players in combat calculations

**2. Captain System**
- Rank determined by: Time on tile, or explicit voting system
- Captain's decisions affect all delegated players
- When captain moves, delegated players stay put (safe default)
- Visual: Captain icon (👑) next to player count

**3. Offline Defeat**
- If your tile is defeated while offline → respawn at home rally point
- You'll see the respawn when you log back in
- History log: "You were defeated at (5,10) and respawned at (2,2)"

**4. Bot Captains (Simulated Leadership)**
- Some bots randomly "go offline" after X ticks
- They delegate to nearby human players
- Gives human player experience of leading a squad
- Shows "+3 offline" to indicate you're leading 3 delegated bots

### Implementation Notes:

**Database Schema:**
```ruby
# Add to Player model
- is_online: boolean (default: true)
- captain_id: integer (references Player, nullable)
- last_seen_at: datetime
- rank_score: integer (for captain selection)

# Add to Territory model
- captain_id: integer (references Player, nullable)
```

**Services:**
```ruby
# app/services/captain_selection_service.rb
# - find_captain_for_territory(territory)
# - delegate_offline_players(territory)

# app/services/offline_simulation_service.rb
# - randomly_offline_bots (10% chance per tick?)
# - bring_bots_back_online (after 5-10 ticks)
```

**UI Changes:**
- Show captain icon next to player count: "5 👑+3"
- Player status indicator: "Leading 3 delegated players"
- Offline player list on hover

### Benefits:

✅ **Casual-Friendly**: Don't need to be online 24/7 to contribute
✅ **Teamwork**: Creates natural squad mechanics
✅ **Leadership**: Player gets to "command" delegated forces
✅ **Persistence**: World feels alive even when you're away
✅ **Strategic**: Choose where to log off matters (safe rally vs. frontline)

### Challenges to Solve:

⚠️ **Captain selection algorithm**: How to prevent gaming the system?
⚠️ **Griefing**: Captain abandons delegated players (move away from safe tile)
⚠️ **Balance**: Does this make stacking too powerful?
⚠️ **UX**: How to communicate delegation clearly?

---

## Other Future Features

### Player Progression
- Persistent stats across rounds
- Titles/badges for achievements
- Cosmetic customization (player icon, color)

### Faction Abilities
- Red: +10% combat strength
- Blue: Faster movement cooldown
- Unlocked based on rally point control

### Territory Modifiers
- Some tiles give resource bonuses
- Chokepoints worth defending
- Hazard tiles (reduce player count by 1)

### Communication
- Simple chat (team only)
- Ping system (mark tiles for attack/defend)
- Captain can issue waypoints

### Scaling
- 5 factions instead of 2
- 50+ players per faction
- Larger maps (20x40)
- Multiple concurrent games/servers

---

**Last Updated**: 2025-10-22
**Priority**: Offline mechanics first, then progression
