/*
 * Function: FLO_fnc_gtnCombatResolveZoneDescriptor
 * Author: Frontline Operations Development Group
 * Description:
 *   Resolves a combat zone identifier and display name using nearby objective
 *   context when available.
 *
 * Arguments:
 *   0: Zone position <ARRAY>
 *   1: EAST group references <ARRAY>
 *   2: WEST group references <ARRAY>
 *
 * Return Value:
 *   Zone descriptor <ARRAY>
 */

params ["_zonePos", "_eastRefs", "_westRefs"];

private _zoneId = format [
    "zone_%1_%2",
    (_eastRefs select 0) select 0,
    (_westRefs select 0) select 0
];
private _zoneName = format ["%1 EAST vs %2 WEST", count _eastRefs, count _westRefs];
private _state = call FLO_fnc_gtnCombatGetState;
private _cache = _state get "objectiveContextCache";
private _cellSize = _state get "objectiveContextCellSize";
private _cacheKey = format [
    "%1_%2",
    floor ((_zonePos select 0) / _cellSize),
    floor ((_zonePos select 1) / _cellSize)
];
private _objectiveContext = _cache getOrDefault [_cacheKey, []];
private _nearestObjectiveId = "";
private _objectiveName = "";

if (_objectiveContext isNotEqualTo []) then {
    _objectiveContext params [["_cachedObjectiveId", ""], ["_cachedObjectiveName", ""]];
    _nearestObjectiveId = _cachedObjectiveId;
    _objectiveName = _cachedObjectiveName;
} else {
    _nearestObjectiveId = [_zonePos] call FLO_fnc_getNearestObjective;
    if (_nearestObjectiveId != "") then {
        private _objectiveData = FLO_Objectives get _nearestObjectiveId;
        _objectiveName = _objectiveData get "name";
        if (_objectiveName == "") then { _objectiveName = _nearestObjectiveId; };
    };
    _cache set [_cacheKey, [_nearestObjectiveId, _objectiveName]];
};

if (_nearestObjectiveId == "") exitWith { [_zoneId, _zoneName] };

[
    format [
        "%1_%2_%3",
        _nearestObjectiveId,
        (_eastRefs select 0) select 0,
        (_westRefs select 0) select 0
    ],
    _objectiveName
]
