params ["_success", "_message"];

if (!hasInterface) exitWith {};

if (isMultiplayer && {remoteExecutedOwner isNotEqualTo 2} && {remoteExecutedOwner isNotEqualTo 0}) exitWith {
    ["UI", 2, format ["Rejected Deployment result from owner %1", remoteExecutedOwner]] call FLO_fnc_log;
};

[_message, ["warning", "success"] select _success] call FLO_fnc_displayNotification;

private _control = uiNamespace getVariable ["FLO_DeployControl", controlNull];

if (!isNull _control) then {
    private _payload = createHashMapFromArray [
        ["success", _success],
        ["message", _message]
    ];
    private _script = format [
        "if (window.FOOFDeploy) { window.FOOFDeploy.receiveResult(%1); }",
        toJSON _payload
    ];

    [_control, ["ExecJS", _script]] call FLO_fnc_baseDeployWebAction;

    FLO_BaseDeployRenderKey = "";
    [] call FLO_fnc_baseDeployUpdateDialog;
};
