/*
 * Function: FLO_fnc_seedObjectiveOwnership
 * Author: Frontline Operations Development Group
 * Description:
 *   Seeds initial EAST/WEST objective ownership using map X-axis split.
 *
 * Arguments:
 *   0: Center buffer width (meters) <NUMBER> - Optional
 *
 * Returns:
 *   BOOL - true when ownership was seeded
 */

if (!isServer) exitWith { false };
if (isNil "FLO_Objectives" || {count FLO_Objectives == 0}) exitWith { false };

params [["_centerBuffer", -1, [0]]];

private _midX = worldSize / 2;
if (_centerBuffer < 0) then {
    _centerBuffer = worldSize * 0.05;
};

private _westOwned = [];
private _eastOwned = [];
private _centerObjectives = [];

{
    private _objId = _x;
    private _objData = FLO_Objectives get _objId;

    private _pos = _objData get "position";
    private _xPos = _pos select 0;

    if (_xPos < (_midX - _centerBuffer)) then {
        _objData set ["owner", west];
        _westOwned pushBack _objId;
    } else {
        if (_xPos > (_midX + _centerBuffer)) then {
            _objData set ["owner", east];
            _eastOwned pushBack _objId;
        } else {
            _centerObjectives pushBack _objId;
        };
    };

    FLO_Objectives set [_objId, _objData];
} forEach (keys FLO_Objectives);

// Assign center buffer objectives to whichever side is currently weaker.
{
    private _objData = FLO_Objectives get _x;
    private _toWest = (count _westOwned) <= (count _eastOwned);
    private _owner = if (_toWest) then { west } else { east };
    _objData set ["owner", _owner];
    FLO_Objectives set [_x, _objData];
    if (_toWest) then {
        _westOwned pushBack _x;
    } else {
        _eastOwned pushBack _x;
    };
} forEach _centerObjectives;

// Ensure both sides own at least one objective.
if ((count _westOwned) == 0 || {(count _eastOwned) == 0}) then {
    private _all = keys FLO_Objectives;
    if (count _all > 1) then {
        private _sorted = [_all, [], {
            ((FLO_Objectives get _x) get "position") select 0
        }, "ASCEND"] call BIS_fnc_sortBy;

        private _westObj = _sorted select 0;
        private _eastObj = _sorted select ((count _sorted) - 1);

        private _westObjData = FLO_Objectives get _westObj;
        _westObjData set ["owner", west];
        FLO_Objectives set [_westObj, _westObjData];

        private _eastData = FLO_Objectives get _eastObj;
        _eastData set ["owner", east];
        FLO_Objectives set [_eastObj, _eastData];
    };
};

// Refresh markers for seeded ownership.
{
    [_x, FLO_Objectives get _x] call FLO_fnc_createObjectiveMarker;
} forEach (keys FLO_Objectives);

publicVariable "FLO_Objectives";

["OBJECTIVE", 2, format["Seeded ownership: WEST=%1 EAST=%2 (buffer=%3m)",
    ({((FLO_Objectives get _x) get "owner") isEqualTo west} count (keys FLO_Objectives)),
    ({((FLO_Objectives get _x) get "owner") isEqualTo east} count (keys FLO_Objectives)),
    round _centerBuffer
]] call FLO_fnc_log;

true
