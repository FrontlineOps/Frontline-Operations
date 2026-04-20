OLDGRP = group player;

player setDamage 0;
[true] remoteExec ["showHud", player];
player stop false;
player enableAI "all";
[player, false] remoteExec ["setCaptive", 0, false];
["GetOutMan"] remoteExec ["removeAllEventHandlers", player, false];

// Apply custom faction loadout based on player role
[] spawn {
    sleep 0.5; // Wait for mission variables to sync
    
    private _loadoutClass = "";
    if (!isNil "TheCommander" && {player isEqualTo TheCommander}) then {
        _loadoutClass = missionNamespace getVariable ["F_Officer", ""];
    } else {
        _loadoutClass = missionNamespace getVariable ["F_Assault_TL", ""];
    };

    if (_loadoutClass != "" && {isClass (configFile >> "CfgVehicles" >> _loadoutClass)}) then {
        player setUnitLoadout _loadoutClass;
        diag_log format ["[RESPAWN] Applied loadout %1 to player %2", _loadoutClass, name player];
    } else {
        diag_log "[RESPAWN] WARNING: No valid loadout class found for player";
    };
};

(_this select 1) setPos [0,0,0];
deleteVehicle (_this select 1);

sleep 1;

ShowHUD [true, true, true, true, true, true, true, true, true, true];