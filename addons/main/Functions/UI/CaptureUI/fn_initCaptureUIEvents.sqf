/* Registers persistent Capture UI client events exactly once. */
if (!hasInterface) exitWith { false };
if (FLO_CaptureUI_EventsInit) exitWith { true };

FLO_CaptureUI_Layer = "FLO_CaptureUI" call BIS_fnc_rscLayer;

["FLO_CaptureUI_Show", {
    params ["_objectiveName", "_objectiveId"];

    FLO_CaptureUI_CurrentName = _objectiveName;
    FLO_CaptureUI_CurrentObj = _objectiveId;
    [] call FLO_fnc_captureUIOpen;
}] call CBA_fnc_addEventHandler;

["FLO_CaptureUI_Hide", {
    if (FLO_CaptureUI_DisplayOpen && {FLO_CaptureUI_HTMLReady}) then {
        private _display = uiNamespace getVariable ["FLO_CaptureUI_Display", displayNull];
        if (!isNull _display) then {
            private _control = _display displayCtrl 1101;
            if (!isNull _control) then {
                _control ctrlWebBrowserAction ["ExecJS", "if (window.FLOCapture) { window.FLOCapture.hide(); }"];
            };
        };
    };

    FLO_CaptureUI_CurrentObj = "";
    FLO_CaptureUI_CurrentName = "";
    FLO_CaptureUI_LatestUpdate = createHashMap;
    FLO_CaptureUI_DisplayOpen = false;
    FLO_CaptureUI_HTMLReady = false;
    FLO_CaptureUI_Layer cutFadeOut 0.2;
}] call CBA_fnc_addEventHandler;

["FLO_CaptureUI_Update", {
    params [
        "_objectiveId",
        "_ratio",
        "_friendlyCount",
        "_enemyCount",
        "_ownership",
        "_friendlySide",
        "_captureState",
        "_secureProgress",
        "_captureProgress"
    ];

    FLO_CaptureUI_LatestUpdate = createHashMapFromArray [
        ["objectiveId", _objectiveId],
        ["ratio", _ratio],
        ["friendlyCount", _friendlyCount],
        ["enemyCount", _enemyCount],
        ["ownership", _ownership],
        ["friendlySide", _friendlySide],
        ["captureState", _captureState],
        ["secureProgress", _secureProgress],
        ["captureProgress", _captureProgress]
    ];

    if (_objectiveId == FLO_CaptureUI_CurrentObj) then {
        [] call FLO_fnc_captureUIOpen;
    };
}] call CBA_fnc_addEventHandler;

["FLO_ClientUIReady", {
    [] call FLO_fnc_captureUIRequestState;
}] call CBA_fnc_addEventHandler;

FLO_CaptureUI_PlayerEventHandler = ["unit", {
    params ["_newUnit", "_oldUnit"];
    if (isNull _newUnit) exitWith {};
    [FLO_fnc_captureUIRequestState, []] call CBA_fnc_execNextFrame;
}] call CBA_fnc_addPlayerEventHandler;

FLO_CaptureUI_EventsInit = true;
["UI", 4, "Capture UI events, browser readiness, and player lifecycle replay initialized"] call FLO_fnc_log;
true
