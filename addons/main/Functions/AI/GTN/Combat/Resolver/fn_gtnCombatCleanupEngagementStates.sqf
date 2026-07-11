/* Removes momentum records for combat zones that have not been observed recently. */
params [["_activeZoneIds", [], [[]]]];

private _state = call FLO_fnc_gtnCombatGetState;
private _engagements = _state get "engagements";
private _ttl = _state get "engagementStateTTL";
private _now = diag_tickTime;
private _active = createHashMap;
{ _active set [_x, true]; } forEach _activeZoneIds;

{
    if (_x in _active) then { continue };
    private _engagement = _engagements get _x;
    if ((_now - (_engagement get "lastSeenAt")) <= _ttl) then { continue };
    _engagements deleteAt _x;
} forEach (keys _engagements);

true
