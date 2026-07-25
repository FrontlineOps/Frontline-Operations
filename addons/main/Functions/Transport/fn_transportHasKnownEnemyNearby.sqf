/*
 * Function: FLO_fnc_transportHasKnownEnemyNearby
 * Author: Frontline Operations Development Group
 * Description:
 *   Checks maintained side-owned GTN enemy intel for a fresh known enemy
 *   contact near the supplied position. This uses raw contact reports and the
 *   commander's maintained known-group picture.
 *
 * Arguments:
 *   0: Side <SIDE>
 *   1: Position <ARRAY>
 *   2: Radius Meters <NUMBER>
 *
 * Return Value:
 *   BOOL - True when a fresh known enemy contact is nearby
 */

params [
    ["_side", sideUnknown, [sideUnknown]],
    ["_position", [0, 0, 0], [[]]],
    ["_radius", 500, [0]]
];

if !(_side in [east, west]) exitWith { false };
if !([_position] call FLO_fnc_validateGroupPosition) exitWith { false };

private _gtnCommander = [_side] call FLO_fnc_gtnGetCommanderBySide;
if (isNil "_gtnCommander") exitWith { false };

private _worldState = _gtnCommander get "_worldState";
private _enemyIntel = _worldState call ["_getEnemyIntel", []];
private _knownGroupPicture = _worldState call ["_getKnownEnemyGroupPicture", []];
private _freshSeconds = _worldState get "_knownEnemyGroupFreshSeconds";
private _cutoffTime = diag_tickTime - _freshSeconds;

if (((_enemyIntel get "contactReports") findIf {
    _x params ["_contactPos", "_contactTime"];
    _contactTime >= _cutoffTime && {(_contactPos distance2D _position) <= _radius}
}) >= 0) exitWith { true };

private _enemyNear = false;
{
    private _entry = _y;
    private _lastSeen = _entry get "lastSeen";
    if (_lastSeen < _cutoffTime) then { continue };

    private _entryPos = _entry get "position";
    if !([_entryPos] call FLO_fnc_validateGroupPosition) then { continue };
    if ((_entryPos distance2D _position) <= _radius) exitWith {
        _enemyNear = true;
    };
} forEach (_knownGroupPicture get "groups");

_enemyNear
