/*
 * Author: IDSolutions
 * Open notification interface.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call IDS_Notifications_fnc_openUI;
 *
 * Public: No
 */

private _display = uiNamespace getVariable ["RscNotifications", nil];
private _ctrl =  _display displayCtrl 1002;

private _event = "JSDialog";
_ctrl ctrlAddEventHandler [_event, {
    params ["_control", "_isConfirmDialog", "_message"];

    [_control, _isConfirmDialog, _message] call IDS_Notifications_fnc_handleUIEvents;
}];

// _ctrl ctrlWebBrowserAction ["LoadFile", "IDS_Notifications\ui\_site\index.html"];
// _ctrl ctrlWebBrowserAction ["OpenDevConsole"];

true;
