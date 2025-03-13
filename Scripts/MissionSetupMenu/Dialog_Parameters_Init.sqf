/*
    File: Dialog_Parameters_Init.sqf
    Author: [Your Name]
    Description:
    Initializes the parameters dialog with current parameter values
*/

// Wait for dialog to be created
(findDisplay 46) createDisplay "parameters_dialog";
waitUntil {!isNull findDisplay 998};

// Get the controls
private _autoSaveSwitchCtrl = (findDisplay 998) displayCtrl 1970;
private _autoSaveIntervalCtrl = (findDisplay 998) displayCtrl 1971;
private _missionSaveCtrl = (findDisplay 998) displayCtrl 1972;
private _restrictedArsenalCtrl = (findDisplay 998) displayCtrl 1973;

// Clear existing items
lbClear _autoSaveSwitchCtrl;
lbClear _autoSaveIntervalCtrl;
lbClear _missionSaveCtrl;
lbClear _restrictedArsenalCtrl;

// Add items to AutoSave Switch dropdown
_autoSaveSwitchCtrl lbAdd "Activate";
_autoSaveSwitchCtrl lbAdd "DeActivate";

// Add items to AutoSave Interval dropdown
_autoSaveIntervalCtrl lbAdd "5 Minutes";
_autoSaveIntervalCtrl lbAdd "10 Minutes";
_autoSaveIntervalCtrl lbAdd "20 Minutes";

// Add items to Mission Save Management dropdown
_missionSaveCtrl lbAdd "Load Mission Progress";
_missionSaveCtrl lbAdd "Reset Mission Progress";

// Add items to Restricted Arsenal dropdown
_restrictedArsenalCtrl lbAdd "Enable";
_restrictedArsenalCtrl lbAdd "Disable";

// Get current parameter values
private _autoSaveSwitch = missionNamespace getVariable ["FLO_AutoSaveSwitch", paramsArray select 0];
private _autoSaveInterval = missionNamespace getVariable ["FLO_AutoSaveInterval", paramsArray select 1];
private _missionSave = missionNamespace getVariable ["FLO_FreshStart", paramsArray select 2];
private _restrictedArsenal = missionNamespace getVariable ["FLO_RestrictedArsenal", paramsArray select 3];

// Set the current selection based on parameter values
switch (_autoSaveSwitch) do {
    case 1: { _autoSaveSwitchCtrl lbSetCurSel 0; }; // Activate
    case 0: { _autoSaveSwitchCtrl lbSetCurSel 1; }; // DeActivate
    default { _autoSaveSwitchCtrl lbSetCurSel 0; }; // Default to Activate
};

switch (_autoSaveInterval) do {
    case 300: { _autoSaveIntervalCtrl lbSetCurSel 0; }; // 5 Minutes
    case 600: { _autoSaveIntervalCtrl lbSetCurSel 1; }; // 10 Minutes
    case 1200: { _autoSaveIntervalCtrl lbSetCurSel 2; }; // 20 Minutes
    default { _autoSaveIntervalCtrl lbSetCurSel 0; }; // Default to 5 Minutes
};

switch (_missionSave) do {
    case 0: { _missionSaveCtrl lbSetCurSel 0; }; // Load Mission Progress
    case 1: { _missionSaveCtrl lbSetCurSel 1; }; // Reset Mission Progress
    default { _missionSaveCtrl lbSetCurSel 0; }; // Default to Load Mission Progress
};

switch (_restrictedArsenal) do {
    case 0: { _restrictedArsenalCtrl lbSetCurSel 0; }; // Enable
    case 1: { _restrictedArsenalCtrl lbSetCurSel 1; }; // Disable
    default { _restrictedArsenalCtrl lbSetCurSel 0; }; // Default to Enable
}; 