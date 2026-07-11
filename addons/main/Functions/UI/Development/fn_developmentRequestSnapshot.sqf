if (!hasInterface || {isNull player}) exitWith { false };

[player] remoteExecCall ["FLO_fnc_developmentRequestSnapshotServer", 2];
true
