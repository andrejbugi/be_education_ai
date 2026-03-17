# Badge And Level Icon Spec

This doc is for design work.

It turns the current backend gamification logic into a stable badge/level list so icons can be created consistently.

Important:
- the backend currently stores only milestone badges as `student_badges`
- the backend currently stores level as a numeric field on `student_progress_profiles`
- level badges below are a design/system spec derived from the current level formula
- they are not separate persisted badge rows yet

## Current backend logic summary

## Levels

Current formula:
- `current_level = floor(total_xp / 100) + 1`

That means:
- Level 1 starts at `0 XP`
- each next level starts every `100 XP`

Examples:
- `0-99 XP` => level 1
- `100-199 XP` => level 2
- `200-299 XP` => level 3

## Stored milestone badges

These are the real backend milestone badges implemented today:

| Code | Macedonian Name | Unlock condition |
|---|---|---|
| `first_completion` | `Прва победа` | first completed assignment |
| `streak_3` | `Во серија` | active streak of at least 3 days |
| `high_achiever` | `Одличен резултат` | average grade `>= 90` with at least 3 graded assignments |
| `attendance_star` | `Редовен ученик` | attendance `>= 95%` with at least 5 records |
| `ai_explorer` | `AI истражувач` | at least 1 AI session |

## Level badge system for icon design

Recommended design convention:
- code: `level_<n>`
- label: `Ниво <n>`
- unlocks when `current_level >= n`
- should be visually derivable from one family/template

Suggested tier colors for easier icon production:
- levels `1-4`: bronze / copper family
- levels `5-8`: silver / teal family
- levels `9-12`: gold / amber family
- levels `13-16`: sapphire / royal family
- levels `17-20`: obsidian / elite family

This does not change backend logic.
It is only a visual grouping for icons.

## Generated level badge list

### Tier 1

| Code | Label | Reached at XP | Active XP range |
|---|---|---:|---:|
| `level_1` | `Ниво 1` | `0` | `0-99` |
| `level_2` | `Ниво 2` | `100` | `100-199` |
| `level_3` | `Ниво 3` | `200` | `200-299` |
| `level_4` | `Ниво 4` | `300` | `300-399` |

### Tier 2

| Code | Label | Reached at XP | Active XP range |
|---|---|---:|---:|
| `level_5` | `Ниво 5` | `400` | `400-499` |
| `level_6` | `Ниво 6` | `500` | `500-599` |
| `level_7` | `Ниво 7` | `600` | `600-699` |
| `level_8` | `Ниво 8` | `700` | `700-799` |

### Tier 3

| Code | Label | Reached at XP | Active XP range |
|---|---|---:|---:|
| `level_9` | `Ниво 9` | `800` | `800-899` |
| `level_10` | `Ниво 10` | `900` | `900-999` |
| `level_11` | `Ниво 11` | `1000` | `1000-1099` |
| `level_12` | `Ниво 12` | `1100` | `1100-1199` |

### Tier 4

| Code | Label | Reached at XP | Active XP range |
|---|---|---:|---:|
| `level_13` | `Ниво 13` | `1200` | `1200-1299` |
| `level_14` | `Ниво 14` | `1300` | `1300-1399` |
| `level_15` | `Ниво 15` | `1400` | `1400-1499` |
| `level_16` | `Ниво 16` | `1500` | `1500-1599` |

### Tier 5

| Code | Label | Reached at XP | Active XP range |
|---|---|---:|---:|
| `level_17` | `Ниво 17` | `1600` | `1600-1699` |
| `level_18` | `Ниво 18` | `1700` | `1700-1799` |
| `level_19` | `Ниво 19` | `1800` | `1800-1899` |
| `level_20` | `Ниво 20` | `1900` | `1900-1999` |

## Suggested icon direction

For level badges:
- keep one base shape across all levels
- change border/accent/trophy/star count by tier
- place the level number prominently in the center
- reserve stronger glow/frame treatment for tier boundaries: `4`, `8`, `12`, `16`, `20`

For milestone badges:
- use unique icon metaphor per badge

Suggested metaphors:
- `first_completion`: checkmark + paper
- `streak_3`: flame or lightning trail
- `high_achiever`: crown or laurel
- `attendance_star`: calendar + star
- `ai_explorer`: spark/robot/constellation

## If you want a larger range

The formula continues forever:
- `level_n`
- reached at XP: `(n - 1) * 100`
- active range: `((n - 1) * 100) - (n * 100 - 1)`

Examples:
- `level_21` starts at `2000 XP`
- `level_30` starts at `2900 XP`
- `level_50` starts at `4900 XP`

For practical icon production, levels `1-20` are a good first set.
