## NotebookDemoScene
##
## Purpose:
##   Playable demo scene demonstrating the NotebookDialogueView:
##   - Spiral binding rings and paper line alignment.
##   - Click-anywhere advancement with lowest priority.
##   - Checklist-style choices directly on the lined page.

extends Control
class_name NotebookDemoScene

@onready var notebook_view: NotebookDialogueView = $NotebookDialogueView

func _ready() -> void:
  DiaJogger.set_view(notebook_view)
  DiaJogger.load_file("res://1_code/DiaJogger/examples/notebook/notes.md")
  _run_demo()

func _run_demo() -> void:
  await DiaJogger.play("Diary/Entry1")
  await DiaJogger.play("Diary/Deduction")
  
  var choice := await DiaJogger.choice([
    "Письмо подбросили специально, чтобы задержать нас",
    "Это предупреждение от старых знакомых отца",
    "Не обращать внимания и скорее садиться в поезд"
  ])
  
  match choice:
    0:
      DiaJogger.load_string("@target Res\n@s Рен\nЕсли это ловушка — нужно быть начеку с первой же станции.")
      await DiaJogger.play("Res")
    1:
      DiaJogger.load_string("@target Res\n@s Рен\nВозможно, в столице меня кто-то ждёт. Стоит перепроверить адрес.")
      await DiaJogger.play("Res")
    2:
      DiaJogger.load_string("@target Res\n@s Рен\nЗакрываю блокнот. Поезд уже подаёт гудок, пора бежать на перрон.")
      await DiaJogger.play("Res")
