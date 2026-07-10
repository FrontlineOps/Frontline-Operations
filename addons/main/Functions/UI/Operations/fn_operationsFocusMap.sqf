/*
 * Function: FLO_fnc_operationsFocusMap
 * Description:
 *   Animates the native Operations map to the theater, player, or objective.
 */

params [
    ["_mode", "FIT", [""]],
    ["_objectiveId", "", [""]]
];

private _map = uiNamespace getVariable ["FLO_OperationsMapControl", controlNull];
if (isNull _map || {FLO_OperationsMapDrawData isEqualTo []}) exitWith { false };

private _position = [];
private _zoom = 0.035;

switch (toUpper _mode) do {
    case "FIT": {
        private _minX = 1e10;
        private _minY = 1e10;
        private _maxX = -1e10;
        private _maxY = -1e10;
        {
            private _objectivePosition = _x select 1;
            _minX = _minX min (_objectivePosition select 0);
            _minY = _minY min (_objectivePosition select 1);
            _maxX = _maxX max (_objectivePosition select 0);
            _maxY = _maxY max (_objectivePosition select 1);
        } forEach FLO_OperationsMapDrawData;

        _position = [(_minX + _maxX) * 0.5, (_minY + _maxY) * 0.5, 0];
        private _span = ((_maxX - _minX) max (_maxY - _minY)) max 1000;
        _zoom = (0.08 + (0.28 * (_span / worldSize))) min 0.5;
    };
    case "PLAYER": {
        _position = (FLO_OperationsLastSnapshot get "player") get "position";
        _zoom = 0.025;
    };
    case "TARGET": {
        private _operation = FLO_OperationsLastSnapshot get "operation";
        _objectiveId = _operation get "targetId";
        if (_objectiveId == "") then {
            private _threatSector = _operation get "threatSector";
            if (_threatSector get "visible") then {
                _position = _threatSector get "position";
                _zoom = (0.035 + (0.35 * ((_threatSector get "longAxis") / worldSize))) min 0.25;
            };
        };
    };
    case "OBJECTIVE": {};
    default {
        throw format ["FLO_fnc_operationsFocusMap: unsupported mode %1", _mode];
    };
};

if (_position isEqualTo [] && {_objectiveId != ""}) then {
    {
        if ((_x select 0) == _objectiveId) exitWith {
            _position = _x select 1;
        };
    } forEach FLO_OperationsMapDrawData;
};

if (_position isEqualTo []) exitWith { false };

ctrlMapAnimClear _map;
_map ctrlMapAnimAdd [0.25, _zoom, _position];
ctrlMapAnimCommit _map;
true
