params [
    ["_message", "", [""]],
    ["_type", "info", [""]],
    ["_title", "", [""]],
    ["_duration", FLO_NotificationDefaultDuration, [0]]
];

if (!hasInterface) exitWith { "" };
if (_message == "") then { throw "Notification message cannot be empty"; };
if (_duration <= 0) then { _duration = FLO_NotificationDefaultDuration; };

_type = toLower _type;
private _style = [_type] call FLO_fnc_notificationStyle;
if (_title == "") then { _title = _style get "label"; };

private _id = format ["FLO_NOTIFICATION_%1_%2", diag_tickTime, floor random 1000000];
private _entry = createHashMapFromArray [
    ["id", _id],
    ["message", _message],
    ["type", _type],
    ["title", _title],
    ["createdAt", diag_tickTime]
];

FLO_NotificationActive pushBack _entry;
while {(count FLO_NotificationActive) > FLO_NotificationMaxVisible} do {
    private _oldest = FLO_NotificationActive select 0;
    [_oldest get "id"] call FLO_fnc_notificationRemove;
};

[] call FLO_fnc_notificationRender;
[
    {
        params ["_id"];
        [_id] call FLO_fnc_notificationRemove;
    },
    [_id],
    _duration
] call CBA_fnc_waitAndExecute;

_id
