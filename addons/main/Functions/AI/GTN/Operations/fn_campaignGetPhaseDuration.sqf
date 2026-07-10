/*
 * Function: FLO_fnc_campaignGetPhaseDuration
 * Description:
 *   Returns the configured duration for one campaign operation phase.
 */

params ["_director", ["_phase", "", [""]]];

private _config = _director get "_config";
private _durations = _config get "phaseDurations";
private _key = toUpper _phase;

if !(_key in _durations) then {
    throw format ["FLO_fnc_campaignGetPhaseDuration: unsupported phase '%1'", _phase];
};

_durations get _key
