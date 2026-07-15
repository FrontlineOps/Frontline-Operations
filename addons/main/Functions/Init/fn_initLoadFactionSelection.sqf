/*
 * Loads one current faction selection and returns its canonical runtime
 * catalog. Custom definitions retain their documented variable input format;
 * auto-discovered selections never round-trip through those globals.
 */
params [
    ["_handle", createHashMap, [createHashMap]],
    ["_role", "", [""]]
];

private _source = [_handle] call FLO_fnc_factionHandleSource;
if (_source in ["auto", "auto_multi"]) exitWith {
    [_handle, _role] call FLO_fnc_factionBuildAutoSelectionCatalog
};

private _customDefinition = [_role] call FLO_fnc_factionGetCustomDefinition;
_customDefinition params ["_customName", "_filePath"];
private _factionName = _handle get "name";
if (_factionName != _customName) then {
    throw format ["Unsupported custom %1 faction selection %2", _role, _factionName];
};
if !([_factionName, _filePath] call FLO_fnc_initLoadFactionDefinition) then {
    throw format ["Custom %1 faction loading failed from %2", _role, _filePath];
};

switch (toLower _role) do {
    case "blufor": {
        private _defaults = [_handle, "BLUFOR"] call FLO_fnc_factionBuildCompositionDefaultsHandle;
        ["BLUFOR", _defaults] call FLO_fnc_factionBuildCustomMilitaryCatalog
    };
    case "opfor": {
        private _defaults = [_handle, "OPFOR"] call FLO_fnc_factionBuildCompositionDefaultsHandle;
        ["OPFOR", _defaults] call FLO_fnc_factionBuildCustomMilitaryCatalog
    };
    case "civilian": {
        call FLO_fnc_factionBuildCustomCivilianCatalog
    };
    default {
        throw format ["Unsupported custom faction role %1", _role]
    };
}
