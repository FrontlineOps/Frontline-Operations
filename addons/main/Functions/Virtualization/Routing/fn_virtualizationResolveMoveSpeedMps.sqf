/*
 * Function: FLO_fnc_virtualizationResolveMoveSpeedMps
 */

params ["_groupData"];

private _speedMPS = 0;
private _composition = _groupData get "comp";

if (_composition isNotEqualTo []) then {
    {
        private _cfg = configFile >> "CfgVehicles" >> _x;
        if (isClass _cfg) then {
            private _maxSpeed = getNumber (_cfg >> "maxSpeed");
            if (_maxSpeed > 0) then {
                private _classSpeedMPS = (_maxSpeed * 1000) / 3600;
                if (_speedMPS <= 0 || {_classSpeedMPS < _speedMPS}) then {
                    _speedMPS = _classSpeedMPS;
                };
            };
        };
    } forEach _composition;
};

if (_speedMPS > 0) exitWith { _speedMPS };

private _platformClass = [_groupData] call FLO_fnc_virtualizationResolveMovePlatformClass;
if (_platformClass == "") exitWith { 0 };

private _cfg = configFile >> "CfgVehicles" >> _platformClass;
if !(isClass _cfg) exitWith { 0 };

private _maxSpeed = getNumber (_cfg >> "maxSpeed");
if (_maxSpeed <= 0) exitWith { 0 };

(_maxSpeed * 1000) / 3600
