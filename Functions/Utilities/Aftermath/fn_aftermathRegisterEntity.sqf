/*
 * Function: FLO_fnc_aftermathRegisterEntity
 * Author: Frontline Operations Development Group
 * Description:
 *   Registers a corpse, wreck, or weapon holder for FLO-owned cleanup.
 *
 * Arguments:
 * 0: Entity <OBJECT>
 * 1: Kind <STRING> - "corpse", "wreck", or "weaponHolder"
 *
 * Return Value:
 * BOOL - True when the entity is tracked
 */

params [
    ["_entity", objNull, [objNull]],
    ["_kind", "", [""]]
];

if (!isServer) exitWith { false };
if (isNull _entity) exitWith { false };
if (_entity getVariable ["FLO_NoAftermathCleanup", false]) exitWith { false };

if (_kind == "corpse") then {
    if (alive _entity) exitWith { false };
    if !(_entity isKindOf "CAManBase") exitWith { false };
} else {
    if (_kind == "wreck") then {
        if (alive _entity) exitWith { false };
        if !(_entity isKindOf "LandVehicle" || {_entity isKindOf "Air"} || {_entity isKindOf "Ship"}) exitWith { false };
    } else {
        if (_kind == "weaponHolder") then {
            if !(_entity isKindOf "GroundWeaponHolder" || {_entity isKindOf "WeaponHolder"} || {_entity isKindOf "WeaponHolderSimulated"}) exitWith { false };
        } else {
            exitWith { false };
        };
    };
};

private _state = FLO_AftermathCleanup;
private _trackedEntities = _state get "trackedEntities";
private _entityKey = str _entity;

if (isNil { _trackedEntities get _entityKey }) then {
    _trackedEntities set [_entityKey, [_entity, diag_tickTime, _kind]];
};

true
