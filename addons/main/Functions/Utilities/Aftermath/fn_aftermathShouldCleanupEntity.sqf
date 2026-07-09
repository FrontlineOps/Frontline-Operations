/*
 * Function: FLO_fnc_aftermathShouldCleanupEntity
 * Author: Frontline Operations Development Group
 * Description:
 *   Evaluates whether a tracked corpse, wreck, or weapon holder should be
 *   removed now.
 *
 * Arguments:
 * 0: Entity <OBJECT>
 * 1: Kind <STRING>
 * 2: Player positions <ARRAY>
 * 3: Player evidence radius <NUMBER>
 * 4: Current time <NUMBER>
 * 5: First seen time <NUMBER>
 *
 * Return Value:
 * BOOL - True when the entity should be deleted
 */

params [
    ["_entity", objNull, [objNull]],
    ["_kind", "", [""]],
    ["_playerPositions", [], [[]]],
    ["_playerEvidenceRadius", 0, [0]],
    ["_now", 0, [0]],
    ["_firstSeen", 0, [0]]
];

if (isNull _entity) exitWith { false };
if (_entity getVariable ["FLO_NoAftermathCleanup", false]) exitWith { false };

private _state = FLO_AftermathCleanup;
private _graceTime = -1;

if (_kind == "corpse") then {
    if (alive _entity) exitWith { false };
    _graceTime = _state get "corpseGraceTime";
} else {
    if (_kind == "wreck") then {
        if (alive _entity) exitWith { false };
        _graceTime = _state get "wreckGraceTime";
    } else {
        if (_kind == "weaponHolder") then {
            _graceTime = _state get "weaponHolderGraceTime";
        };
    };
};

if (_graceTime < 0) exitWith { false };
if ((_now - _firstSeen) < _graceTime) exitWith { false };

private _entityPos = getPosATL _entity;
if ((_playerPositions findIf { _entityPos distance2D _x <= _playerEvidenceRadius }) > -1) exitWith { false };

true
