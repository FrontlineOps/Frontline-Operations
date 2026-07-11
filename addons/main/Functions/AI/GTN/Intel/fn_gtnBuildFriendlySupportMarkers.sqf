/*
 * Function: FLO_fnc_gtnBuildFriendlySupportMarkers
 * Author: Frontline Operations Development Group
 * Description:
 *   Builds commander COP support markers for active friendly artillery
 *   missions from the maintained artillery-manager mission state.
 *
 * Arguments:
 *   0: GTN world state <HASHMAPOBJECT>
 *
 * Return Value:
 *   ARRAY - Generic marker records
 */

params [["_worldState", nil]];

if (isNil "_worldState" || {isNil "FLO_GTNArtilleryManager"}) exitWith { [] };

private _ownSide = _worldState get "_ownSide";
private _sideKey = _worldState get "_sideKey";
private _friendlyColor = ["ColorBLUFOR", "ColorOPFOR"] select (_ownSide isEqualTo east);
private _markerType = ["artillery", _ownSide] call FLO_fnc_gtnCommanderIntelMarkerType;
private _missions = FLO_GTNArtilleryManager get "missions";
private _markers = [];

{
    private _groupId = _x;
    private _mission = _y;
    if (!(_mission isEqualType createHashMap)) then { continue };

    if ((_mission get "side") != _ownSide) then { continue };
    if (diag_tickTime > (_mission get "expiresAt")) then { continue };

    private _issuedAt = _mission get "issuedAt";
    private _etaMin = _mission get "etaMin";
    private _etaMax = _mission get "etaMax";
    private _elapsed = diag_tickTime - _issuedAt;
    private _etaMinLeft = if (_etaMin >= 0) then { ceil ((_etaMin - _elapsed) max 0) } else { -1 };
    private _etaMaxLeft = if (_etaMax >= 0) then { ceil ((_etaMax - _elapsed) max 0) } else { -1 };
    private _text = if (_etaMaxLeft > 0) then {
        if (_etaMinLeft >= 0 && {_etaMaxLeft > _etaMinLeft}) then {
            format ["ARTY %1-%2s", _etaMinLeft, _etaMaxLeft]
        } else {
            format ["ARTY %1s", _etaMaxLeft]
        }
    } else {
        "ARTY FIRE"
    };

    private _targetPos = _mission get "targetPos";
    private _radius = _mission get "radius";
    private _markerBase = format ["FLO_GTN_INTEL_%1_SUP_ARTY_%2", _sideKey, _groupId];

    _markers pushBack [
        format ["%1_ICON", _markerBase],
        "ICON",
        _targetPos,
        _markerType,
        [0.55, 0.55],
        0.75,
        _text,
        _friendlyColor,
        ""
    ];

    if (_radius > 0) then {
        _markers pushBack [
            format ["%1_AREA", _markerBase],
            "ELLIPSE",
            _targetPos,
            "",
            [_radius, _radius],
            0.14,
            "",
            _friendlyColor,
            "DiagGrid"
        ];
    };

    {
        _markers pushBack [
            format ["%1_DOT_%2", _markerBase, _forEachIndex],
            "ICON",
            _x,
            "mil_dot",
            [0.4, 0.4],
            0.6,
            "",
            _friendlyColor,
            ""
        ];
    } forEach (_mission get "impactPoints");
} forEach _missions;

_markers
