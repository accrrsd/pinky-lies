# Project Conventions

## Naming Standards
| Type | Suffix | Scope | Location |
|------|--------|-------|----------|
| Component | `Comp` | ECS | `1 code/ECS/1_components/TestComp.gd` |
| System | `Sys` | ECS | `1 code/ECS/2_systems/TestSys.gd` |
| Entity | `Entity` | ECS | `1 code/ECS/0_entities/TestEntity.gd` |
| Script | `Script` | Niche | `1 code/scripts/` or near scene |
| Dev | `Dev` | Editor/@tool | `1 code/scripts/` or `5 trash/` |

## Folder Rules
- 1_code:
    - core: 
    - resources: Только скрипты-классы (definitions).
    - singletones: 
- 2_general:
    - assets:
    - resources: Только экземпляры (.tres).
- 3_scenes:
    - menus:
    - ui_kit:
    - misc: Для уникальных сцен. Если элементов > 3, вынести в отдельную папку.
- 4_docs: Документация. Планы. Прочие организационные файлы. Концепты.
- 5 trash: Синхронизируется с Git. Обязательна очистка перед релизом.