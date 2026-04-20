/*
 * Function: FLO_fnc_factionClassifyVehicle
 * Author: Frontline Operations Development Group
 * Description:
 *   Classifies a CfgVehicles class into FLO faction catalog vehicle pools.
 *
 * Arguments:
 *   0: Vehicle classname <STRING>
 *
 * Return Value:
 *   ARRAY of catalog pool keys
 */

params [["_className", "", [""]]];

if (_className == "") exitWith { [] };

private _cfg = configFile >> "CfgVehicles" >> _className;
if !(isClass _cfg) exitWith { [] };
if (getNumber (_cfg >> "scope") < 2) exitWith { [] };
if (_className isKindOf "Man") exitWith { [] };

private _cnLower = toLower _className;
private _dnLower = toLower (getText (_cfg >> "displayName"));
private _cats = [];

private _hasText = {
    params ["_needle"];
    (_cnLower find _needle) >= 0 || {(_dnLower find _needle) >= 0}
};

private _isAA = {
    (["aa"] call _hasText) ||
    {["sam"] call _hasText} ||
    {["anti_air"] call _hasText} ||
    {["antiair"] call _hasText} ||
    {["zu23"] call _hasText} ||
    {["tunguska"] call _hasText} ||
    {["shilka"] call _hasText}
};

private _isArtillery = {
    (getNumber (_cfg >> "artilleryScanner") > 0) ||
    {["arty"] call _hasText} ||
    {["artillery"] call _hasText} ||
    {["mortar"] call _hasText} ||
    {["mlrs"] call _hasText} ||
    {["howitzer"] call _hasText}
};

private _isDrone = (getNumber (_cfg >> "isUav") > 0) ||
    {["uav"] call _hasText} ||
    {["ugv"] call _hasText} ||
    {["drone"] call _hasText};

if (_isDrone) then {
    if (_className isKindOf "Air") then {
        _cats pushBack "airDrone";
    } else {
        _cats pushBack "groundDrone";
    };
};

if (_className isKindOf "StaticWeapon") exitWith {
    if (call _isAA) then {
        _cats pushBack "staticAA";
    };
    if (call _isArtillery) then {
        _cats pushBack "groundArtillery";
    };
    _cats arrayIntersect _cats
};

if (_className isKindOf "Helicopter") exitWith {
    private _transport = getNumber (_cfg >> "transportSoldier");
    if (_transport >= 4) then {
        _cats pushBack "airTransport";
    };
    if (_transport <= 6 || {["attack"] call _hasText} || {["gunship"] call _hasText}) then {
        _cats pushBack "airHeli";
    };
    _cats arrayIntersect _cats
};

if (_className isKindOf "Plane") exitWith {
    ["airJet"]
};

if (_className isKindOf "Ship") exitWith {
    ["boat"]
};

if (_className isKindOf "LandVehicle") then {
    private _transport = getNumber (_cfg >> "transportSoldier");
    private _armor = getNumber (_cfg >> "armor");

    if (call _isArtillery) then {
        _cats pushBack "groundArtillery";
    };

    if (call _isAA) then {
        _cats pushBack "mobileAA";
    };

    if (_className isKindOf "Tank") then {
        if (_transport > 0 || {_armor < 500} || {["apc"] call _hasText} || {["ifv"] call _hasText}) then {
            _cats pushBack "groundMechanized";
        } else {
            _cats pushBack "groundArmor";
        };
    } else {
        if (_className isKindOf "Truck") then {
            if (_transport > 0) then {
                _cats pushBack "groundTransport";
            };
        };

        if (_className isKindOf "Car") then {
            _cats pushBack "groundMotorized";
            if (_transport >= 4) then {
                _cats pushBack "groundTransport";
            };
        };
    };
};

_cats arrayIntersect _cats
