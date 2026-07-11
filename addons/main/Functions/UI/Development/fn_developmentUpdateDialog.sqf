params ["_snapshot"];

if (!hasInterface || {!FLO_DevelopmentBrowserReady}) exitWith {};

private _control = uiNamespace getVariable ["FLO_DevelopmentControl", controlNull];
if (isNull _control) exitWith {};

private _script = format [
    "if (window.FLODevelopment) { window.FLODevelopment.applySnapshot(%1); }",
    toJSON _snapshot
];
_control ctrlWebBrowserAction ["ExecJS", _script];
