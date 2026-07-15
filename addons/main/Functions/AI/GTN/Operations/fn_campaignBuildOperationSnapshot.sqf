/* Builds the compact side-filtered operation descriptor used by Command Net. */
params [
    ["_operation", createHashMap, [createHashMap]],
    ["_viewerSideKey", "", [""]],
    ["_isPrimary", false, [false]]
];

private _operationId = _operation get "operationId";
private _objectiveId = _operation get "objectiveId";
private _viewerIsAttacker = (_operation get "attackerSideKey") == _viewerSideKey;
private _role = _operation get "priorityRole";
if (!_viewerIsAttacker) then {
    _role = ["DEFEND_SUPPORTING_EFFORT", "DEFEND_MAIN_EFFORT"] select _isPrimary;
};

createHashMapFromArray [
    ["id", _operationId],
    ["isPrimary", _isPrimary],
    ["role", _role],
    ["phase", _operation get "phase"],
    ["targetVisible", true],
    ["targetId", _objectiveId],
    ["targetName", [_objectiveId] call FLO_fnc_campaignObjectiveName],
    ["threatSector", createHashMapFromArray [
        ["operationId", _operationId],
        ["visible", false],
        ["position", []],
        ["longAxis", 0],
        ["shortAxis", 0],
        ["direction", 0],
        ["grid", ""],
        ["label", ""]
    ]],
    ["doctrine", ["CLASSIFIED", _operation get "doctrine"] select _viewerIsAttacker]
]
