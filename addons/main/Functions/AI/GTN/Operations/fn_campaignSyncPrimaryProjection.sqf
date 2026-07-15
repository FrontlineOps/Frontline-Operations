/* Validates the registry and projects its primary operation onto the campaign read model. */
params ["_state"];

private _operations = _state get "operations";
private _order = _state get "operationOrder";
private _operationIds = keys _operations;

if ((count (_order arrayIntersect _order)) != (count _order)) then {
    throw format ["Campaign operation order contains duplicate IDs: %1", _order];
};
if ((count _operationIds) != (count _order)) then {
    throw format ["Campaign operation registry/order count mismatch: %1 vs %2", count _operationIds, count _order];
};
{
    if !(_x in _operations) then {
        throw format ["Campaign operation order references missing operation %1", _x];
    };
} forEach _order;
{
    if !(_x in _order) then {
        throw format ["Campaign operation registry contains unordered operation %1", _x];
    };
} forEach _operationIds;

private _activeOrder = _order select { ((_operations get _x) get "phase") != "RECOVERY" };
if (_activeOrder isNotEqualTo []) then {
    private _recoveryOrder = _order select { ((_operations get _x) get "phase") == "RECOVERY" };
    _order = _activeOrder + _recoveryOrder;
    _state set ["operationOrder", _order];
};

if (_order isEqualTo []) exitWith {
    _state set ["primaryOperationId", ""];
    _state set ["operationId", ""];
    _state set ["attackerSideKey", _state get "initiativeSideKey"];
    _state set ["objectiveId", ""];
    _state set ["sourceObjectiveIds", []];
    _state set ["supportObjectiveIds", []];
    _state set ["result", ""];
    _state set ["defenderIntelLevel", "NONE"];
    _state set ["defenderIntelReason", "NO_ACTIVE_OPERATION"];
    _state set ["resourceReservationId", ""];
    _state set ["resourceBudget", 0];
    _state set ["resourceSpent", 0];
    _state set ["resourceReleased", 0];
    _state
};

private _primaryOperationId = _order select 0;
{
    private _operation = _operations get _x;
    if ((_operation get "operationId") != _x) then {
        throw format ["Campaign operation key/id mismatch: %1 vs %2", _x, _operation get "operationId"];
    };
    private _isPrimary = _x == _primaryOperationId;
    _operation set ["priorityRole", ["SUPPORTING_EFFORT", "MAIN_EFFORT"] select _isPrimary];
    if (_isPrimary) then { _operation set ["drawdownPending", false]; };
} forEach _order;

private _primary = _operations get _primaryOperationId;
_state set ["primaryOperationId", _primaryOperationId];
_state set ["operationId", _primaryOperationId];
_state set ["phase", _primary get "phase"];
_state set ["phaseStartedAtDateNum", _primary get "phaseStartedAtDateNum"];
_state set ["phaseEndsAtDateNum", _primary get "phaseEndsAtDateNum"];
_state set ["attackerSideKey", _primary get "attackerSideKey"];
_state set ["defenderSideKey", _primary get "defenderSideKey"];
_state set ["objectiveId", _primary get "objectiveId"];
_state set ["sourceObjectiveIds", +(_primary get "sourceObjectiveIds")];
_state set ["supportObjectiveIds", +(_primary get "supportObjectiveIds")];
_state set ["result", _primary get "result"];
_state set ["transitionReason", _primary get "transitionReason"];
_state set ["defenderIntelLevel", _primary get "defenderIntelLevel"];
_state set ["defenderIntelReason", _primary get "defenderIntelReason"];
_state set ["resourceReservationId", _primary get "resourceReservationId"];
_state set ["resourceBudget", _primary get "resourceBudget"];
_state set ["resourceSpent", _primary get "resourceSpent"];
_state set ["resourceReleased", _primary get "resourceReleased"];
_state
