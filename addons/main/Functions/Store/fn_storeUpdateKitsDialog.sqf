params ["_payload"];

if (!hasInterface) exitWith {};

private _control = uiNamespace getVariable ["FLO_StoreKitsControl", controlNull];
if (isNull _control) exitWith {};

private _script = format [
    "if (window.FLOOKits) { window.FLOOKits.receive(%1); }",
    toJSON _payload
];

[_control, ["ExecJS", _script]] call FLO_fnc_storeWebAction;
