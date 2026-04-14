/*
 * Function: FLO_fnc_transportHasKnownEnemyNearby
 * Author: Frontline Operations Development Group
 * Description:
 *   Checks maintained side-owned GTN enemy intel for a fresh known enemy
 *   contact near the supplied position. This uses both raw contact reports and
 *   the resolved engagement picture so transport threat unloads match the
 *   commander COP's maintained hostile group picture.
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

private _sideKey = ([_side] call FLO_fnc_gtnSideContext) get "sideKey";
private _gtnCommander = FLO_GTN_CommandersBySide get _sideKey;
private _worldState = _gtnCommander get "_worldState";
private _enemyIntel = _worldState call ["_getEnemyIntel", []];
private _engagementPicture = _worldState call ["_getEnemyEngagementPicture", []];
private _freshSeconds = _worldState get "_enemyEngagementFreshSeconds";
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
} forEach (_engagementPicture get "groups");

_enemyNear
