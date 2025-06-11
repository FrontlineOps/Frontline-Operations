private _respawnMarkerName = "respawn_west" + (str (position player));
private _respawnMarker = createMarker [_respawnMarkerName, (position player)];
_respawnMarker setMarkerType "b_unknown";
_respawnMarker setMarkerSize [0.6, 0.6];
_respawnMarker setMarkerText "Respawn";
_respawnMarker setMarkerAlpha 1;

[] call FLO_fnc_indexObjectives;

// Build road links between objectives
[false] spawn FLO_fnc_buildObjectiveGraph;

[] spawn FLO_fnc_monitorObjectiveDominance;

MarLOCC = 1;
publicVariable "MarLOCC";