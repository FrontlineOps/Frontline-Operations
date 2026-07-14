/* Renders the latest objective name and matching authoritative Capture state. */
if (!hasInterface || {!FLO_CaptureUI_DisplayOpen} || {!FLO_CaptureUI_HTMLReady}) exitWith { false };
if (FLO_CaptureUI_CurrentObj == "") exitWith { false };

private _display = uiNamespace getVariable ["FLO_CaptureUI_Display", displayNull];
if (isNull _display) then {
    private _message = "Capture UI is marked ready without a display";
    ["UI", 1, _message] call FLO_fnc_log;
    throw _message;
};

private _control = _display displayCtrl 1101;
if (isNull _control) then {
    private _message = "Capture UI is marked ready without browser control 1101";
    ["UI", 1, _message] call FLO_fnc_log;
    throw _message;
};

private _script = format [
    "if (window.FLOCapture) { window.FLOCapture.show(%1);",
    toJSON FLO_CaptureUI_CurrentName
];

if ((keys FLO_CaptureUI_LatestUpdate) isNotEqualTo []
    && {(FLO_CaptureUI_LatestUpdate get "objectiveId") == FLO_CaptureUI_CurrentObj}) then {
    _script = _script + format [
        "window.FLOCapture.applyState(%1);",
        toJSON FLO_CaptureUI_LatestUpdate
    ];
};

_script = _script + "}";
_control ctrlWebBrowserAction ["ExecJS", _script];
true
