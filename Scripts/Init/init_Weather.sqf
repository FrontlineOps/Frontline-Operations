/*
 * Weather Randomization
 * Author: Frontline Operations
 *
 * Description:
 * Randomizes weather conditions including fog and overcast.
 * Fog is only applied when overcast is significant (>= 0.6).
 *
 * Usage:
 * Called from FOB container "Change Weather" action.
 *
 * Note:
 * This script runs on the server and applies weather globally.
 */

if (!isServer) exitWith {};

["WEATHER", 3, "Randomizing weather conditions..."] call FLO_fnc_log;

// Fog intensity weights favor clear to light fog
private _fogIntensity = selectRandom [0, 0, 0.05, 0.05, 0.1, 0.1, 0.1, 0.2, 0.2, 0.3, 0.4, 0.5];
private _fogDecay = selectRandom [0.01, 0.01, 0.01, 0.02, 0.03, 0.05, 0.05, 0.1, 0.1];
private _fogAltitude = 0;

// Overcast weights favor partly cloudy to clear
private _overcast = selectRandom [0.1, 0.1, 0.1, 0.3, 0.3, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1, 1, 1];

// Only apply fog when sufficiently overcast
if (_overcast >= 0.6) then {
    0 setFog [_fogIntensity, _fogDecay, _fogAltitude];
} else {
    0 setFog [0, _fogDecay, _fogAltitude];
};

0 setOvercast _overcast;
forceWeatherChange;

["WEATHER", 3, format["Weather set - Overcast: %1, Fog: %2", _overcast, _fogIntensity]] call FLO_fnc_log;
