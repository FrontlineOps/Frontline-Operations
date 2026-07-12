if (!hasInterface || {isNull player}) exitWith { false };

[player] remoteExecCall ["FLO_fnc_supportRequestSnapshotServer", 2];
true
