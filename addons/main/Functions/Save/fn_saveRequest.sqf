/* Authenticates one player-requested manual save at the server boundary. */
params [["_requester", objNull, [objNull]]];

if (!isServer) exitWith { false };
if (isNull _requester) exitWith {
    ["SAVE", 2, format ["Rejected manual save request with no player from owner %1", remoteExecutedOwner]] call FLO_fnc_log;
    false
};

private _owner = owner _requester;
if (remoteExecutedOwner > 2 && {_owner != remoteExecutedOwner}) exitWith {
    ["SAVE", 2, format [
        "Rejected manual save request from owner %1 for player owner %2",
        remoteExecutedOwner,
        _owner
    ]] call FLO_fnc_log;
    false
};

if !([_requester] call FLO_fnc_saveCanRequest) exitWith {
    ["SAVE", 2, format ["Rejected manual save request from non-admin owner %1", _owner]] call FLO_fnc_log;
    ["Saving campaign progress requires a logged-in admin.", "warning", false, _owner] call FLO_fnc_sendNotification;
    false
};
if (FLO_MissionSaveInProgress) exitWith {
    ["SAVE", 2, format ["Rejected concurrent manual save request from owner %1", _owner]] call FLO_fnc_log;
    ["Campaign saving is already in progress.", "warning", false, _owner] call FLO_fnc_sendNotification;
    false
};

["SAVE", 3, "Authorized manual campaign save requested"] call FLO_fnc_log;
// Spawn locally after authentication so the worker owns a server-local execution context.
[_owner] spawn {
    params ["_owner"];
    if !([_owner] call FLO_fnc_saveStart) then {
        ["Campaign saving is already in progress or initialization is incomplete.", "warning", false, _owner] call FLO_fnc_sendNotification;
    };
};
true
