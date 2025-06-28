private _respawnMarkerName = "respawn_west" + (str (position player));
private _respawnMarker = createMarker [_respawnMarkerName, (position player)];
_respawnMarker setMarkerType "b_unknown";
_respawnMarker setMarkerSize [0.6, 0.6];
_respawnMarker setMarkerText "Respawn";
_respawnMarker setMarkerAlpha 1;

// Server-side only objective system initialization
[] remoteExec ["FLO_fnc_indexObjectives", 2];

// Build road links between objectives (spawned)
[false] remoteExec ["FLO_fnc_startObjectiveGraph", 2];

// Start objective dominance monitoring (continuous loop)
[] remoteExec ["FLO_fnc_startObjectiveMonitoring", 2];

MarLOCC = 1;
publicVariable "MarLOCC";