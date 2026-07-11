params [["_id", "", [""]]];

if (!hasInterface) exitWith {};
if (_id == "") exitWith {};

private _index = FLO_NotificationActive findIf { (_x get "id") == _id };
if (_index < 0) exitWith {};

private _entry = FLO_NotificationActive select _index;
if ("controls" in _entry) then {
    {
        if (!isNull _x) then { ctrlDelete _x; };
    } forEach (_entry get "controls");
};

FLO_NotificationActive deleteAt _index;
[] call FLO_fnc_notificationRender;
