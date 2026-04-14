/*
 * Function: FLO_fnc_gtnCombatCleanupMarkers
 * Author: Frontline Operations Development Group
 * Description:
 *   Removes expired combat debug markers or clears them all when debug display
 *   is disabled.
 *
 * Arguments:
 *   None
 *
 * Return Value:
 *   None
 */

if (!FLO_GTN_CombatDebugEnabled) exitWith {
    {
        deleteMarker _x;
    } forEach (keys FLO_GTN_CombatDebugMarkers);
    FLO_GTN_CombatDebugMarkers = createHashMap;
    FLO_GTN_CombatDebugMarkerOrder = [];
};

private _now = diag_tickTime;
private _expired = [];

{
    private _markerId = _x;
    if ((FLO_GTN_CombatDebugMarkers get _markerId) <= _now) then {
        _expired pushBack _markerId;
    };
} forEach (keys FLO_GTN_CombatDebugMarkers);

private _order = FLO_GTN_CombatDebugMarkerOrder;

{
    deleteMarker _x;
    FLO_GTN_CombatDebugMarkers deleteAt _x;
    private _idx = _order find _x;
    if (_idx >= 0) then {
        _order deleteAt _idx;
    };
} forEach _expired;

FLO_GTN_CombatDebugMarkerOrder = _order;
