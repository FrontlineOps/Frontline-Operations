if (!hasInterface || {isNull player}) exitWith { false };

[player] remoteExecCall ["FLO_fnc_campaignRequestSnapshot", 2];
true
