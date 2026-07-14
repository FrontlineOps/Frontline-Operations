/* Runs the single paced formation readiness and role worker. */
if (!isServer || {!FLO_MissionReady}) exitWith { false };
if (isNil "FLO_FormationState") then { throw "Formation update ran before initialization"; };

private _updateStartedAt = diag_tickTime;
private _state = FLO_FormationState;
private _reconcileStartedAt = diag_tickTime;
if (FLO_FormationReconcileDirty) then {
    [_state] call FLO_fnc_formationReconcile;
    FLO_FormationReconcileDirty = false;
};
private _reconcileMs = (diag_tickTime - _reconcileStartedAt) * 1000;

private _readinessStartedAt = diag_tickTime;
private _now = call FLO_fnc_operationalDateNumber;
private _lastUpdate = _state get "lastReadinessUpdateAtDateNum";
private _elapsedSeconds = 30;
if (_lastUpdate >= 0) then {
    _elapsedSeconds = (([_lastUpdate, _now] call FLO_fnc_dateNumberDeltaSeconds) max 0) min 120;
};
private _elapsedMinutes = _elapsedSeconds / 60;
private _groups = call FLO_fnc_virtualizationGetGroupMap;
private _readinessChanged = false;
private _formationCount = 0;
private _memberCount = 0;
private _skillGroupCount = 0;
private _supplyRoutesBySide = createHashMap;
{
    private _formation = _y;
    private _memberIds = (_formation get "memberIds") select { _x in _groups };
    if (_memberIds isEqualTo []) then { continue };
    _formationCount = _formationCount + 1;
    _memberCount = _memberCount + count _memberIds;
    private _strength = 0;
    { _strength = _strength + ((_groups get _x) get "unitCount"); } forEach _memberIds;
    private _previousStrength = _formation get "lastStrength";
    private _role = _formation get "role";
    private _ratePerMinute = switch (_role) do {
        case "MAIN": { -1.20 };
        case "FEINT": { -0.90 };
        case "FEINT_RETURN": { -0.40 };
        case "EXPLOIT": { -1.50 };
        case "WITHDRAW": { -0.50 };
        case "RECOVERY": { 1.25 };
        default { 0.50 };
    };
    if (_role == "RESERVE") then {
        private _homeObjectiveId = _formation get "homeObjectiveId";
        private _sideKey = _formation get "sideKey";
        if !(_sideKey in _supplyRoutesBySide) then {
            private _network = FLO_Logistics_Networks get _sideKey;
            [_network] call FLO_fnc_logisticsNetworkEnsureSupplyChainFresh;
            _supplyRoutesBySide set [_sideKey, _network get "_supplyRouteInfo"];
        };
        if (_homeObjectiveId in (_supplyRoutesBySide get _sideKey)) then { _ratePerMinute = 1.50; };
    };
    private _lossDrain = 0;
    if (_previousStrength > 0 && {_strength < _previousStrength}) then {
        _lossDrain = ((_previousStrength - _strength) / _previousStrength) * 10;
    };
    private _oldReadiness = _formation get "readiness";
    private _newReadiness = ((_oldReadiness + (_ratePerMinute * _elapsedMinutes) - _lossDrain) max 0) min 100;
    _formation set ["readiness", _newReadiness];
    _formation set ["lastStrength", _strength];
    if (abs (_newReadiness - _oldReadiness) >= 0.25) then {
        _readinessChanged = true;
        {
            private _groupData = _groups get _x;
            if (_groupData get "isActive") then {
                [_x, _groupData get "realGroup"] call FLO_fnc_formationApplyRealGroupSkills;
                _skillGroupCount = _skillGroupCount + 1;
            };
        } forEach _memberIds;
    };
} forEach (_state get "formations");
_state set ["lastReadinessUpdateAtDateNum", _now];
if (_readinessChanged) then { _state set ["revision", (_state get "revision") + 1]; };
private _readinessMs = (diag_tickTime - _readinessStartedAt) * 1000;

private _rolesStartedAt = diag_tickTime;
[_state, FLO_FormationDirector] call FLO_fnc_formationProcessRoles;
private _rolesMs = (diag_tickTime - _rolesStartedAt) * 1000;
private _withdrawStartedAt = diag_tickTime;
[_state, "WEST"] call FLO_fnc_formationEvaluateSalientWithdrawal;
[_state, "EAST"] call FLO_fnc_formationEvaluateSalientWithdrawal;
private _withdrawMs = (diag_tickTime - _withdrawStartedAt) * 1000;
private _validateStartedAt = diag_tickTime;
[_state] call FLO_fnc_formationValidateState;
private _validateMs = (diag_tickTime - _validateStartedAt) * 1000;
private _totalMs = (diag_tickTime - _updateStartedAt) * 1000;
if (_totalMs >= 5) then {
    diag_log format [
        "[FLO][PERF] Formation update total=%1ms formations=%2 members=%3 skills=%4 | reconcile=%5 readiness=%6 roles=%7 withdraw=%8 validate=%9",
        _totalMs,
        _formationCount,
        _memberCount,
        _skillGroupCount,
        _reconcileMs,
        _readinessMs,
        _rolesMs,
        _withdrawMs,
        _validateMs
    ];
};
true
