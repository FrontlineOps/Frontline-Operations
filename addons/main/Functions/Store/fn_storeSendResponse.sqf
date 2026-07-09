params ["_owner", "_event", "_payload"];

if (!isServer) exitWith {};

if (_owner <= 0) exitWith {
    if (hasInterface) then {
        [_event, _payload] call FLO_fnc_storeReceiveResponse;
    };
};

[_event, _payload] remoteExecCall ["FLO_fnc_storeReceiveResponse", _owner];
