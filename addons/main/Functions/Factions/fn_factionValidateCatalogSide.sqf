/*
 * Function: FLO_fnc_factionValidateCatalogSide
 * Description:
 *   Verifies that every class in selected catalog fields belongs to the
 *   catalog's native Arma side. This is the initialization boundary that
 *   permits all later spawning paths to create native units directly.
 *
 * Arguments:
 *   0: Catalog <HASHMAP>
 *   1: Expected CfgVehicles side <NUMBER>
 *   2: Catalog label <STRING>
 *   3: Fields to validate <ARRAY>
 *
 * Return Value:
 *   True when every catalog entry belongs to the expected side <BOOL>
 */

params [
    ["_catalog", createHashMap, [createHashMap]],
    ["_expectedSide", -1, [0]],
    ["_label", "", [""]],
    ["_fields", [], [[]]]
];

if !(_expectedSide in [0, 1, 3]) then {
    private _message = format ["Invalid native side %1 for %2 faction catalog", _expectedSide, _label];
    ["FACTIONS", 1, _message] call FLO_fnc_log;
    throw _message;
};

private _violations = [];
private _checkedClasses = [];

{
    private _field = _x;
    private _entries = _catalog get _field;

    if !(_entries isEqualType []) then {
        _violations pushBack format ["%1 is not an array", _field];
        continue;
    };

    {
        private _entry = _x;

        if (_entry isEqualType "") then {
            if !(_entry in _checkedClasses) then {
                _checkedClasses pushBack _entry;
                private _vehicleCfg = configFile >> "CfgVehicles" >> _entry;
                if !(isClass _vehicleCfg) then {
                    _violations pushBack format ["%1:%2 is not a CfgVehicles class", _field, _entry];
                } else {
                    private _actualSide = getNumber (_vehicleCfg >> "side");
                    if (_actualSide != _expectedSide) then {
                        _violations pushBack format ["%1:%2 has side %3", _field, _entry, _actualSide];
                    };
                };
            };
            continue;
        };

        if (_entry isEqualType configNull) then {
            if !(isClass _entry) then {
                _violations pushBack format ["%1 contains an invalid config entry", _field];
                continue;
            };

            private _groupUnits = "true" configClasses _entry;
            if (_groupUnits isEqualTo []) then {
                _violations pushBack format ["%1:%2 contains no units", _field, configName _entry];
                continue;
            };

            {
                private _unitClass = getText (_x >> "vehicle");
                private _unitCfg = configFile >> "CfgVehicles" >> _unitClass;
                if (_unitClass == "" || {!(isClass _unitCfg)}) then {
                    _violations pushBack format ["%1:%2 contains an invalid unit class", _field, configName _entry];
                    continue;
                };

                if !(_unitClass in _checkedClasses) then {
                    _checkedClasses pushBack _unitClass;
                    private _actualSide = getNumber (_unitCfg >> "side");
                    if (_actualSide != _expectedSide) then {
                        _violations pushBack format ["%1:%2 contains %3 with side %4", _field, configName _entry, _unitClass, _actualSide];
                    };
                };
            } forEach _groupUnits;
            continue;
        };

        _violations pushBack format ["%1 contains unsupported entry type %2", _field, typeName _entry];
    } forEach _entries;
} forEach _fields;

if (_violations isNotEqualTo []) then {
    private _shown = _violations select [0, 8];
    private _message = format [
        "%1 faction catalog violates native side %2 (%3 issue(s)): %4",
        _label,
        _expectedSide,
        count _violations,
        _shown joinString "; "
    ];
    ["FACTIONS", 1, _message] call FLO_fnc_log;
    throw _message;
};

true
