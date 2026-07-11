/*
 * Function: FLO_fnc_gtnInjectCombatEventContacts
 * Author: Frontline Operations Development Group
 * Description:
 *   Converts recent virtual-combat telemetry into low-confidence commander
 *   contact reports so remote virtual battles can inform the maintained GTN
 *   enemy intel picture without resorting to omniscient world scans.
 *
 * Arguments:
 *   0: GTN world state <HASHMAPOBJECT>
 *   1: Existing contact reports <ARRAY>
 *
 * Return Value:
 *   ARRAY [contactReports, addedCount]
 */

params [
    ["_worldState", nil],
    ["_contacts", [], [[]]]
];

if (isNil "_worldState") exitWith { [_contacts, 0] };

private _events = FLO_GTN_CombatEvents;
private _enemySide = _worldState get "_enemySide";
private _freshSeconds = _worldState get "_combatIntelFreshSeconds";
private _lastProcessedAt = _worldState get "_combatIntelLastProcessedAt";
private _cutoffTime = diag_tickTime - _freshSeconds;
private _added = 0;
private _latestProcessedAt = _lastProcessedAt;

{
    private _eventTime = _x get "time";
    if (_eventTime <= _lastProcessedAt) then { continue };

    if (_eventTime > _latestProcessedAt) then {
        _latestProcessedAt = _eventTime;
    };

    if (_eventTime < _cutoffTime) then { continue };

    private _enemyUnits = if (_enemySide isEqualTo east) then {
        _x get "eastAfter"
    } else {
        _x get "westAfter"
    };
    private _enemyGroupCount = if (_enemySide isEqualTo east) then {
        _x get "eastGroupCount"
    } else {
        _x get "westGroupCount"
    };

    if (_enemyUnits <= 0 || {_enemyGroupCount <= 0}) then { continue };

    private _eventPos = _x get "position";
    private _isDuplicate = false;
    {
        _x params ["_contactPos", "_contactTime"];
        if ((_contactPos distance2D _eventPos) < 120 && {abs (_contactTime - _eventTime) < 90}) exitWith {
            _isDuplicate = true;
        };
    } forEach _contacts;

    if (_isDuplicate) then { continue };

    private _confidence = 0.45;
    if ((_x get "winner") isEqualTo _enemySide) then {
        _confidence = _confidence + 0.1;
    };
    if ((_x get "margin") >= 3) then {
        _confidence = _confidence + 0.05;
    };
    if (_confidence > 0.9) then {
        _confidence = 0.9;
    };

    _contacts pushBack [_eventPos, _eventTime, _enemyUnits, "combat", _confidence];
    _added = _added + 1;
} forEach _events;

_worldState set ["_combatIntelLastProcessedAt", _latestProcessedAt];

[_contacts, _added]
