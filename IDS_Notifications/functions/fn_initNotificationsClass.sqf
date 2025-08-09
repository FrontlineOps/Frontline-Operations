/*
 * Author: IDSolutions
 * Initialize notification class
 *
 * Arguments:
 * N/A
 *
 * Return Value:
 * N/A
 *
 * Examples:
 * [] call IDS_Notifications_fnc_initNotificationClass
 *
 * Public: Yes
 */

INotificationClass = createHashMapObject [[
    ["#type", "INotificationClass"],
    ["#create", {
        private _display = uiNamespace getVariable ["IDS_Notifications", nil];
        private _control = _display displayCtrl 1002;

        _self set ["control", _control];
        _self set ["isLoaded", false];
    }],
    ["init", {
        private _params = ["success", "System Ready", "Notification system handshake complete!", 3000];

        _self call ["create", _params];
        _self set ["isLoaded", true];

        systemChat format ["Notification System loaded for %1", (name player)];
        diag_log "[IDS:Notification:System] Notifications System Initialized!";
    }],
    ["create", {
        params ["_type", "_title", "_content", ["_duration", 4000]];

        private _control = _self get "control";
        private _message = createHashMap;

        _message set ["type", _type];
        _message set ["title", _title];
        _message set ["message", _content];
        _message set ["duration", _duration];

        _control ctrlWebBrowserAction ["ExecJS", format ["window.dispatchEvent(new CustomEvent('ids:notify', { detail: %1 }))", (toJSON _message)]];
    }]
]];

missionNamespace setVariable ["IDS_NotificationClass", INotificationClass];
publicVariable "INotificationClass";
INotificationClass
