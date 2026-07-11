/* Localizes and presents one notification through the native FOOF stack. */
params [
    ["_message", "", ["", []]],
    ["_type", "info", [""]],
    ["_playMusic", false, [true]]
];

if (!hasInterface) exitWith {};
if (isMultiplayer && {remoteExecutedOwner != 0} && {remoteExecutedOwner != 2}) exitWith {
    diag_log format ["[FLO][Notification] Rejected client presentation from owner %1", remoteExecutedOwner];
};

if (_message isEqualType []) then {
    private _formatArgs = +_message;
    {
        if (_x isEqualType "" && {_x find "STR_" == 0}) then {
            _formatArgs set [_forEachIndex, localize _x];
        };
    } forEach _formatArgs;
    _message = format _formatArgs;
} else {
    if (_message find "STR_" == 0) then { _message = localize _message; };
};

_type = toLower _type;
private _duration = switch _type do {
    case "success": { 9 };
    case "warning": { 12 };
    case "error": { 15 };
    default { 6 };
};

[_message, _type, "", _duration] call FLO_fnc_notify;
if (_playMusic) then { playMusic "EventTrack01_F_Curator"; };
