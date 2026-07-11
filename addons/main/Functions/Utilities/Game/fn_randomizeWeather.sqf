/*
 * Function: FLO_fnc_randomizeWeather
 * Description:
 *   Applies a server-authoritative random weather preset requested by an admin.
 */
params [["_requester", objNull, [objNull]]];

if (!isServer || {isNull _requester}) exitWith { false };

private _owner = owner _requester;
if ((remoteExecutedOwner > 2) && {_owner isNotEqualTo remoteExecutedOwner}) exitWith {
    ["WEATHER", 1, format [
        "Rejected weather request from owner %1 for player owner %2",
        remoteExecutedOwner,
        _owner
    ]] call FLO_fnc_log;
    false
};

if ((admin _owner) <= 0) exitWith {
    ["Changing campaign weather requires a logged-in admin.", "warning", false, _owner] call FLO_fnc_sendNotification;
    false
};

private _fogIntensity = selectRandom [0, 0, 0.05, 0.05, 0.1, 0.1, 0.1, 0.2, 0.2, 0.3, 0.4, 0.5];
private _fogDecay = selectRandom [0.01, 0.01, 0.01, 0.02, 0.03, 0.05, 0.05, 0.1, 0.1];
private _overcast = selectRandom [0.1, 0.1, 0.1, 0.3, 0.3, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1, 1, 1];
private _appliedFog = [0, _fogIntensity] select (_overcast >= 0.6);

0 setFog [_appliedFog, _fogDecay, 0];
0 setOvercast _overcast;
forceWeatherChange;

["WEATHER", 3, format ["Weather set - Overcast: %1, Fog: %2", _overcast, _appliedFog]] call FLO_fnc_log;
["Campaign weather changed.", "info", false, _owner] call FLO_fnc_sendNotification;

true
