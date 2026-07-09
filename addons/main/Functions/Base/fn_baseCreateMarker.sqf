/*
 * Function: FLO_fnc_baseCreateMarker
 * Author: Frontline Operations Development Group
 * Description:
 *   Creates or preserves the respawn/base marker for a FOB or COP building.
 *
 * Arguments:
 * 0: Building <OBJECT>
 * 1: Base config <HASHMAP>
 * 2: Preserve marker <BOOL>
 *
 * Returns:
 * Marker name <STRING>
 */
params ["_building", "_config", "_preserveMarker"];

private _markerVariable = _config get "markerVariable";
private _restoreVariable = _config get "restoreVariable";
private _type = _config get "type";

private _markerName = "";

if (_preserveMarker && {_building getVariable [_restoreVariable, false]}) then {
    _markerName = _building getVariable [_markerVariable, ""];
    [_type, 3, format["Using restored %1 marker %2", _type, _markerName]] call FLO_fnc_log;
} else {
    private _activeSide = FLO_ActivePlayerSide;
    private _respawnKey = ["west", "east"] select (_activeSide isEqualTo east);
    private _relpos = _building getRelPos [12, 0];
    _markerName = format ["respawn_%1_%2", _respawnKey, str (getPosATL _building)];
    _building setVariable [_markerVariable, _markerName, true];

    if (_markerName in allMapMarkers) then {
        [_type, 3, format["Using existing %1 marker %2", _type, _markerName]] call FLO_fnc_log;
    } else {
        private _marker = createMarker [_markerName, _relpos];
        _marker setMarkerTypeLocal "b_installation";
        _marker setMarkerColorLocal "ColorYellow";
        _marker setMarkerTextLocal (_config get "markerText");
        _marker setMarkerSize (_config get "markerSize");
        [_type, 3, format["Created new %1 marker %2", _type, _markerName]] call FLO_fnc_log;
    };
};

_markerName
