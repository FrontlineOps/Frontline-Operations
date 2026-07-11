/*
 * Function: FLO_fnc_initActivatePlayer
 * Description:
 *   Authorizes one client-owned player for play after mission initialization.
 */

if (!isServer) exitWith { false };

params [["_playerObject", objNull, [objNull]]];

private _requestOwner = remoteExecutedOwner;
if (!FLO_MissionReady) exitWith {
    ["INIT", 1, format ["Rejected early player activation from owner %1", _requestOwner]] call FLO_fnc_log;
    false
};

if (isNull _playerObject || {!isPlayer _playerObject}) exitWith {
    ["INIT", 1, format ["Rejected invalid player activation from owner %1", _requestOwner]] call FLO_fnc_log;
    false
};

if (owner _playerObject != _requestOwner) exitWith {
    ["INIT", 1, format [
        "Rejected foreign player activation: requester=%1 playerOwner=%2 player=%3",
        _requestOwner,
        owner _playerObject,
        name _playerObject
    ]] call FLO_fnc_log;
    false
};

private _startPosition = FLO_MissionConfig get "startPosition";
if !(_startPosition isEqualType [] && {count _startPosition == 3}) exitWith {
    ["INIT", 1, format ["Mission start position is malformed: %1", _startPosition]] call FLO_fnc_log;
    false
};

_playerObject hideObjectGlobal false;
_playerObject enableSimulationGlobal true;
_playerObject setVariable ["FLO_InitPlayerActivation", [_startPosition, diag_tickTime], _requestOwner];

["INIT", 3, format ["Activated player %1 for owner %2", name _playerObject, _requestOwner]] call FLO_fnc_log;
true
