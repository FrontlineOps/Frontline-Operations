/*
 * Author: IDSolutions
 * Handles UI events.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call IDS_Notifications_fnc_handleUIEvents;
 *
 * Public: No
 */

params ["_control", "_isConfirmDialog", "_message"];

private _class = missionNamespace getVariable ["IDS_NotificationClass", nil];
if (isNil "_class") then { [] call IDS_Notifications_fnc_initNotificationClass };

private _alert = fromJSON _message;
private _event = _alert get "event";
private _data = _alert get "data";

switch (_event) do {
    case "notifications::ready": {
        INotificationClass call ["init", []];
    };
    default { hint format ["Unhandled UI event: %1", _event]; };
};

true;