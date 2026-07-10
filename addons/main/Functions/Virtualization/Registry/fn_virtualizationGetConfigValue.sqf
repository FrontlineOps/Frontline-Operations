/*
 * Function: FLO_fnc_virtualizationGetConfigValue
 */

params [["_key", "", [""]]];

if (_key == "") then {
    throw "FLO_fnc_virtualizationGetConfigValue: empty key";
};

private _registry = call FLO_fnc_virtualizationRequireRegistry;
private _config = _registry get "config";
private _value = _config get _key;
if (isNil "_value") then {
    throw format ["FLO virtualization config missing key %1", _key];
};

_value
