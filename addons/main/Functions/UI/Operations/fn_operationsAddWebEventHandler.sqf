params ["_control"];

private _event = "JSDialog";
_control ctrlAddEventHandler [_event, {
    params ["_control", "_isConfirmDialog", "_message"];
    [_control, _isConfirmDialog, _message] call FLO_fnc_operationsHandleUiEvent;
}];
