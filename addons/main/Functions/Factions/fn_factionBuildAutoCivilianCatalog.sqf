/*
 * Function: FLO_fnc_factionBuildAutoCivilianCatalog
 * Author: Frontline Operations Development Group
 * Description:
 *   Builds civilian unit and vehicle arrays from a CfgFactionClasses entry.
 *
 * Arguments:
 *   0: Faction classname <STRING>
 *
 * Return Value:
 *   HASHMAP with keys men, vehicles
 */

params [["_factionClass", "", [""]]];

private _men = [];
private _vehicles = [];
private _factionLower = toLower _factionClass;
private _factionCfg = missionConfigFile >> "CfgFactionClasses" >> _factionClass;
if !(isClass _factionCfg) then {
    _factionCfg = configFile >> "CfgFactionClasses" >> _factionClass;
};
if !(isClass _factionCfg) exitWith {
    createHashMapFromArray [["men", []], ["vehicles", []]]
};
if (getNumber (_factionCfg >> "side") != 3) exitWith {
    createHashMapFromArray [["men", []], ["vehicles", []]]
};

{
    private _vehCfg = _x;
    if ((toLower (getText (_vehCfg >> "faction"))) != _factionLower) then { continue };
    if (getNumber (_vehCfg >> "scope") < 2) then { continue };
    if (getNumber (_vehCfg >> "side") != 3) then { continue };

    private _className = configName _vehCfg;
    if (_className isKindOf "Man") then {
        _men pushBackUnique _className;
    } else {
        if (_className isKindOf "Car" || {_className isKindOf "Truck"} || {_className isKindOf "Ship"}) then {
            _vehicles pushBackUnique _className;
        };
    };
} forEach ("true" configClasses (configFile >> "CfgVehicles"));

createHashMapFromArray [
    ["men", _men],
    ["vehicles", _vehicles]
]
