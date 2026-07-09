/*
 * Function: FLO_fnc_refreshRespawnMarkersByTerritory
 * Author: Frontline Operations Development Group
 * Description:
 *   Ensures FOB/OP respawn markers are only available in friendly territory.
 *   Markers in enemy-owned objectives are removed from selection.
 *   Also keeps marker side prefix aligned with FLO_ActivePlayerSide.
 *
 * Arguments: None
 *
 * Returns:
 *   BOOL - True when refresh completed
 */

if (!isServer) exitWith { false };
if (isNil "FLO_Objectives") exitWith { false };
if !(FLO_ActivePlayerSide in [east, west]) exitWith { false };

private _activeSide = FLO_ActivePlayerSide;
private _enemySide = [east, west] select (_activeSide isEqualTo east);
private _sideKey = ["west", "east"] select (_activeSide isEqualTo east);

private _fnc_normalizeOwner = {
    params ["_owner"];
    if (_owner isEqualType "") then {
        private _ownerKey = toUpper _owner;
        if (_ownerKey isEqualTo "EAST") then { _owner = east; };
        if (_ownerKey isEqualTo "WEST") then { _owner = west; };
    };
    _owner
};

private _fnc_ownerAtPos = {
    params ["_pos", "_fnc_normalizeOwner"];
    private _owner = sideUnknown;

    {
        private _objData = FLO_Objectives get _x;
        if ([_pos, _objData] call FLO_fnc_isPositionInObjective) exitWith {
            _owner = _objData get "owner";
        };
    } forEach (keys FLO_Objectives);

    [_owner] call _fnc_normalizeOwner
};

private _structures = [];

if (!isNil "FLO_FactionFobType") then {
    {
        _structures pushBack [_x, "fobMarkerName", "FOB", [1.5, 1.5], "b_installation", "FLO_FOB_Initialized"];
    } forEach (allMissionObjects FLO_FactionFobType);
};

if (!isNil "FLO_FactionCopType") then {
    {
        _structures pushBack [_x, "opMarkerName", "OP", [1.5, 1.5], "b_installation", "FLO_OP_Initialized"];
    } forEach (allMissionObjects FLO_FactionCopType);
};

{
    _x params ["_building", "_markerVar", "_markerText", "_markerSize", "_markerType", "_initVar"];
    if (!alive _building) then { continue };
    if !(_building getVariable [_initVar, false]) then { continue };

    private _markerPos = _building getRelPos [12, 0];
    private _markerName = _building getVariable [_markerVar, ""];
    private _targetName = format ["respawn_%1_%2", _sideKey, str (getPosATL _building)];

    if (_markerName != _targetName) then {
        if (_markerName != "" && {_markerName in allMapMarkers}) then {
            deleteMarker _markerName;
        };
        _markerName = _targetName;
        _building setVariable [_markerVar, _markerName, true];
    };

    private _owner = [getPosATL _building, _fnc_normalizeOwner] call _fnc_ownerAtPos;
    if (_owner isEqualTo _enemySide) then {
        if (_markerName in allMapMarkers) then {
            deleteMarker _markerName;
        };
    } else {
        if !(_markerName in allMapMarkers) then {
            createMarker [_markerName, _markerPos];
        };

        _markerName setMarkerPosLocal _markerPos;
        _markerName setMarkerTypeLocal _markerType;
        _markerName setMarkerColorLocal "ColorYellow";
        _markerName setMarkerTextLocal _markerText;
        _markerName setMarkerSizeLocal _markerSize;
        _markerName setMarkerAlpha 1;
    };
} forEach _structures;

true
