if (!hasInterface) exitWith { false };

private _control = uiNamespace getVariable ["FLO_SupportControl", controlNull];
if (isNull _control) exitWith { false };
if ((keys FLO_SupportLastServerSnapshot) isEqualTo []) exitWith { false };

private _hasTarget = FLO_SupportTargetPosition isNotEqualTo [];
private _targetGrid = "------";
private _targetPosition = [];
if (_hasTarget) then {
    _targetGrid = mapGridPosition FLO_SupportTargetPosition;
    _targetPosition = +FLO_SupportTargetPosition;
};
private _serverSnapshot = FLO_SupportLastServerSnapshot;

private _snapshot = createHashMapFromArray [
    ["generatedAt", _serverSnapshot get "generatedAt"],
    ["sideName", _serverSnapshot get "sideName"],
    ["selectedType", FLO_SupportSelectedType],
    ["hasTarget", _hasTarget],
    ["targetGrid", _targetGrid],
    ["targetPosition", _targetPosition],
    ["available", _serverSnapshot get "available"],
    ["balance", _serverSnapshot get "balance"],
    ["committed", _serverSnapshot get "committed"],
    ["assets", _serverSnapshot get "assets"],
    ["packages", _serverSnapshot get "packages"]
];

private _script = format [
    "if (window.FLOSupport) { window.FLOSupport.applySnapshot(%1); }",
    toJSON _snapshot
];
[_control, ["ExecJS", _script]] call FLO_fnc_supportWebAction;
true
