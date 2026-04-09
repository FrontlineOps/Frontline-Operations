/*
 * Function: FLO_fnc_aftermathCleanupRun
 * Author: Frontline Operations Development Group
 * Description:
 *   Periodic server cleanup pass for corpses, wrecks, and weapon holders.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * BOOL - True when the pass completed
 */

if (!isServer) exitWith { false };
if (isNil "FLO_AftermathCleanup") exitWith { false };

private _state = FLO_AftermathCleanup;
if !(_state get "enabled") exitWith { false };

{
    {
        [_x, "weaponHolder"] call FLO_fnc_aftermathRegisterEntity;
    } forEach (allMissionObjects _x);
} forEach (_state get "weaponHolderClasses");

private _trackedEntities = _state get "trackedEntities";
private _playerPositions = (allPlayers select { alive _x }) apply { getPosATL _x };
private _playerEvidenceRadius = _state get "playerEvidenceRadius";
private _now = diag_tickTime;

private _deletedCorpses = 0;
private _deletedWrecks = 0;
private _deletedWeaponHolders = 0;

{
    private _entityKey = _x;
    private _entry = _trackedEntities get _entityKey;
    _entry params ["_entity", "_firstSeen", "_kind"];

    if (isNull _entity) then {
        _trackedEntities deleteAt _entityKey;
        continue;
    };

    if !([
        _entity,
        _kind,
        _playerPositions,
        _playerEvidenceRadius,
        _now,
        _firstSeen
    ] call FLO_fnc_aftermathShouldCleanupEntity) then {
        if (_kind == "corpse" && {alive _entity}) then {
            _trackedEntities deleteAt _entityKey;
        };
        if (_kind == "wreck" && {alive _entity}) then {
            _trackedEntities deleteAt _entityKey;
        };
        continue;
    };

    _entity hideObjectGlobal true;
    deleteVehicle _entity;
    _trackedEntities deleteAt _entityKey;

    switch (_kind) do {
        case "corpse": { _deletedCorpses = _deletedCorpses + 1; };
        case "wreck": { _deletedWrecks = _deletedWrecks + 1; };
        case "weaponHolder": { _deletedWeaponHolders = _deletedWeaponHolders + 1; };
    };
} forEach (keys _trackedEntities);

if ((_deletedCorpses + _deletedWrecks + _deletedWeaponHolders) > 0) then {
    ["AFTERMATH_CLEANUP", 2, format [
        "Deleted aftermath entities (corpses=%1 wrecks=%2 holders=%3)",
        _deletedCorpses,
        _deletedWrecks,
        _deletedWeaponHolders
    ]] call FLO_fnc_log;
};

true
