OLDGRP = group player;

removeAllActions player;

player setDamage 0;
[true] remoteExec ["showHud", player];
player stop false;
player enableAI "all";
[player, false] remoteExec ["setCaptive", 0, false];
["GetOutMan"] remoteExec ["removeAllEventHandlers", player, false];

// Clear player's inventory
removeAllWeapons player;
removeAllItems player;
//removeAllAssignedItems player;
removeUniform player;
removeVest player;
removeBackpack player;
removeHeadgear player;
removeGoggles player;

(_this select 1) setPos [0,0,0];
deleteVehicle (_this select 1);

sleep 1;

ShowHUD [true, true, true, true, true, true, true, true, true, true];