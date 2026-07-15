private _activeMods = [];
private _activePrefixes = [];
private _patchNames = ("true" configClasses (configFile >> "CfgPatches")) apply {
    toLower configName _x
};

{
    _x params ["_label", "_prefix"];
    private _loaded = (_patchNames findIf { _x find _prefix == 0 }) >= 0;

    if (_loaded) then {
        _activeMods pushBack _label;
        _activePrefixes pushBack _prefix;
    };
} forEach FLO_StoreOptionalModDefinitions;

createHashMapFromArray [
    ["activeMods", _activeMods],
    ["activePrefixes", _activePrefixes]
]
