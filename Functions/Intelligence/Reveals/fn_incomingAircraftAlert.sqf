/*
 * Function: FLO_fnc_incomingAircraftAlert
 * Author: Frontline Operations Development Group
 * Description:
 *   Alerts players to incoming enemy aircraft.
 *   Called by GTN Commander when air assets are tasked to attack.
 *
 * Parameters:
 *   0: Target position the aircraft is heading toward (ARRAY)
 *   1: Aircraft type hint (STRING) - "attack_heli", "transport_heli", "jet"
 *   2: Estimated time to arrival in seconds (NUMBER) - Optional
 *
 * Returns: Nothing
 */

params ["_targetPos", ["_aircraftType", "unknown"], ["_eta", -1]];

private _typeText = switch (toLower _aircraftType) do {
    case "attack_heli": { "ATTACK HELICOPTER" };
    case "transport_heli": { "TRANSPORT HELICOPTER" };
    case "jet": { "FIXED WING AIRCRAFT" };
    case "cas": { "CLOSE AIR SUPPORT" };
    default { "AIRCRAFT" };
};

private _grid = mapGridPosition _targetPos;
private _etaText = if (_eta > 0) then { format [" - ETA %1 seconds", _eta] } else { "" };

["STR_FLO_INTEL_TITLE", format ["INCOMING %1 heading toward grid %2%3", _typeText, _grid, _etaText], "warning"] call FLO_fnc_sendNotification;

// Create brief warning marker
private _mrkId = format ["airWarning_%1", floor random 99999];
private _mrk = createMarkerLocal [_mrkId, _targetPos];
_mrk setMarkerTypeLocal "mil_warning";
_mrk setMarkerColorLocal "colorOPFOR";
_mrk setMarkerText format ["AIR (%1)", _typeText];
_mrk setMarkerAlpha 0.8;

// Delete marker after 30 seconds
[_mrkId] spawn {
    params ["_m"];
    sleep 20;
    for "_i" from 1 to 5 do {
        _m setMarkerAlpha (0.8 - (_i * 0.15));
        sleep 2;
    };
    deleteMarker _m;
};

["INTEL", 3, format["Aircraft alert: %1 heading to %2", _typeText, _grid]] call FLO_fnc_log;
