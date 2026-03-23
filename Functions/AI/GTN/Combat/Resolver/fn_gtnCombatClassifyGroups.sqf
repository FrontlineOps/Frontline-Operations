/*
 * Function: FLO_fnc_gtnCombatClassifyGroups
 * Author: Frontline Operations Development Group
 * Description:
 *   Classifies virtual groups for combat resolution in a single pass. Builds
 *   the direct-combat pool, dynamic seed IDs from the lighter side, and
 *   abstract support availability.
 *
 * Arguments:
 *   0: Virtual groups map <HASHMAP>
 *   1: Seed cell size <NUMBER>
 *   2: Engagement distance <NUMBER>
 *
 * Return Value:
 *   Classification data <HASHMAP>
 */

params ["_groups", ["_seedCellSize", 150, [0]], ["_engagementDist", 300, [0]]];

private _combatGroups = createHashMap;
private _eastSeeds = [];
private _westSeeds = [];
private _eastSeedCells = createHashMap;
private _westSeedCells = createHashMap;
private _eastThreatCells = createHashMap;
private _westThreatCells = createHashMap;
private _directCombatTypes = [
    "infantry",
    "motorized",
    "mechanized",
    "armor",
    "mobile_aa"
];
private _supportAvailability = createHashMapFromArray [
    ["EAST_ARTY", false],
    ["EAST_AIR", false],
    ["WEST_ARTY", false],
    ["WEST_AIR", false]
];
private _threatCellRadius = ceil (_engagementDist / _seedCellSize);
private _cellKeyBase = ceil (worldSize / _seedCellSize) + _threatCellRadius + 8;
private _cellKeyStride = (_cellKeyBase * 2) + 1;

{
    private _groupId = _x;
    private _gData = _y;
    private _side = _gData get "side";
    private _groupType = _gData get "groupType";
    if !(_side in [east, west]) then { continue };
    if (([_gData] call FLO_fnc_virtualizationGetTransportAttachment) != "") then { continue };

    if ((_gData get "missionLock") == "") then {
        private _sideKey = if (_side isEqualTo east) then { "EAST" } else { "WEST" };

        if (_groupType isEqualTo "artillery") then {
            _supportAvailability set [_sideKey + "_ARTY", true];
        };

        if (_groupType in ["air", "helicopter", "jet"]) then {
            _supportAvailability set [_sideKey + "_AIR", true];
        };
    };

    if !(_groupType in _directCombatTypes) then { continue };
    if ((_gData get "unitCount") <= 0) then { continue };

    _combatGroups set [_groupId, _gData];
    private _pos = _gData get "position";
    private _seedCellX = floor ((_pos select 0) / _seedCellSize);
    private _seedCellY = floor ((_pos select 1) / _seedCellSize);
    private _seedCellKey = ((_seedCellX + _cellKeyBase) * _cellKeyStride) + (_seedCellY + _cellKeyBase);

    if (_side isEqualTo east) then {
        if !(_eastSeedCells getOrDefault [_seedCellKey, false]) then {
            _eastSeedCells set [_seedCellKey, true];
            _eastSeeds pushBack _groupId;

            for "_xCell" from (_seedCellX - _threatCellRadius) to (_seedCellX + _threatCellRadius) do {
                for "_yCell" from (_seedCellY - _threatCellRadius) to (_seedCellY + _threatCellRadius) do {
                    _eastThreatCells set [((_xCell + _cellKeyBase) * _cellKeyStride) + (_yCell + _cellKeyBase), true];
                };
            };
        };
    } else {
        if !(_westSeedCells getOrDefault [_seedCellKey, false]) then {
            _westSeedCells set [_seedCellKey, true];
            _westSeeds pushBack _groupId;

            for "_xCell" from (_seedCellX - _threatCellRadius) to (_seedCellX + _threatCellRadius) do {
                for "_yCell" from (_seedCellY - _threatCellRadius) to (_seedCellY + _threatCellRadius) do {
                    _westThreatCells set [((_xCell + _cellKeyBase) * _cellKeyStride) + (_yCell + _cellKeyBase), true];
                };
            };
        };
    };
} forEach _groups;

private _seedSide = east;
private _opponentSide = west;
private _seedIds = _eastSeeds;
if ((count _westSeeds) < (count _eastSeeds)) then {
    _seedSide = west;
    _opponentSide = east;
    _seedIds = _westSeeds;
};

createHashMapFromArray [
    ["combatGroups", _combatGroups],
    ["seedIds", _seedIds],
    ["seedSide", _seedSide],
    ["opponentSide", _opponentSide],
    ["seedCellSize", _seedCellSize],
    ["engagementDist", _engagementDist],
    ["eastThreatCells", _eastThreatCells],
    ["westThreatCells", _westThreatCells],
    ["threatCellRadius", _threatCellRadius],
    ["eastSeedCount", count _eastSeeds],
    ["westSeedCount", count _westSeeds],
    ["supportAvailability", _supportAvailability]
]
