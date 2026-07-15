/* Owns the scheduled siege lifecycle shared by FOBs and COPs. */
params [
    ["_base", objNull, [objNull]],
    ["_config", createHashMap, [createHashMap]]
];

if (!isServer) exitWith {};
if (isNull _base) then {
    ["BASE", 1, "Cannot start siege monitor for a null base"] call FLO_fnc_log;
    throw "FLO_fnc_baseMonitorSiege requires a base object";
};
if (isNil { _base getVariable "FLO_BaseSide" }) then {
    ["BASE", 1, format ["Base %1 has no FLO_BaseSide", _base]] call FLO_fnc_log;
    throw "FLO_fnc_baseMonitorSiege requires FLO_BaseSide";
};

private _baseSide = _base getVariable "FLO_BaseSide";
if !(_baseSide in [west, east]) then {
    ["BASE", 1, format ["Base %1 has invalid FLO_BaseSide %2", _base, _baseSide]] call FLO_fnc_log;
    throw "FLO_fnc_baseMonitorSiege received an invalid base side";
};

private _label = _config get "siegeLabel";
private _maxHoldTime = _config get "holdoutTime";
private _areaRadius = _config get "holdoutRadius";
private _cleanupRadius = _config get "cleanupRadius";
private _cleanupObjectTypes = _config get "cleanupObjectTypes";
private _markerVariable = _config get "markerVariable";
private _markerSize = _config get "siegeMarkerSize";
private _checkInterval = 5;
private _notificationInterval = 60;
private _holdoutTime = 0;
private _lastNotification = -1e12;
private _statusMarker = "";
private _lost = false;

["BASE", 3, format ["%1 siege monitor started for %2", _label, _baseSide]] call FLO_fnc_log;

while {alive _base && {!_lost}} do {
    private _counts = [_base, _areaRadius, _baseSide] call FLO_fnc_baseCountSiegeForces;
    _counts params ["_friendlyCount", "_enemyCount"];

    if (_enemyCount > _friendlyCount && {_enemyCount > 0}) then {
        if (_statusMarker == "") then {
            _statusMarker = createMarker [format ["FLO_%1_Siege_%2", _label, floor random 1e9], getPos _base];
            _statusMarker setMarkerShapeLocal "ICON";
            _statusMarker setMarkerTypeLocal "mil_objective";
            _statusMarker setMarkerColorLocal "ColorRed";
            _statusMarker setMarkerSize _markerSize;
            ["BASE", 3, format ["%1 siege started: side=%2 friendly=%3 enemy=%4", _label, _baseSide, _friendlyCount, _enemyCount]] call FLO_fnc_log;
        };

        _holdoutTime = _holdoutTime + _checkInterval;
        private _timeLeft = (_maxHoldTime - _holdoutTime) max 0;
        private _minutes = floor (_timeLeft / 60);
        private _seconds = _timeLeft mod 60;
        _statusMarker setMarkerPosLocal (getPos _base);
        _statusMarker setMarkerText format ["%1 UNDER SIEGE: %2:%3", _label, _minutes, [_seconds, 2] call CBA_fnc_formatNumber];

        if ((diag_tickTime - _lastNotification) >= _notificationInterval) then {
            [format ["%1 under siege! %2 minutes remaining", _label, ceil (_timeLeft / 60)], "warning", false, 0] call FLO_fnc_sendNotification;
            _lastNotification = diag_tickTime;
        };

        if (_holdoutTime >= _maxHoldTime) then { _lost = true };
    } else {
        if (_statusMarker != "") then {
            deleteMarker _statusMarker;
            _statusMarker = "";
            if (_holdoutTime > 0) then {
                [format ["%1 defense successful! Timer reset.", _label], "success", false, 0] call FLO_fnc_sendNotification;
                ["BASE", 3, format ["%1 siege ended after successful defense", _label]] call FLO_fnc_log;
            };
        };
        _holdoutTime = 0;
    };

    if (!_lost) then { sleep _checkInterval };
};

if (_lost) then {
    if (_statusMarker != "") then {
        _statusMarker setMarkerTextLocal format ["%1 LOST!", _label];
        _statusMarker setMarkerColor "ColorBlack";
    };
    [format ["%1 has fallen to enemy forces!", _label], "error", false, 0] call FLO_fnc_sendNotification;
    ["BASE", 2, format ["%1 lost after %2-second siege", _label, _maxHoldTime]] call FLO_fnc_log;

    { deleteVehicle _x } forEach (nearestObjects [_base, _cleanupObjectTypes, _cleanupRadius]);

    private _markerName = _base getVariable [_markerVariable, ""];
    if (_markerName != "") then { deleteMarker _markerName };

    private _nearbyTriggers = (allMissionObjects "EmptyDetector") select {
        position _x distance _base < _cleanupRadius
    };
    { deleteVehicle _x } forEach _nearbyTriggers;

    if (!isNull _base) then { _base setDamage 1 };
};

if (_statusMarker != "") then { deleteMarker _statusMarker };
["BASE", 3, format ["%1 siege monitor ended", _label]] call FLO_fnc_log;
