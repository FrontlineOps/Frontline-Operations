params ["_event", "_payload"];

if (!hasInterface) exitWith {};

if (isMultiplayer && {remoteExecutedOwner isNotEqualTo 2} && {remoteExecutedOwner isNotEqualTo 0}) exitWith {
    ["UI", 2, format ["Rejected Store response from owner %1", remoteExecutedOwner]] call FLO_fnc_log;
};

[_event, _payload] call FLO_fnc_storeUpdateDialog;
