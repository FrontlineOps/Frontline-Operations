/*
 * Function: FLO_fnc_updateObjectiveCaptureState
 * Author: Frontline Operations Development Group
 * Description:
 *   Updates one objective's capture state machine from maintained side counts.
 *   This does not flip ownership directly; it returns a requested owner flip
 *   when securing completes so FLO_fnc_flipObjective remains authoritative.
 *
 * Arguments:
 *   0: Objective ID <STRING>
 *   1: Objective data <HASHMAP>
 *   2: BLUFOR count <NUMBER>
 *   3: OPFOR count <NUMBER>
 *   4: Delta time <NUMBER>
 *   5: Current diag time <NUMBER>
 *   6: Capture time <NUMBER>
 *   7: Secure time <NUMBER>
 *   8: Minimum units to capture <NUMBER>
 *   9: Current date number <NUMBER>
 *
 * Return Value:
 *   HASHMAP
 */

params [
    ["_objectiveId", ""],
    ["_objective", createHashMap],
    ["_bluforCount", 0],
    ["_opforCount", 0],
    ["_deltaTime", 0],
    ["_currentTime", 0],
    ["_captureTime", 20],
    ["_secureTime", 90],
    ["_minUnitsToCapture", 1],
    ["_nowDateNum", 0]
];

private _owner = _objective get "owner";

if (isNil {_objective get "captureState"}) then { _objective set ["captureState", "held"]; };
if (isNil {_objective get "captureSide"}) then { _objective set ["captureSide", sideUnknown]; };
if (isNil {_objective get "captureSecureStartedAt"}) then { _objective set ["captureSecureStartedAt", -1]; };
if (isNil {_objective get "captureSecureProgress"}) then { _objective set ["captureSecureProgress", 0]; };
if (isNil {_objective get "captureStatusChangedAt"}) then { _objective set ["captureStatusChangedAt", _currentTime]; };
if (isNil {_objective get "captureIntegratedAtDateNum"}) then { _objective set ["captureIntegratedAtDateNum", -1]; };

private _previousProgress = _objective get "captureProgress";
private _previousState = _objective get "captureState";
private _previousCaptureSide = _objective get "captureSide";
private _previousSecureStartedAt = _objective get "captureSecureStartedAt";
private _previousSecureProgress = _objective get "captureSecureProgress";

private _progress = _previousProgress;
private _secureStartedAt = _previousSecureStartedAt;
private _secureProgress = 0;
private _captureSide = sideUnknown;
private _state = "held";
private _requestedOwner = sideUnknown;

private _diff = abs (_bluforCount - _opforCount);
private _dynamicRate = (1.0 + (_diff * 0.5)) min 5.0;

private _westDominates = _bluforCount > _opforCount && {_bluforCount >= _minUnitsToCapture} && {!(_owner isEqualTo west)};
private _eastDominates = _opforCount > _bluforCount && {_opforCount >= _minUnitsToCapture} && {!(_owner isEqualTo east)};
private _attacker = sideUnknown;

if (_westDominates) then { _attacker = west; };
if (_eastDominates) then { _attacker = east; };

if (_attacker isEqualTo west) then {
    _progress = (_progress + (_deltaTime * _dynamicRate)) min _captureTime;
} else {
    if (_attacker isEqualTo east) then {
        _progress = (_progress - (_deltaTime * _dynamicRate)) max (-_captureTime);
    } else {
        if (_progress > 0) then { _progress = (_progress - (_deltaTime * 0.5)) max 0 };
        if (_progress < 0) then { _progress = (_progress + (_deltaTime * 0.5)) min 0 };
    };
};

if (_attacker isEqualTo sideUnknown) then {
    _secureStartedAt = -1;
    _secureProgress = 0;

    if (_bluforCount > 0 && {_opforCount > 0}) then {
        _state = "contested";
    } else {
        private _integratedAt = _objective get "captureIntegratedAtDateNum";
        if (_integratedAt > 0) then {
            _state = if (_nowDateNum < _integratedAt) then { "integrating" } else { "integrated" };
        } else {
            _state = if ((_objective get "capturedAtDateNum") >= 0) then { "integrated" } else { "held" };
        };
    };
} else {
    _captureSide = _attacker;
    private _attackerCount = if (_attacker isEqualTo west) then { _bluforCount } else { _opforCount };
    private _defenderCount = if (_attacker isEqualTo west) then { _opforCount } else { _bluforCount };
    private _thresholdReached = if (_attacker isEqualTo west) then {
        _progress >= _captureTime
    } else {
        _progress <= (-_captureTime)
    };

    if (_defenderCount > 0) then {
        _state = if (_attackerCount > _defenderCount) then { "clearing" } else { "contested" };
        _secureStartedAt = -1;
        _secureProgress = 0;
    } else {
        if (_thresholdReached) then {
            _state = "securing";

            if (
                _previousState != "securing"
                || {!(_previousCaptureSide isEqualTo _attacker)}
                || {_secureStartedAt < 0}
            ) then {
                _secureStartedAt = _currentTime;
            };

            _secureProgress = ((_currentTime - _secureStartedAt) / (_secureTime max 1)) min 1;
            if (_secureProgress >= 1) then {
                _requestedOwner = _attacker;
            };
        } else {
            _state = "clearing";
            _secureStartedAt = -1;
            _secureProgress = 0;
        };
    };
};

private _stateChanged = _state != _previousState || {!(_captureSide isEqualTo _previousCaptureSide)};
if (_stateChanged) then {
    _objective set ["captureStatusChangedAt", _currentTime];
};

_objective set ["captureProgress", _progress];
_objective set ["captureState", _state];
_objective set ["captureSide", _captureSide];
_objective set ["captureSecureStartedAt", _secureStartedAt];
_objective set ["captureSecureProgress", _secureProgress];
_objective set ["captureTime", _captureTime];
_objective set ["captureSecureTime", _secureTime];

createHashMapFromArray [
    ["requestedOwner", _requestedOwner],
    ["stateChanged", _stateChanged],
    ["progressChanged", (abs (_previousProgress - _progress)) > 0.01],
    ["secureChanged", (abs (_previousSecureProgress - _secureProgress)) > 0.01],
    ["state", _state]
]
