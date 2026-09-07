## DialogueDemo
##
## Purpose:
##   Demonstrates how to use DiaJogger from gameplay GDScript.
##
## Architecture Principles Illustrated:
##   - Markdown defines dialogue lines and presentation tags.
##   - GDScript controls all narrative flow, conditions, and choices.

extends Node

func _ready() -> void:
  # 1. Load dialogue document
  DiaJogger.load_file("res://1_code/DiaJogger/examples/station.md")
  
  # 2. Play initial act
  await DiaJogger.play("Station/Act 1")
  
  # 3. Choice handled by GDScript
  var choice := await DiaJogger.choice([
    "Рассказать правду",
    "Солгать"
  ])
  
  # 4. Narrative branching in GDScript
  match choice:
    0: await DiaJogger.play("Station/Letter")
    1: print("Ren lied and walked away.")
