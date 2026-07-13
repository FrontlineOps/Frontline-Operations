if (!hasInterface) exitWith { false };

FLO_OperationsGuideRequested = true;

private _control = uiNamespace getVariable ["FLO_OperationsControl", controlNull];
if (isNull _control || {!FLO_OperationsBrowserReady}) exitWith { true };

private _onboarding = ["false", "true"] select FLO_OperationsGuideIsOnboarding;
private _script = format ["if (window.FLOOperations) { window.FLOOperations.openGuide(%1); }", _onboarding];
[_control, ["ExecJS", _script]] call FLO_fnc_operationsWebAction;
FLO_OperationsGuideRequested = false;
FLO_OperationsGuideIsOnboarding = false;

true
