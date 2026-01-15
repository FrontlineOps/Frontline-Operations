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

private _commander = FLO_GTN_ResourceManager get "_gtnCommander";
if (isNil "_commander") exitWith { 
    ["Enemy command analysis unavailable", "warning"] call FLO_fnc_sendNotification;
    false 
};

// Get active tracks and their targets
private _tracks = _commander get "_tracks";
if (isNil "_tracks" || {count _tracks == 0}) exitWith {
    ["No active enemy operations detected", "info"] call FLO_fnc_sendNotification;
    false
};

private _attackTracks = _tracks select { (_x get "goal") == "attack" };

if (count _attackTracks == 0) exitWith { 
    ["No enemy offensive operations detected", "info"] call FLO_fnc_sendNotification;
    false 
};

private _track = selectRandom _attackTracks;
private _target = _track get "target";

if (isNil "_target") exitWith {
    ["Enemy objectives unclear", "info"] call FLO_fnc_sendNotification;
    false
};

// Get objective position
private _targetPos = if (typeName _target == "STRING" && {!isNil "FLO_Objectives"}) then {
    private _objData = FLO_Objectives getOrDefault [_target, nil];
    if (!isNil "_objData") then { _objData get "position" } else { nil }
} else {
    _target
};

if (isNil "_targetPos") exitWith {
    ["Enemy objectives unclear", "info"] call FLO_fnc_sendNotification;
    false
};

// Create marker
private _mrkId = format ["cmdFocus_%1", floor random 99999];
private _mrk = createMarkerLocal [_mrkId, _targetPos];
_mrk setMarkerTypeLocal "mil_objective";
_mrk setMarkerColorLocal "colorOPFOR";
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
