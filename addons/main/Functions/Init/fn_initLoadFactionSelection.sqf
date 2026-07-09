/*
 * Function: FLO_fnc_initLoadFactionSelection
 * Description:
 *   Loads one custom or auto-discovered faction selection during Phase 2.
 */
params ["_handle", ["_role", "", [""]]];

private _factionName = _handle get "name";
private _source = [_handle] call FLO_fnc_factionHandleSource;

if (_source in ["auto", "auto_multi"]) exitWith {
    [_handle, _role] call FLO_fnc_factionApplyAutoGlobals
};

private _customDefinition = [_role] call FLO_fnc_factionGetCustomDefinition;
_customDefinition params ["_customName", "_filePath"];

if (_factionName isNotEqualTo _customName) exitWith {
    diag_log format [
        "[FLO_INIT_P2] Unsupported non-custom %1 faction selection: %2",
        _role,
        _factionName
    ];
    false
};

[_factionName, _filePath] call FLO_fnc_initLoadFactionDefinition
