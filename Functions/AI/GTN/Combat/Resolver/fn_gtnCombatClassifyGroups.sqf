/*
 * Function: FLO_fnc_gtnCombatClassifyGroups
 * Author: Frontline Operations Development Group
 * Description:
 *   Classifies virtual groups for combat resolution in a single pass. Builds
 *   the direct-combat pool, EAST seed IDs, and abstract support availability.
 *
 * Arguments:
 *   0: Virtual groups map <HASHMAP>
 *
 * Return Value:
 *   Classification data <HASHMAP>
 */

params ["_groups"];

private _combatGroups = createHashMap;
private _eastSeeds = [];
private _supportAvailability = createHashMapFromArray [
    ["EAST_ARTY", false],
    ["EAST_AIR", false],
    ["WEST_ARTY", false],
    ["WEST_AIR", false]
];

{
    private _groupId = _x;
    private _gData = _y;
    private _side = _gData get "side";
    if !(_side in [east, west]) then { continue };
    if ((_gData get "attachedTo") != "") then { continue };

    if !(_gData get "onMission") then {
        private _sideKey = ([_side] call FLO_fnc_gtnSideContext) get "sideKey";
        private _groupType = _gData get "groupType";

        if (_groupType isEqualTo "artillery") then {
            _supportAvailability set [_sideKey + "_ARTY", true];
        };

        if (_groupType in ["air", "helicopter", "jet"]) then {
            _supportAvailability set [_sideKey + "_AIR", true];
        };
    };

    if !([_gData get "groupType"] call FLO_fnc_gtnCombatIsDirectCombatGroup) then { continue };
    if ((_gData get "unitCount") <= 0) then { continue };

    _combatGroups set [_groupId, _gData];
    if (_side isEqualTo east) then {
        _eastSeeds pushBack _groupId;
    };
} forEach _groups;

createHashMapFromArray [
    ["combatGroups", _combatGroups],
    ["eastSeeds", _eastSeeds],
    ["supportAvailability", _supportAvailability]
]
