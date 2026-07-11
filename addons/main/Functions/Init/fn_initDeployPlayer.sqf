/*
 * Function: FLO_fnc_initDeployPlayer
 * Description:
 *   Requests server activation and places the local player at campaign start.
 */

if (!hasInterface) exitWith { false };
if (!canSuspend) exitWith { throw "Initial player deployment requires scheduled execution" };
if (isNull player || {player != player} || {!local player}) exitWith {
    throw "Initial player deployment requires a valid local player"
};

titleText ["Deploying...", "BLACK FADED", 0.1, true, true];
FLO_ClientDeploymentFailed = false;
player setVariable ["FLO_InitPlayerActivation", nil, false];
[player] remoteExecCall ["FLO_fnc_initActivatePlayer", 2];

private _activationDeadline = diag_tickTime + 20;
waitUntil {
    sleep 0.1;
    (player getVariable ["FLO_InitPlayerActivation", []]) isNotEqualTo []
        || {diag_tickTime >= _activationDeadline}
};

private _activation = player getVariable ["FLO_InitPlayerActivation", []];
if (_activation isEqualTo []) exitWith {
    FLO_ClientDeploymentFailed = true;
    ["INIT_CLIENT", 1, "Player activation timed out after 20 seconds"] call FLO_fnc_log;
    titleText ["", "BLACK IN", 1, true, true];
    hint "FLO could not activate your player. Reconnect and check the server RPT for [FLO][INIT] errors.";
    false
};

if !(_activation isEqualType [] && {count _activation == 2}) exitWith {
    FLO_ClientDeploymentFailed = true;
    ["INIT_CLIENT", 1, format ["Player activation acknowledgement is malformed: %1", _activation]] call FLO_fnc_log;
    titleText ["", "BLACK IN", 1, true, true];
    hint "FLO received an invalid deployment acknowledgement. Check the server and client RPT.";
    false
};

_activation params ["_startPosition", "_serverTick"];
if !(
    _startPosition isEqualType []
    && {count _startPosition == 3}
    && {_serverTick isEqualType 0}
) exitWith {
    FLO_ClientDeploymentFailed = true;
    ["INIT_CLIENT", 1, format ["Player activation data is malformed: %1", _activation]] call FLO_fnc_log;
    titleText ["", "BLACK IN", 1, true, true];
    hint "FLO received malformed deployment data. Check the server and client RPT.";
    false
};

player allowDamage true;
private _placed = player setVehiclePosition [_startPosition, [], 15, "NONE"];
if (!_placed) exitWith {
    FLO_ClientDeploymentFailed = true;
    ["INIT_CLIENT", 1, format ["No safe initial player position near %1", _startPosition]] call FLO_fnc_log;
    titleText ["", "BLACK IN", 1, true, true];
    hint "FLO could not find a safe deployment position. Move the campaign start or reconnect after clearing the area.";
    false
};

private _stateDeadline = diag_tickTime + 5;
waitUntil {
    sleep 0.1;
    (simulationEnabled player && {!isObjectHidden player} && {isDamageAllowed player})
        || {diag_tickTime >= _stateDeadline}
};

if (!simulationEnabled player || {isObjectHidden player} || {!isDamageAllowed player}) exitWith {
    FLO_ClientDeploymentFailed = true;
    ["INIT_CLIENT", 1, format [
        "Player activation did not propagate: simulation=%1 hidden=%2 damage=%3",
        simulationEnabled player,
        isObjectHidden player,
        isDamageAllowed player
    ]] call FLO_fnc_log;
    titleText ["", "BLACK IN", 1, true, true];
    hint "FLO player activation did not complete. Reconnect and check the server and client RPT.";
    false
};

FLO_InitPlayerDeploymentDone = true;
["INIT_CLIENT", 3, format ["Player deployed at %1 (server tick %2)", getPosATL player, _serverTick]] call FLO_fnc_log;
true
