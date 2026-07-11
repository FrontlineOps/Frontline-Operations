/*
 * Function: FLO_fnc_virtualizationResolveMovePlatformClass
 */

params ["_groupData"];

private _vehicleType = _groupData get "vehicleType";
if (_vehicleType != "") exitWith { _vehicleType };

private _spawnClass = _groupData get "spawnClass";
if (_spawnClass != "" && {isClass (configFile >> "CfgVehicles" >> _spawnClass)}) exitWith {
    _spawnClass
};

private _groupCfg = _groupData get "groupCfg";
if (_groupCfg isEqualType configNull && {!isNull _groupCfg}) then {
    private _units = configProperties [_groupCfg, "isClass _x", false];
    if (_units isNotEqualTo []) then {
        private _unitClass = getText ((_units select 0) >> "vehicle");
        if (_unitClass != "" && {isClass (configFile >> "CfgVehicles" >> _unitClass)}) exitWith {
            _unitClass
        };
    };
};

""
