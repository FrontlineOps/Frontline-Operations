params ["_snapshot"];

if (!hasInterface || {!FLO_OperationsBrowserReady}) exitWith {};

private _control = uiNamespace getVariable ["FLO_OperationsControl", controlNull];
if (isNull _control) exitWith {};

private _script = format [
    "if (window.FLOOperations) { window.FLOOperations.applySnapshot(%1); }",
    toJSON _snapshot
];

[_control, ["ExecJS", _script]] call FLO_fnc_operationsWebAction;
