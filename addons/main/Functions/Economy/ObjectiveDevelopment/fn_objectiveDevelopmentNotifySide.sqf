params [
    ["_side", sideUnknown, [west]],
    ["_message", "", [""]],
    ["_type", "info", [""]]
];

if !(_side in [west, east]) then { throw format ["Invalid development notification side %1", _side]; };
if (_message == "") then { throw "Development notification message cannot be empty"; };

{
    if ((side group _x) isEqualTo _side) then {
        [_message, _type, false, owner _x] call FLO_fnc_sendNotification;
    };
} forEach ([false] call FLO_fnc_getConnectedHumanPlayers);

true
