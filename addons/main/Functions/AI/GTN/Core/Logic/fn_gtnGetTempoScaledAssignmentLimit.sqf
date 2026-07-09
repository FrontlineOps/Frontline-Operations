/*
 * Function: FLO_fnc_gtnGetTempoScaledAssignmentLimit
 * Author: Frontline Operations Development Group
 *
 * Description:
 *   Resolves the effective per-cycle assignment cap for a commander config key.
 *   GTN assignment caps are authored for the 10-second commander cadence.
 *   Slower cadences follow an upward interpolation curve anchored on the
 *   supported commander tempo presets so strategic mobilization rises
 *   materially with longer sleeps instead of flattening out.
 *
 * Arguments:
 * 0: GTN Commander <HASHMAP>
 * 1: Config key <STRING>
 *
 * Return Value:
 * Effective assignment limit <NUMBER>
 */

params ["_cmdr", "_configKey"];

private _config = _cmdr get "_config";
private _baseLimit = (_config get _configKey) max 0;
private _updateInterval = (_cmdr get "_updateInterval") max 1;
private _baselineInterval = 10;
private _tempoMultiplierAnchors = [
    [10, 1],
    [20, 4],
    [28, 5.25]
];
private _multiplier = _updateInterval / _baselineInterval;

if (_updateInterval <= ((_tempoMultiplierAnchors select 0) select 0)) then {
    _multiplier = ((_tempoMultiplierAnchors select 0) select 1) max _multiplier;
} else {
    private _resolved = false;
    for "_i" from 1 to ((count _tempoMultiplierAnchors) - 1) do {
        private _lower = _tempoMultiplierAnchors select (_i - 1);
        private _upper = _tempoMultiplierAnchors select _i;
        private _lowerTempo = _lower select 0;
        private _upperTempo = _upper select 0;

        if (_updateInterval <= _upperTempo) exitWith {
            private _alpha = (_updateInterval - _lowerTempo) / (_upperTempo - _lowerTempo);
            _multiplier = (_lower select 1) + (((_upper select 1) - (_lower select 1)) * _alpha);
            _resolved = true;
        };
    };

    if (!_resolved) then {
        private _lower = _tempoMultiplierAnchors select -2;
        private _upper = _tempoMultiplierAnchors select -1;
        private _lowerTempo = _lower select 0;
        private _upperTempo = _upper select 0;
        private _slope = ((_upper select 1) - (_lower select 1)) / (_upperTempo - _lowerTempo);
        _multiplier = (_upper select 1) + ((_updateInterval - _upperTempo) * _slope);
    };
};
private _scaledLimit = ceil (_baseLimit * _multiplier);

if (_baseLimit > 0) then {
    _scaledLimit = _scaledLimit max _baseLimit;
};

_scaledLimit
