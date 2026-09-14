if (!hasInterface) exitWith {};

private _control = uiNamespace getVariable ["FLO_DeployControl", controlNull];
if (isNull _control) exitWith {};
if (!FLO_BaseDeployBrowserReady) exitWith {};

private _snapshot = [] call FLO_fnc_baseDeployBuildSnapshot;
private _renderKey = toJSON _snapshot;

if (FLO_BaseDeployRenderKey isEqualTo _renderKey) exitWith {};
FLO_BaseDeployRenderKey = _renderKey;

private _script = format [
    "if (window.FLODeploy) { window.FLODeploy.applySnapshot(%1); }",
    _renderKey
];

[_control, ["ExecJS", _script]] call FLO_fnc_uiWebAction;
