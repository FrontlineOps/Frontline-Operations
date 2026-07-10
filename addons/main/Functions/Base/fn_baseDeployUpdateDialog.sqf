if (!hasInterface) exitWith {};

private _control = uiNamespace getVariable ["FLO_DeployControl", controlNull];
if (isNull _control) exitWith {};
if (!FLO_BaseDeployBrowserReady) exitWith {};

private _snapshot = [] call FLO_fnc_baseDeployBuildSnapshot;
private _renderKey = format [
    "%1|%2|%3|%4|%5|%6|%7|%8|%9",
    _snapshot get "sideKey",
    _snapshot get "grid",
    _snapshot get "alive",
    _snapshot get "onWater",
    _snapshot get "hasAuthority",
    _snapshot get "balance",
    _snapshot get "factionName",
    _snapshot get "fobCost",
    _snapshot get "firstFOBFree"
];

if (FLO_BaseDeployRenderKey isEqualTo _renderKey) exitWith {};
FLO_BaseDeployRenderKey = _renderKey;

private _script = format [
    "if (window.FOOFDeploy) { window.FOOFDeploy.applySnapshot(%1); }",
    toJSON _snapshot
];

[_control, ["ExecJS", _script]] call FLO_fnc_baseDeployWebAction;
