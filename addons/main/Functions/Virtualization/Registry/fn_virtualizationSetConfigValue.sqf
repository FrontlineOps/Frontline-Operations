/*
 * Function: FLO_fnc_virtualizationSetConfigValue
 * Description:
 *   Updates a declared runtime configuration value. Undeclared keys fail.
 */

params [
    ["_key", "", [""]],
    "_value"
];

private _registry = call FLO_fnc_virtualizationRequireRegistry;
private _config = _registry get "config";
if !(_key in _config) then {
    throw format ["FLO virtualization config missing key %1", _key];
};

private _current = _config get _key;
if !(_value isEqualType _current) then {
    throw format [
        "FLO virtualization config %1 has type %2, expected %3",
        _key,
        typeName _value,
        typeName _current
    ];
};

_config set [_key, _value];
call FLO_fnc_virtualizationTouchRegistry;
true
