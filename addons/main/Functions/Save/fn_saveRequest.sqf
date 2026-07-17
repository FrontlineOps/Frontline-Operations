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

if ((admin _owner) <= 0) exitWith {
    ["SAVE", 2, format ["Rejected manual save request from non-admin owner %1", _owner]] call FLO_fnc_log;
    ["Saving campaign progress requires a logged-in admin.", "warning", false, _owner] call FLO_fnc_sendNotification;
    false
};
if (FLO_MissionSaveInProgress) exitWith {
    ["SAVE", 2, format ["Rejected concurrent manual save request from owner %1", _owner]] call FLO_fnc_log;
    ["Campaign saving is already in progress.", "warning", false, _owner] call FLO_fnc_sendNotification;
    false
};

["SAVE", 3, format ["Manual save requested by admin owner %1", _owner]] call FLO_fnc_log;
private _saved = call FLO_fnc_MissionSave;
if (_saved) then {
    ["Campaign progress saved.", "success", false, _owner] call FLO_fnc_sendNotification;
} else {
    ["Campaign progress was not saved. Check the server RPT for the rejected state.", "error", false, _owner] call FLO_fnc_sendNotification;
};

_saved
