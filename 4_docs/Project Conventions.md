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
- 3 scenes/misc: Для уникальных сцен. Если элементов > 3, вынести в отдельную папку.
- 5 trash: Синхронизируется с Git. Обязательна очистка перед релизом.
- 1 code/resources: Только скрипты-классы (definitions).
- 2 general/resources: Только экземпляры (.tres).