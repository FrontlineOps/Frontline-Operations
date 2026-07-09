/*
 * Function: FLO_fnc_civilianBuildIntelSubtitle
 * Author: Frontline Operations Development Group
 * Description:
 *   Builds a short subtitle line for a civilian intel package so spoken
 *   feedback matches the reported intel type instead of using generic flavor.
 *
 * Arguments:
 * 0: Intel package <HASHMAP>
 *
 * Return Value:
 * STRING - Subtitle text
 */

params [["_package", createHashMap, [createHashMap]]];

if ((keys _package) isEqualTo []) exitWith { "That is all I know." };

private _payload = _package get "payload";
private _reportType = if (_payload isEqualType [] && {_payload isNotEqualTo []}) then {
    _payload select 0
} else {
    ""
};

switch (_reportType) do {
    case "VEHICLE_MOVEMENT": {
        selectRandom [
            "Military vehicles were moving through there.",
            "I saw army vehicles on that route.",
            "Watch that road. Vehicles passed through there."
        ]
    };
    case "CHECKPOINT_RUMOR": {
        selectRandom [
            "There is a checkpoint or roadblock that way.",
            "Armed men were stopping movement over there.",
            "That route is being watched."
        ]
    };
    case "PATROL_SIGHTING": {
        selectRandom [
            "An armed patrol was seen over there.",
            "Soldiers passed through that area recently.",
            "There were patrols moving near that spot."
        ]
    };
    case "SAFE_ROUTE_HINT": {
        selectRandom [
            "That way seemed quieter when I last heard.",
            "That route should be safer for now.",
            "If you move, go that way instead."
        ]
    };
    case "HOSTILE_REPORT": {
        selectRandom [
            "There was trouble over there recently.",
            "Something hostile happened in that area.",
            "Be careful. That direction is dangerous."
        ]
    };
    default {
        "Check your map. That is what I heard."
    };
}
