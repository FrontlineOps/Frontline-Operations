params ["_event", "_payload"];

if (!hasInterface) exitWith {};

if (isMultiplayer && {remoteExecutedOwner isNotEqualTo 2} && {remoteExecutedOwner isNotEqualTo 0}) exitWith {
    diag_log format ["[FLO][Store] Rejected store response from owner %1", remoteExecutedOwner];
};

[_event, _payload] call FLO_fnc_storeUpdateDialog;
