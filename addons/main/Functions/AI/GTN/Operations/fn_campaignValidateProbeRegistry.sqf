/* Validates current probe ownership against the formal operation registry. */
params [
    ["_fronts", createHashMap, [createHashMap]],
    ["_operations", createHashMap, [createHashMap]],
    ["_operationOrder", [], [[]]]
];

private _fail = {
    params ["_message"];
    ["CAMPAIGN", 1, _message] call FLO_fnc_log;
    throw _message;
};
private _committedGroups = createHashMap;

{
    private _probeId = _x;
    private _front = _y;
    [_probeId, _front] call FLO_fnc_campaignValidateProbeFrontState;
    {
        if (_x in _committedGroups) then {
            [format [
                "Probe fronts %1 and %2 both own committed group %3",
                _committedGroups get _x,
                _probeId,
                _x
            ]] call _fail;
        };
        _committedGroups set [_x, _probeId];
    } forEach (_front get "committedGroupIds");

    private _operationId = _front get "formalOperationId";
    if (_operationId == "") then { continue };
    if !(_operationId in _operations) then {
        [format ["Probe front %1 references missing operation %2", _probeId, _operationId]] call _fail;
    };
    private _operation = _operations get _operationId;
    if ((_operation get "phase") != "ASSAULT") then {
        [format ["Probe front %1 retains inactive operation %2", _probeId, _operationId]] call _fail;
    };
    if ((_front get "stage") != "ASSAULT") then {
        [format ["Probe front %1 attaches operation %2 from immature stage %3", _probeId, _operationId, _front get "stage"]] call _fail;
    };
    if (
        (_operation get "assaultCommittedTotal") <= 0
        || {(_operation get "assaultWaveSequence") <= 0}
    ) then {
        [format ["Probe front %1 attaches operation %2 without valid opening adoption", _probeId, _operationId]] call _fail;
    };
    if (
        (_operation get "attackerSideKey") != (_front get "sideKey")
        || {(_operation get "objectiveId") != (_front get "objectiveId")}
    ) then {
        [format ["Probe front %1 does not match operation %2 ownership", _probeId, _operationId]] call _fail;
    };
} forEach _fronts;

{
    private _operationId = _x;
    private _operation = _operations get _operationId;
    if ((_operation get "phase") != "ASSAULT") then { continue };
    private _probeId = [
        _operation get "attackerSideKey",
        _operation get "objectiveId"
    ] call FLO_fnc_campaignProbeId;
    if !(_probeId in _fronts) then {
        [format ["Active operation %1 has no canonical probe %2", _operationId, _probeId]] call _fail;
    };
    if (((_fronts get _probeId) get "formalOperationId") != _operationId) then {
        [format ["Active operation %1 does not own canonical probe %2", _operationId, _probeId]] call _fail;
    };
} forEach _operationOrder;

true
