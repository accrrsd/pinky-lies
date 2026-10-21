@target Station/Act 1

@b station_day
@m station_theme

@s Emily @e happy
Good morning, Ren!

We've been waiting for you on the platform.

@s Deva @e worried
Didn't sleep all night again?

You look like the train just ran over your vacation plans.

@s Ren
I'm fine. I was just thinking.

@s Emily @e surprised
By the way, while we were waiting, something happened!

@s Deva @e thinking
Yes, exactly. Ask us if you'd like to hear the details.

@target Station/AskTrain

@s Deva @e happy
Our train leaves in twenty minutes from track three.

I have the tickets, so don't worry.

@s Emily @e surprised @d sfx train
Do you hear that whistle?..
@dirty @write_wait 0.8 @d speed 0.8
The train is already approaching!

@s Emily @e worried
Still, the timetable seems strange today...
@dirty
some routes were just cancelled.

@target Station/AskLetter

@s Emily @e surprised
I found something in the waiting lounge!

@p Emily_letter
It's an old sealed envelope...
@dirty
Your name is written on it.

@s Deva @e worried
And the wax seal looks very peculiar...
@dirty @write_wait 0.6 @e surprised
As if it came from another city!

@target Station/AskDeva

@s Deva @e happy
Me? I'm just happy we're finally getting out of town.

Although that letter does make me a bit uneasy.

@target Station/Leave

@s Emily @e happy
Let's head to boarding then!

@s Deva @e surprised
I really...
@dirty
don't want to miss it!
@dirty @write_wait 0.5 @e happy
Let's hurry to the platform!

@r s
We grabbed our luggage and headed toward the platform exit.

@r
