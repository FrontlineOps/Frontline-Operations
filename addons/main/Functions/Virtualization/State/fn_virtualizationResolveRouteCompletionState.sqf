/* Resolves the canonical runtime state after the final route waypoint. */
params [["_groupData", createHashMap, [createHashMap]]];

if ((_groupData get "replacementState") != "") exitWith { "moving" };
if ((_groupData get "commanderOrder") in ["ATTACK", "DEFEND"]) exitWith { "holding" };
if (([_groupData] call FLO_fnc_virtualizationGetAADeployState) == "DEPLOYED") exitWith { "holding" };

"idle"
