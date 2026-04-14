/*
 * Function: FLO_fnc_gtnCombatUpdateMarker
 * Author: Frontline Operations Development Group
 * Description:
 *   Creates or refreshes the debug marker for a recorded virtual combat event
 *   using a compact WEST-perspective combat status label.
 *
 * Arguments:
 *   0: Combat event <HASHMAP>
 *   1: Marker time-to-live <NUMBER>
 *
 * Return Value:
 *   None
 */

params ["_event", "_markerTTL"];

if (!FLO_GTN_CombatDebugEnabled) exitWith {};

private _winner = _event get "winner";
if !(_winner in [east, west]) exitWith {};

private _zoneId = _event get "objectiveId";
private _pos = _event get "position";
private _id = [_zoneId] call FLO_fnc_gtnCombatMarkerId;

createMarker [_id, _pos];
_id setMarkerPos _pos;
_id setMarkerShape "ICON";
_id setMarkerType "loc_Attack";
_id setMarkerSize [0.4, 0.4];
_id setMarkerAlpha 0.85;

private _winnerLabel = "EAST";
private _color = "ColorEAST";
if (_winner isEqualTo west) then {
    _winnerLabel = "WEST";
    _color = "ColorWEST";
};

private _westStatus = if (_winner isEqualTo west) then { "Winning" } else { "Losing" };

_id setMarkerColor _color;
_id setMarkerText format ["COMBAT %1", _westStatus];

FLO_GTN_CombatDebugMarkers set [_id, diag_tickTime + _markerTTL];

private _order = FLO_GTN_CombatDebugMarkerOrder;
private _existingIdx = _order find _id;
if (_existingIdx >= 0) then {
    _order deleteAt _existingIdx;
};

_order pushBack _id;
FLO_GTN_CombatDebugMarkerOrder = _order;
