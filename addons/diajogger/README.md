# DiaJogger

Minimalist Dialogue Runtime for Godot (GDScript).

> **Core Philosophy**: All text is markup; control flow is code.
> Markdown describes narrative content and presentation metadata. GDScript controls game flow, state, choices, and world interactions.

---

## Architecture Reading Guide (How to Read the Codebase)

To understand DiaJogger from first principles, read the files in the following bottom-up order:

```text
1. diajogger_event.gd     (The atomic data unit: TARGET, MARKUP, DATA, TEXT)
       ↓
2. diajogger_state.gd     (The presentation state applied as events occur)
       ↓
3. diajogger_document.gd  (In-memory parsed event stream + target lookup table)
       ↓
4. diajogger_caret.gd     (The playhead/scrubber tracking position & active state)
       ↓
5. diajogger_parser.gd    (Regex-based compiler turning Markdown into Document)
       ↓
6. diajogger_view.gd      (UI presentation boundary; zero knowledge of game flow)
       ↓
7. diajogger_runtime.gd   (Minimal loop dispatching events between Caret and View)
       ↓
8. diajogger.gd           (Public facade & Autoload singleton for game scripts)
       ↓
9. examples/              (station.md script & dialogue_demo.gd usage)
```

### Detailed File Roles:

1. [**`diajogger_event.gd`**](file:///workspace/addons/diajogger/diajogger_event.gd) (`DiaJoggerEvent`):
   Start here. The entire system is an event-stream pipeline. Instead of a complex class hierarchy, DiaJogger uses 4 minimal event types: `TARGET`, `MARKUP`, `DATA`, `TEXT`.
2. [**`diajogger_state.gd`**](file:///workspace/addons/diajogger/diajogger_state.gd) (`DiaJoggerState`):
   Represents presentation state (`speaker`, `emotion`, `portrait`, `background`, `music`, arbitrary `data`). Changes whenever `MARKUP` or `DATA` events are consumed.
3. [**`diajogger_document.gd`**](file:///workspace/addons/diajogger/diajogger_document.gd) (`DiaJoggerDocument`):
   Represents the compiled dialogue file in memory, storing the array of events and an index of target entry points. Computes state at any target index.
4. [**`diajogger_caret.gd`**](file:///workspace/addons/diajogger/diajogger_caret.gd) (`DiaJoggerCaret`):
   The central conceptual playhead ("jogger"). Answers: *"Where are we in the document, and what presentation state applies right now?"* Steps forward and updates state.
5. [**`diajogger_parser.gd`**](file:///workspace/addons/diajogger/diajogger_parser.gd) (`DiaJoggerParser`):
   Translates raw Markdown + `@`-tags into a `DiaJoggerDocument`. Supports multi-tag lines (`@s Emily @e angry`), escapes (`\@`), and skips comments (`<!-- -->`, `# `).
6. [**`diajogger_view.gd`**](file:///workspace/addons/diajogger/diajogger_view.gd) (`DiaJoggerView`):
   The presentation boundary. Receives text and state, displays dialogue, awaits player input (`ui_accept` / mouse click), and presents choices. Includes a built-in default UI out-of-the-box.
7. [**`diajogger_runtime.gd`**](file:///workspace/addons/diajogger/diajogger_runtime.gd) (`DiaJoggerRuntime`):
   The minimal loop stepping the Caret: shows text on the View, applies markup/data to state, and stops when reaching the next Target boundary or EOF.
8. [**`diajogger.gd`**](file:///workspace/addons/diajogger/diajogger.gd) (`DiaJoggerFacade` / Autoload `DiaJogger`):
   The public facade singleton. Handles document registration, target resolution, and exposes simple async methods `play()` and `choice()`.
9. [**`examples/`**](file:///workspace/addons/diajogger/examples):
   - [`DemoDialogueScene.tscn`](file:///workspace/addons/diajogger/examples/DemoDialogueScene.tscn): Complete playable test scene with background, character sprites, and click-anywhere advance.
   - [`demo_dialogue_scene.gd`](file:///workspace/addons/diajogger/examples/demo_dialogue_scene.gd): Controller script handling dialogue start, choices, and scene mood changes.
   - [`vn_dialogue_view.gd`](file:///workspace/addons/diajogger/examples/vn_dialogue_view.gd): Custom visual novel view with speaker tag, typewriter effect, and emotion animations.
   - [`station.md`](file:///workspace/addons/diajogger/examples/station.md): Example dialogue script in Markdown with branching.
   - [`dialogue_demo.gd`](file:///workspace/addons/diajogger/examples/dialogue_demo.gd): Minimal headless GDScript example demonstrating game-side flow.
   - [**`notebook/`**](file:///workspace/addons/diajogger/examples/notebook):
     - [`NotebookDialogueView.tscn`](file:///workspace/addons/diajogger/examples/notebook/NotebookDialogueView.tscn): Specialized dialogue view styled as a spiral notebook with metallic rings and ruled lines.
     - [`notebook_dialogue_view.gd`](file:///workspace/addons/diajogger/examples/notebook/notebook_dialogue_view.gd): View logic supporting notebook checklist choices and fountain pen typography.
     - [`notebook_paper.gd`](file:///workspace/addons/diajogger/examples/notebook/notebook_paper.gd): Custom control drawing ruled paper lines and metallic spiral binding rings.
     - [`NotebookDemoScene.tscn`](file:///workspace/addons/diajogger/examples/notebook/NotebookDemoScene.tscn): Playable investigation journal demo.

---

## Markdown Syntax

DiaJogger clearly separates **structure**, **presentation state**, and **arbitrary metadata**:

```md
# Structure tags (always written in full, not affected by @r)
@target <name>      # Named entry point / anchor (e.g. @target Station/Act 1)
@dirty              # Keep text buffer: appends the next line to current text without clearing
@write_wait <sec>   # Auto-advance after <sec> seconds without waiting for player click

# Presentation state tags
@s <speaker>        # Speaker name (e.g. @s Emily or @s none)
@e <emotion>        # Emotion name (e.g. @e happy or @e none)
@p <portrait>       # Portrait asset key (e.g. @p Emily_smile or @p none)
@b <background>     # Background asset key (e.g. @b station_day or @b none)
@m <music>          # Music track key (e.g. @m station_theme or @m none)
@r                  # Reset all presentation states to defaults
@r s m              # Selective reset (resets only speaker and music, without '@')

# Arbitrary metadata
@d <key> <data>     # Custom metadata (e.g. @d sfx train, @d speed 0.8, @d voice emily_03)
```

### Mid-Sentence State Changes with "@dirty" & "@write_wait"

Instead of polluting text with complex inline bracket tags, DiaJogger uses clean line tags:

```md
@s Emily @e surprised @d sfx train
Слышишь этот гудок?..
@dirty @write_wait 0.8 @d speed 0.8
Поезд уже совсем близко!
```
1. `Слышишь этот гудок?..` prints with normal typewriter speed while triggering the train horn.
2. `@dirty` ensures the dialogue box is not wiped.
3. `@write_wait 0.8` waits 0.8 seconds automatically (no click required).
4. `Поезд уже совсем близко!` continues printing in the same bubble at 0.8x speed!

### Resetting Values & "@r"

* **`none` value**: Passing `none` after any tag resets that tag to its default empty value:
  ```md
  @s none           # clears speaker
  @e none           # clears emotion
  @m none           # stops/clears music track
  @b none           # clears background
  ```
* **`@r` reset tag**:
  * On its own, `@r` resets **all** presentation states to defaults.
  * Followed by tag names (without `@`), `@r` resets **only** those specific tags:
  ```md
  @r s              # resets speaker only (narration / thoughts)
  @r s m            # resets speaker and music, keeps background and emotions
  @r s e            # resets speaker and emotion
  @r                # full reset of all presentation states
  ```

### Multiple tags on one line

Tags can be combined on a single line:

```md
@s Emily @e angry @p Emily_angry @d speed 1.2
Ты опять не спал всю ночь?
```

### Example Dialogue File (`station.md`)

```md
@target Station/Act 1

@b station_day
@m station_theme

@s Emily @e happy
Доброе утро, Рен!
Мы уже заждались тебя на платформе.

@s Deva @e worried
Ты опять всю ночь не спал?
Выглядишь так, будто поезд переехал твои планы на отдых.

@s Ren
Нормально. Я просто думал.

@target Station/AskTrain

@s Deva @e happy
Наш поезд отправляется через двадцать минут с третьего пути.
Билеты у меня, так что не переживай.

@s Emily @e surprised @d sfx train
Слышишь этот гудок?..
@dirty @write_wait 0.8 @d speed 0.8
Поезд уже совсем близко!

@s Emily @e worried
Но расписание сегодня странное...
@dirty
некоторые рейсы просто отменили.

@target Station/Leave

@s Emily @e happy
Тогда идём на посадку!

@s Deva @e surprised
Я очень...
@dirty
не хочу опоздать!
@dirty @write_wait 0.5 @e happy
Бежим скорее к платформе!

@r s
Мы взяли чемоданы и направились к выходу на платформу.

@r
```

---

## GDScript Usage

### 1. Playing a target

```gdscript
# Load document file
DiaJogger.load_file("res://addons/diajogger/examples/station.md")

# Play target until the next target or EOF
await DiaJogger.play("Station/Act 1")
```

### 2. Handling Choices & Branching

```gdscript
var choice := await DiaJogger.choice([
  "Рассказать правду",
  "Солгать"
])

match choice:
  0:
    await DiaJogger.play("Station/Letter")
  1:
    await DiaJogger.play("Station/Lie")
```

#### Timed Choices in Godot ("Control Flow is Code")

DiaJogger's core remains minimal (`choice(options)`). If you need countdown timers or default selections on timeout, implement it in Godot in 4 lines using `DiaJogger.select_choice()`:

```gdscript
# Game script helper:
func timed_choice(options: Array[String], timeout: float, default_idx: int = 0) -> int:
  var timer := get_tree().create_timer(timeout)
  timer.timeout.connect(func(): if DiaJogger.is_waiting_choice(): DiaJogger.select_choice(default_idx))
  return await DiaJogger.choice(options)
```

### 3. Custom View

Create a node inheriting from `DiaJoggerView` and register it:

```gdscript
DiaJogger.set_view($MyCustomDialogueUI)
```

### 4. Dialogue Loops in GDScript (No @jump in Markdown!)

Because DiaJogger leaves control flow to GDScript, investigation / topic loops are standard `while` loops:

```gdscript
var exploring := true
while exploring:
  var topic := await DiaJogger.choice([
    "Спросить про поезд",
    "Спросить про письмо",
    "Закончить разговор"
  ])
  match topic:
    0: await DiaJogger.play("Station/AskTrain")
    1: await DiaJogger.play("Station/AskLetter")
    2: exploring = false

await DiaJogger.play("Station/Leave")
```

### 5. Saving, Loading & Resuming Mid-Dialogue

DiaJogger provides built-in state serialization with exact caret position preservation:

```gdscript
# Save (even mid-dialogue!):
var saved_state: Dictionary = DiaJogger.serialize_state()

# Load & Resume:
DiaJogger.restore_state(saved_state)
# Resume execution from the exact line without restarting the section:
await DiaJogger.resume()
```
