/*
 * Function: FLO_fnc_bribeMilitia
 * Description:
 *   Validates a militia bribe request and mutates authoritative campaign state.
 */
params [["_requester", objNull, [objNull]]];

if (!isServer || {isNull _requester}) exitWith { false };

private _owner = owner _requester;
if ((remoteExecutedOwner > 2) && {_owner isNotEqualTo remoteExecutedOwner}) exitWith {
    ["CIVILIANS", 1, format [
        "Rejected militia bribe from owner %1 for player owner %2",
        remoteExecutedOwner,
        _owner
    ]] call FLO_fnc_log;
    false
};

private _isAdmin = (admin _owner) > 0;
private _isOfficer = (typeOf _requester isEqualTo F_Officer) || {typeOf _requester isEqualTo "B_G_officer_F"};
if (!_isAdmin && {!_isOfficer}) exitWith {
    ["You are not authorized to bribe the militia.", "warning", false, _owner] call FLO_fnc_sendNotification;
    false
};

private _cost = 200;
private _side = side group _requester;
private _sideKey = [_side] call FLO_fnc_sideKey;
private _treasury = FLO_SideResources get _sideKey;
if !([_treasury, _cost] call FLO_fnc_sideResourcesCanAfford) exitWith {
    ["Not enough resources to bribe the militia.", "warning", false, _owner] call FLO_fnc_sendNotification;
    false
};

if !([
    _treasury,
    _cost,
    "CIVIL_AFFAIRS",
    "Militia bribe",
    name _requester,
    "MILITIA_BRIBE",
    true
] call FLO_fnc_sideResourcesSpendResources) then {
    throw "Militia bribe affordability changed during an unscheduled server transaction";
};

FLO_ReputationHandle set ["value", 15];
publicVariable "FLO_ReputationHandle";

[
    {
        params ["_targetOwner"];
        [["%1: %2", "STR_FLO_REPUTATION_TITLE", "STR_FLO_REP_AGG_INCBRIBE"], "success", false, _targetOwner] call FLO_fnc_sendNotification;
    },
    [_owner],
    12
] call CBA_fnc_waitAndExecute;

true
