/* Returns [reservation ID, operation scoped, operation ID] for a target. */
params [
    ["_side", sideUnknown, [east]],
    ["_objectiveId", "", [""]]
];

if (isNil "FLO_CampaignDirector") exitWith { ["", false, ""] };
private _state = FLO_CampaignDirector get "_state";
private _operations = _state get "operations";
private _sideKey = ([_side] call FLO_fnc_gtnSideContext) get "sideKey";
private _exactOperationId = "";

{
    private _operationId = _x;
    private _operation = _operations get _operationId;
    if ((_operation get "attackerSideKey") != _sideKey) then { continue };
    if !((_operation get "phase") in ["ASSAULT", "SECURE", "CONSOLIDATE"]) then { continue };

    if ((_operation get "objectiveId") == _objectiveId) exitWith {
        _exactOperationId = _operationId;
    };
} forEach (_state get "operationOrder");

private _operationId = _exactOperationId;
if (_operationId == "") exitWith { ["", false, ""] };
private _operation = _operations get _operationId;
[_operation get "resourceReservationId", true, _operationId]
