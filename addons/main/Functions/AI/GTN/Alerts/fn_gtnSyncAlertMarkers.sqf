/*
 * Function: FLO_fnc_gtnSyncAlertMarkers
 * Author: Frontline Operations Development Group
 * Description:
 *   Client-side sync for temporary GTN alerts. Creates local alert markers and
 *   fades them out after the requested duration.
 *
 * Arguments:
 *   0: Side key <STRING>
 *   1: Alert ID <STRING>
 *   2: Alert type <STRING>
 *   3: Position <ARRAY>
 *   4: Radius <NUMBER>
 *   5: Duration seconds <NUMBER>
 *   6: Alert payload <ARRAY>
 *
 * Return Value:
 *   BOOL
 */

if (!hasInterface) exitWith { false };

params [
    ["_sideKey", "", [""]],
    ["_alertId", "", [""]],
    ["_alertType", "", [""]],
    ["_position", [0, 0, 0], [[]], [3]],
    ["_radius", 0, [0]],
    ["_duration", 60, [0]],
    ["_payload", [], [[]]]
];

if (isNull player) exitWith { false };

private _localSide = side group player;
if !(_localSide in [east, west]) exitWith { false };

private _localSideKey = ["WEST", "EAST"] select (_localSide isEqualTo east);
if (_localSideKey != _sideKey) exitWith { false };

private _iconMarkerId = format ["%1_ICON", _alertId];
private _areaMarkerId = format ["%1_AREA", _alertId];
private _impactMarkerIds = [];

private _markerText = "ALERT";
private _markerColor = "ColorOPFOR";
private _iconMarkerType = "mil_warning";
private _areaBrush = "Border";
private _areaAlpha = 0.18;
private _etaMin = -1;
private _etaMax = -1;

switch (toUpper _alertType) do {
    case "ARTILLERY_INCOMING": {
        _markerText = "ARTY IMPACTS";
        _areaBrush = "DiagGrid";
        _areaAlpha = 0.22;
        if ((count _payload) >= 2) then {
            _etaMin = _payload select 0;
            _etaMax = _payload select 1;
        };
    };
    case "AIR_INCOMING": {
        _markerText = "AIR CONTACT";
        _areaBrush = "Border";
        _areaAlpha = 0.16;
    };
    case "CIVILIAN_REPORT": {
        _markerText = "CIV REPORT";
        _markerColor = "ColorYellow";
        _areaBrush = "Border";
        _areaAlpha = 0.14;
    };
    case "CIV_PATROL": {
        _markerText = "CIV PATROL";
        _markerColor = "ColorYellow";
        _iconMarkerType = "mil_dot";
        _areaBrush = "Border";
        _areaAlpha = 0.14;
    };
    case "CIV_VEHICLE": {
        _markerText = "CIV VEHICLE";
        _markerColor = "ColorYellow";
        _iconMarkerType = "mil_arrow2";
        _areaBrush = "Border";
        _areaAlpha = 0.14;
    };
    case "CIV_CHECKPOINT": {
        _markerText = "CIV CHECKPOINT";
        _markerColor = "ColorYellow";
        _iconMarkerType = "mil_warning";
        _areaBrush = "Border";
        _areaAlpha = 0.14;
    };
    case "CIV_SAFE_ROUTE": {
        _markerText = "CIV SAFE ROUTE";
        _markerColor = "ColorGUER";
        _iconMarkerType = "mil_arrow2";
        _areaBrush = "Border";
        _areaAlpha = 0.12;
    };
    case "CIV_HOSTILE": {
        _markerText = "CIV HOSTILE";
        _markerColor = "ColorRed";
        _iconMarkerType = "mil_warning";
        _areaBrush = "DiagGrid";
        _areaAlpha = 0.16;
    };
    case "INTEL_COMMANDER_TARGET": {
        private _objectiveName = if ((count _payload) >= 1) then { _payload select 0 } else { "" };
        private _phase = if ((count _payload) >= 2) then { toUpper (_payload select 1) } else { "" };
        _markerText = if (_objectiveName != "") then {
            format ["ENY TARGET %1", _objectiveName]
        } else {
            "ENY TARGET"
        };
        if (_phase == "ASSAULT") then {
            _markerText = _markerText + " (ASSAULT)";
        };
        _markerColor = if ((count _payload) >= 3) then { _payload select 2 } else { _markerColor };
        _iconMarkerType = "mil_objective";
        _areaBrush = "Border";
        _areaAlpha = 0.14;
    };
    case "INTEL_SUPPLY_NODE": {
        private _objectiveName = if ((count _payload) >= 1) then { _payload select 0 } else { "" };
        private _nodeType = if ((count _payload) >= 2) then { _payload select 1 } else { "SUPPLY" };
        _markerText = if (_objectiveName != "") then {
            format ["ENY %1 %2", _nodeType, _objectiveName]
        } else {
            format ["ENY %1", _nodeType]
        };
        _markerColor = if ((count _payload) >= 3) then { _payload select 2 } else { _markerColor };
        _iconMarkerType = ["o_maint", "b_maint"] select (_markerColor == "ColorBLUFOR");
        _areaBrush = "Border";
        _areaAlpha = 0.12;
    };
    case "INTEL_HQ": {
        private _objectiveName = if ((count _payload) >= 1) then { _payload select 0 } else { "" };
        _markerText = if (_objectiveName != "") then {
            format ["ENY HQ %1", _objectiveName]
        } else {
            "ENY HQ"
        };
        _markerColor = if ((count _payload) >= 3) then { _payload select 2 } else { _markerColor };
        _iconMarkerType = "n_support";
        _areaBrush = "DiagGrid";
        _areaAlpha = 0.16;
    };
};

