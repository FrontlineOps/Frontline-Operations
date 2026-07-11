/*
 * Function: FLO_fnc_operationsSelectObjective
 * Description:
 *   Validates and publishes objective selection to the Operations browser.
 */

params [
    ["_objectiveId", "", [""]],
    ["_focus", false, [false]]
];

if (_objectiveId == "") exitWith { false };
if !(_objectiveId in (FLO_OperationsMapDrawData apply { _x select 0 })) exitWith { false };

FLO_OperationsSelectedObjectiveId = _objectiveId;

if (FLO_OperationsBrowserReady) then {
    private _control = uiNamespace getVariable ["FLO_OperationsControl", controlNull];
    if (!isNull _control) then {
        private _script = format [
            "if (window.FLOOperations) { window.FLOOperations.selectObjective(%1); }",
            toJSON _objectiveId
        ];
        [_control, ["ExecJS", _script]] call FLO_fnc_operationsWebAction;
    };
};

if (_focus) then {
    ["OBJECTIVE", _objectiveId] call FLO_fnc_operationsFocusMap;
};

true
