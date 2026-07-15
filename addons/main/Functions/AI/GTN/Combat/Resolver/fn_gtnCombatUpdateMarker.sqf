/*
 * Function: FLO_fnc_gtnCombatUpdateMarker
 * Author: Frontline Operations Development Group
 * Description:
 *   Creates or refreshes the debug marker for a recorded virtual combat event
 *   using a compact active-player-side combat status label.
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
if !(FLO_ActivePlayerSide in [east, west]) then {
    ["GTN_COMBAT", 1, format ["Cannot render combat marker for invalid player side %1", FLO_ActivePlayerSide]] call FLO_fnc_log;
    throw "FLO_fnc_gtnCombatUpdateMarker requires a valid active player side";
};

private _zoneId = _event get "objectiveId";
private _pos = _event get "position";
private _id = [_zoneId] call FLO_fnc_gtnCombatMarkerId;

createMarker [_id, _pos];
_id setMarkerPosLocal _pos;
_id setMarkerShapeLocal "ICON";
_id setMarkerTypeLocal "loc_Attack";
_id setMarkerSizeLocal [0.4, 0.4];
_id setMarkerAlphaLocal 0.85;

private _color = "ColorEAST";
if (_winner isEqualTo west) then {
    _color = "ColorWEST";
};

private _playerStatus = ["LOSING", "WINNING"] select (_winner isEqualTo FLO_ActivePlayerSide);
if (_event get "decisive") then {
    _playerStatus = format ["%1 / DECISIVE", _playerStatus];
};

_id setMarkerColorLocal _color;
_id setMarkerText format ["COMBAT %1", _playerStatus];

FLO_GTN_CombatDebugMarkers set [_id, diag_tickTime + _markerTTL];

private _order = FLO_GTN_CombatDebugMarkerOrder;
private _existingIdx = _order find _id;
if (_existingIdx >= 0) then {
    _order deleteAt _existingIdx;
};

_order pushBack _id;
FLO_GTN_CombatDebugMarkerOrder = _order;
