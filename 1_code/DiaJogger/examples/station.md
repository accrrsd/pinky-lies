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

@s Emily @e surprised
Кстати, пока мы тебя ждали, тут кое-что произошло!

@s Deva @e thinking
Да, именно. Спроси нас, если хочешь узнать подробности.

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

@target Station/AskLetter

@s Emily @e surprised
Я нашла кое-что в зале ожидания!

@p Emily_letter
Это старый запечатанный конверт...
@dirty
На нём написано твоё имя.

@s Deva @e worried
И печать на нём очень странная...
@dirty @write_wait 0.6 @e surprised
Будто из другого города!

@target Station/AskDeva

@s Deva @e happy
Я? Я просто рада, что мы наконец-то выбираемся из города.

Хотя то письмо меня немного настораживает.

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
