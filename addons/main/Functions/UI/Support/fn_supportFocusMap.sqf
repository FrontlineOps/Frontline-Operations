params [["_mode", "PLAYER", [""]]];

private _map = uiNamespace getVariable ["FLO_SupportMapControl", controlNull];
if (isNull _map) exitWith { false };

private _position = getPosATL player;
private _zoom = 0.035;
switch (toUpper _mode) do {
    case "PLAYER": {};
    case "TARGET": {
        if (FLO_SupportTargetPosition isEqualTo []) exitWith {};
        _position = +FLO_SupportTargetPosition;
        _zoom = 0.02;
    };
    default {
        throw format ["FLO_fnc_supportFocusMap: unsupported mode %1", _mode];
    };
};

ctrlMapAnimClear _map;
_map ctrlMapAnimAdd [0.25, _zoom, _position];
ctrlMapAnimCommit _map;
true
