/* Returns [reservation ID, operation scoped] for a reinforcement request. */
params [
    ["_side", sideUnknown, [east]],
    ["_objectiveId", "", [""]]
];

if (isNil "FLO_CampaignDirector") exitWith { ["", false] };
private _state = FLO_CampaignDirector get "_state";
if !((_state get "phase") in ["PREPARE", "ASSAULT", "SECURE", "CONSOLIDATE"]) exitWith { ["", false] };

private _sideKey = ([_side] call FLO_fnc_gtnSideContext) get "sideKey";
if ((_state get "attackerSideKey") != _sideKey) exitWith { ["", false] };

private _operationObjectives = +(_state get "sourceObjectiveIds");
_operationObjectives append (_state get "supportObjectiveIds");
_operationObjectives pushBackUnique (_state get "objectiveId");
if !(_objectiveId in _operationObjectives) exitWith { ["", false] };

[_state get "resourceReservationId", true]
