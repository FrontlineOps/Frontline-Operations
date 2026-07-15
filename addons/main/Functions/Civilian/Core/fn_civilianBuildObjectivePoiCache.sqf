/*
 * Function: FLO_fnc_civilianBuildObjectivePoiCache
 * Author: Frontline Operations Development Group
 * Description:
 *   Builds one cached civilian point-of-interest set for an objective.
 *   These POIs are reused by the civilian manager so routine updates do not
 *   repeatedly rescan the same roads and buildings.
 *
 * Arguments:
 * 0: Objective ID <STRING>
 *
 * Return Value:
 * HASHMAP - Objective POI cache
 */

params [["_objectiveId", "", [""]]];

private _cache = createHashMapFromArray [
    ["objectiveId", _objectiveId],
    ["objectivePos", [0, 0, 0]],
    ["home", []],
    ["market", []],
    ["work", []],
    ["observe", []],
    ["shelter", []],
    ["parking", []]
];

if (_objectiveId == "" || {!(_objectiveId in FLO_Objectives)}) exitWith { _cache };

private _objective = FLO_Objectives get _objectiveId;
private _cfg = FLO_CivilianConfig;
private _objectivePos = +(_objective get "position");
_objectivePos set [2, 0];

private _objectiveRadius = (_objective get "radius") max 90;
private _roadLimit = _cfg get "POI_MAX_ROADS";
private _buildingPosLimit = _cfg get "POI_MAX_BUILDING_POSITIONS";
private _fallbackLandPos = +_objectivePos;
if (surfaceIsWater _fallbackLandPos) then {
    _fallbackLandPos = [_fallbackLandPos, _objectiveRadius] call FLO_fnc_getSafeLandPos;
};
if (count _fallbackLandPos >= 2) then {
    if (count _fallbackLandPos > 2) then {
        _fallbackLandPos set [2, 0];
    } else {
        _fallbackLandPos pushBack 0;
    };
};
if (count _fallbackLandPos < 2 || {surfaceIsWater _fallbackLandPos}) then {
    _fallbackLandPos = [];
};

private _roadPositions = [];
private _intersectionPositions = [];
private _marketPositions = [];

{
    private _roadPos = getPos _x;
    _roadPos set [2, 0];

    if ((_roadPos distance2D _objectivePos) > _objectiveRadius) then { continue };
    if (surfaceIsWater _roadPos) then { continue };

    _roadPositions pushBackUnique _roadPos;

    private _connections = roadsConnectedTo _x;
    if ((count _connections) >= 3) then {
        _intersectionPositions pushBackUnique _roadPos;
    };

    if ((_roadPos distance2D _objectivePos) <= ((_objectiveRadius * 0.4) max 50)) then {
        _marketPositions pushBackUnique _roadPos;
    };

    if ((count _roadPositions) >= _roadLimit) exitWith {};
} forEach (_objectivePos nearRoads _objectiveRadius);

private _buildingClasses = if (!isNil "CivBuildingClasses") then { CivBuildingClasses } else { ["House"] };
private _buildings = [];
{
    _buildings append (nearestObjects [_objectivePos, [_x], _objectiveRadius]);
} forEach _buildingClasses;

private _buildingPositions = [];
{
    private _building = _x;
    private _index = 0;

    while {(count _buildingPositions) < _buildingPosLimit} do {
        private _buildingPos = _building buildingPos _index;
        if (_buildingPos isEqualTo [0, 0, 0]) exitWith {};

        if !(surfaceIsWater _buildingPos) then {
            _buildingPositions pushBack _buildingPos;
        };
        _index = _index + 1;
    };

    if ((count _buildingPositions) >= _buildingPosLimit) exitWith {};
} forEach _buildings;

if (_buildingPositions isEqualTo [] && {_fallbackLandPos isNotEqualTo []}) then {
    _buildingPositions pushBack _fallbackLandPos;
};
if (_roadPositions isEqualTo [] && {_fallbackLandPos isNotEqualTo []}) then {
    _roadPositions pushBack _fallbackLandPos;
};
if (_intersectionPositions isEqualTo []) then {
    _intersectionPositions = +_roadPositions;
};
if (_marketPositions isEqualTo []) then {
    _marketPositions = +_intersectionPositions;
};

private _homePositions = +((_buildingPositions call BIS_fnc_arrayShuffle) select [0, ((count _buildingPositions) min 16)]);
private _shelterPositions = +((_buildingPositions call BIS_fnc_arrayShuffle) select [0, ((count _buildingPositions) min 12)]);
private _workPositions = _roadPositions select {
    (_x distance2D _objectivePos) >= ((_objectiveRadius * 0.25) max 35)
};

if (_workPositions isEqualTo []) then {
    _workPositions = +_roadPositions;
};

_cache set ["objectivePos", _objectivePos];
_cache set ["home", _homePositions];
_cache set ["market", _marketPositions];
_cache set ["work", _workPositions];
_cache set ["observe", _intersectionPositions];
_cache set ["shelter", _shelterPositions];
_cache set ["parking", _roadPositions];

_cache
