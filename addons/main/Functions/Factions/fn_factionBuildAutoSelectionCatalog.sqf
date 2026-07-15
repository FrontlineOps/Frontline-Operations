/* Builds one canonical catalog from a current auto-discovered faction handle. */
params [
    ["_handle", createHashMap, [createHashMap]],
    ["_role", "", [""]]
];

private _source = [_handle] call FLO_fnc_factionHandleSource;
if !(_source in ["auto", "auto_multi"]) then {
    throw format ["Auto faction catalog received source %1", _source];
};

private _factionClasses = if (_source == "auto_multi") then {
    +(_handle get "factionClasses")
} else {
    [_handle get "factionClass"]
};
if (_factionClasses isEqualTo []) then {
    throw format ["Auto faction handle %1 has no faction classes", _handle get "name"];
};

private _catalog = switch (toLower _role) do {
    case "civilian": {
        if (_source == "auto_multi") then {
            [_factionClasses] call FLO_fnc_factionBuildMergedAutoCivilianCatalog
        } else {
            [_factionClasses select 0] call FLO_fnc_factionBuildAutoCivilianCatalog
        }
    };
    case "blufor";
    case "opfor": {
        if (_source == "auto_multi") then {
            [_factionClasses] call FLO_fnc_factionBuildMergedAutoMilitaryCatalog
        } else {
            [_factionClasses select 0] call FLO_fnc_factionBuildAutoMilitaryCatalog
        }
    };
    default {
        throw format ["Unsupported auto faction role %1", _role]
    };
};

if ((keys _catalog) isEqualTo []) then {
    throw format ["Auto faction catalog is empty for %1", _handle get "name"];
};

if ((toLower _role) == "civilian") then {
    if ((_catalog get "men") isEqualTo []) then {
        throw format ["Auto civilian faction %1 has no spawnable men", _handle get "name"];
    };
} else {
    if ((_catalog get "groundInfantryUnits") isEqualTo []) then {
        throw format ["Auto military faction %1 has no spawnable infantry", _handle get "name"];
    };

    private _groundTransport = +(_catalog get "groundTransport");
    _catalog set ["logisticsConstruction", +_groundTransport];
    _catalog set ["logisticsAmmo", +_groundTransport];
    _catalog set ["logisticsRespawn", +_groundTransport];
    _catalog set ["containers", []];
};

["FACTIONS", 3, format [
    "Built auto %1 catalog %2",
    toUpper _role,
    _handle get "name"
]] call FLO_fnc_log;

_catalog
