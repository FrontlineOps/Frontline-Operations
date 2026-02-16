/*
 * Function: FLO_fnc_revealCommanderObjective
 * Author: Frontline Operations Development Group
 * Description:
 *   Reveals the GTN Commander's current attack focus objective.
 *   Only available at HIGH intel tier.
 *
 * Parameters: None
 *
 * Returns:
 *   BOOLEAN - true if objective revealed, false if unavailable
 */

// Check intel tier
if (!isNil "FLO_Intel_Tier" && {FLO_Intel_Tier != "HIGH"}) exitWith {
    ["Insufficient intelligence level for strategic intel", "info"] call FLO_fnc_sendNotification;
    false
};

if (isNil "FLO_GTN_ResourceManager") exitWith { 
    ["Enemy command analysis unavailable", "warning"] call FLO_fnc_sendNotification;
    false 
};

private _activeSide = FLO_ActivePlayerSide;
if !(_activeSide in [east, west]) then { _activeSide = west };
private _enemySide = if (_activeSide isEqualTo east) then { west } else { east };

private _commander = nil;
if (!isNil {FLO_GTN_ResourceManager get "_getCommanderBySide"}) then {
    _commander = FLO_GTN_ResourceManager call ["_getCommanderBySide", [_enemySide]];
} else {
    _commander = FLO_GTN_ResourceManager get "_gtnCommander";
};

if (isNil "_commander") exitWith { 
    ["Enemy command analysis unavailable", "warning"] call FLO_fnc_sendNotification;
    false 
};

private _targetObjId = _commander call ["_selectPriorityObjective", []];
if (_targetObjId == "") exitWith {
    ["No active enemy operations detected", "info"] call FLO_fnc_sendNotification;
    false
};

// Get objective position
private _targetPos = [_targetObjId] call FLO_fnc_getObjectivePosition;

if (isNil "_targetPos") exitWith {
    ["Enemy objectives unclear", "info"] call FLO_fnc_sendNotification;
    false
};

// Create marker
private _mrkId = format ["cmdFocus_%1", floor random 99999];
private _mrk = createMarkerLocal [_mrkId, _targetPos];
_mrk setMarkerTypeLocal "mil_objective";
_mrk setMarkerColorLocal (if (_enemySide isEqualTo east) then { "colorOPFOR" } else { "colorBLUFOR" });
_mrk setMarkerText "Enemy Focus";
_mrk setMarkerAlpha 1;

// Fade marker over 120 seconds
[_mrkId] spawn { 
    params ["_m"]; 
    sleep 90;
    private _steps = 10;
    for "_i" from 1 to _steps do {
        _m setMarkerAlpha (1 - (_i / _steps));
        sleep 3;
    };
    deleteMarker _m;
};

private _grid = mapGridPosition _targetPos;
[format ["Enemy commander focusing on grid %1", _grid], "success"] call FLO_fnc_sendNotification;
["INTEL", 3, format["Revealed commander objective at %1", _grid]] call FLO_fnc_log;

true
