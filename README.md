# MoreTooltipInfo

## Overview
MoreTooltipInfo allows you to add useful informations about items, spells, etc. in the tooltip. 

Don't hesitate to go on the [SimcMinMax] Discord to ask about specific stuff.


## Where does the data comes from?
All data come from Blizzard API and client Data.

The simulationcraft team built powerful tools to extract all kind of data and all of it is automatically extracted and added into the addon.

If there is hotfixes in game, you will just have to update the addon to get the latest data.

## Personnal Data
For item DPS, there is base data coming from simulations from [bloodmallet.com](https://bloodmallet.com/) or [herodamage.com](https://www.herodamage.com/).

You can also import your own profile to better match your char. Open profile manager with `/mti`.

Format for item dps data is as follow :
```
MoreTooltipInfo:class_id:spec_id:"profileName":trinket^[item_id1]ilvl1=dps1;ilvl2=dps2;ilvl3=dps3^[item_id2]ilvl4=dps4;ilvl5=dps5;ilvl6=dps6
```

for example :
```
MoreTooltipInfo:8:64:"X.com-patchwerk":trinket^[174103]115=111;125=1234;130=1250;150=9999^[174500]115=111;125=123;130=456;135=789
```

Format for talent dps data is as follow (base_dps is for talent alone, best_dps is with the best talent combination):
```
MoreTooltipInfo:class_id:spec_id:"profileName":talent^[spellID]Base=base_dps;Best=best_dps^[spellID2]Base=base_dps2;Best=best_dps2
```

for example :
```
MoreTooltipInfo:8:64:"X.com-patchwerk":talent^[56377]Base=1234;Best=9999^[153595]Base=5678;Best=8888
```


## Currently available data
- Spell:
  - ID
  - RPPM
  - GCD
- Item:
  - ID
  - Spell ID
  - RPPM
  - bonusID
  - gemID
  - enchantID
  - enchant spellID
  - enchant RPPM
  - Simulated DPS
- Talent:
  - Talent ID
  - Simulated DPS
- Soulbinds:
  - Spell ID
- Conduits:
  - Conduit ID
  - Spell ID
  - Rank

## UI
You can enable and disable what you want to show in the tooltip in Game Menu > Interface > MoreTooltipInfo
 
## Known issues and development plan
- Add more data to the addon (Do not hesitate to suggest)

- Add notifications when data changes

- Cleanup and make all that data available through a Lib


## Credits
Kutikuti