params ["_cfg"];

if !(isClass _cfg) exitWith { "" };

private _className = toLower configName _cfg;
private _sourceMod = toLower configSourceMod _cfg;
private _sourceAddons = configSourceAddonList _cfg apply { toLower _x };
private _activeMods = FLO_StoreOptionalModIndex get "activeMods";
private _result = "";

{
    _x params ["_label", "_prefix"];
    if (_result != "" || {!(_label in _activeMods)}) then { continue };

    private _sourceMatch = (_sourceAddons findIf { _x find _prefix == 0 }) >= 0;
    private _modName = toLower _label;
    if (
        _className find _prefix == 0
        || {_sourceMod find _modName >= 0}
        || {_sourceMatch}
    ) then {
        _result = _label;
    };
} forEach FLO_StoreOptionalModDefinitions;

_result