createMarkerLocal [_iconMarkerId, _position];
_iconMarkerId setMarkerShapeLocal "ICON";
_iconMarkerId setMarkerTypeLocal _iconMarkerType;
_iconMarkerId setMarkerColorLocal _markerColor;
_iconMarkerId setMarkerTextLocal _markerText;
_iconMarkerId setMarkerSizeLocal [0.7, 0.7];
_iconMarkerId setMarkerAlphaLocal 0.9;

if ((toUpper _alertType) == "ARTILLERY_INCOMING" && {(count _payload) >= 3}) then {
    private _impactPoints = _payload select 2;
    {
        private _impactMarkerId = format ["%1_IMP_%2", _alertId, _forEachIndex];
        createMarkerLocal [_impactMarkerId, _x];
        _impactMarkerId setMarkerShapeLocal "ICON";
        _impactMarkerId setMarkerTypeLocal "mil_dot";
        _impactMarkerId setMarkerColorLocal _markerColor;
        _impactMarkerId setMarkerSizeLocal [0.45, 0.45];
        _impactMarkerId setMarkerAlphaLocal 0.75;
        _impactMarkerIds pushBack _impactMarkerId;
    } forEach _impactPoints;
};

if (_radius > 0) then {
    createMarkerLocal [_areaMarkerId, _position];
    _areaMarkerId setMarkerShapeLocal "ELLIPSE";
    _areaMarkerId setMarkerBrushLocal _areaBrush;
    _areaMarkerId setMarkerColorLocal _markerColor;
    _areaMarkerId setMarkerSizeLocal [_radius, _radius];
    _areaMarkerId setMarkerAlphaLocal _areaAlpha;
};

[_iconMarkerId, _areaMarkerId, _impactMarkerIds, _radius, _duration, _alertType, _etaMin, _etaMax, _areaAlpha] spawn {
    params ["_iconMarkerId", "_areaMarkerId", "_impactMarkerIds", "_radius", "_duration", "_alertType", "_etaMin", "_etaMax", "_baseAreaAlpha"];

    private _steadyDuration = ((_duration * 0.6) max 5);
    private _steadyUntil = diag_tickTime + _steadyDuration;
    private _startTime = diag_tickTime;

    while {diag_tickTime < _steadyUntil} do {
        if ((toUpper _alertType) == "ARTILLERY_INCOMING" && {_etaMin >= 0}) then {
            private _elapsed = diag_tickTime - _startTime;
            private _etaMinLeft = ceil ((_etaMin - _elapsed) max 0);
            private _etaMaxLeft = ceil ((_etaMax - _elapsed) max 0);
            private _text = if (_etaMaxLeft > 0) then {
                if (_etaMaxLeft > _etaMinLeft) then {
                    format ["ARTY %1-%2s", _etaMinLeft, _etaMaxLeft]
                } else {
                    format ["ARTY %1s", _etaMaxLeft]
                };
            } else {
                "ARTY IMPACTS"
            };
            _iconMarkerId setMarkerTextLocal _text;
        };

        sleep 1;
    };

    for "_i" from 1 to 5 do {
        private _iconAlpha = 0.9 - (_i * 0.16);
        if (_iconAlpha < 0) then { _iconAlpha = 0; };
        _iconMarkerId setMarkerAlphaLocal _iconAlpha;

        if (_radius > 0) then {
            private _areaStep = ((_baseAreaAlpha / 6) max 0.01);
            private _areaAlpha = _baseAreaAlpha - (_i * _areaStep);
            if (_areaAlpha < 0) then { _areaAlpha = 0; };
            _areaMarkerId setMarkerAlphaLocal _areaAlpha;
        };

        {
            private _dotAlpha = 0.75 - (_i * 0.13);
            if (_dotAlpha < 0) then { _dotAlpha = 0; };
            _x setMarkerAlphaLocal _dotAlpha;
        } forEach _impactMarkerIds;

        sleep ((_duration * 0.08) max 1);
    };

    deleteMarkerLocal _iconMarkerId;
    if (_radius > 0) then {
        deleteMarkerLocal _areaMarkerId;
    };
    {
        deleteMarkerLocal _x;
    } forEach _impactMarkerIds;
};

true
