if (!hasInterface) exitWith { false };

FLO_OperationsGuideRequested = true;

private _control = uiNamespace getVariable ["FLO_OperationsControl", controlNull];
if (isNull _control || {!FLO_OperationsBrowserReady}) exitWith { true };

private _script = "if (window.FLOOperations) { window.FLOOperations.openGuide(); }";
[_control, ["ExecJS", _script]] call FLO_fnc_operationsWebAction;
FLO_OperationsGuideRequested = false;

true
