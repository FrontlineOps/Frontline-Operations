params ["_unitClasses"];

if (!hasInterface) exitWith {};

if (isMultiplayer && {remoteExecutedOwner isNotEqualTo 2} && {remoteExecutedOwner isNotEqualTo 0}) exitWith {
    diag_log format ["[FLO][Store] Rejected recruit request from owner %1", remoteExecutedOwner];
};

if ((typeName _unitClasses) isNotEqualTo "ARRAY") exitWith {};

private _spawnBase = player modelToWorld [0, 4, 0];
private _spawnPos = _spawnBase findEmptyPosition [1, 15, "B_Soldier_F"];
if (_spawnPos isEqualTo []) then {
    _spawnPos = _spawnBase;
};

private _group = group player;
private _spawned = 0;

{
    if ((typeName _x) isNotEqualTo "STRING") then { continue };
    if !(isClass (configFile >> "CfgVehicles" >> _x)) then { continue };

    private _unit = _group createUnit [_x, _spawnPos, [], 3, "FORM"];
    _unit enableAI "RADIOPROTOCOL";

    if ((_x == F_Assault_Eng) || {_x == F_Recon_Eng}) then {
        _unit setUnitTrait ["engineer", true];
        _unit setVariable ["ACE_isEngineer", true, true];
    };

    if ((_x == F_Assault_Eod) || {_x == F_Recon_Eod}) then {
        _unit setUnitTrait ["explosiveSpecialist", true];
        _unit setVariable ["ACE_isEOD", true, true];
    };

    if ((_x == F_Assault_Med) || {_x == F_Recon_Med}) then {
        _unit setUnitTrait ["medic", true];
        _unit setVariable ["ace_medical_medicclass", 2, true];
    };

    _spawned = _spawned + 1;
} forEach _unitClasses;

[format ["Recruited %1 AI.", _spawned], "success"] call FLO_fnc_displayNotification;
