/*
 * Function: FLO_fnc_gtnAlertIncomingArtillery
 * Author: Frontline Operations Development Group
 * Description:
 *   Publishes a reported artillery-impact warning to the side being targeted.
 *   The alert is only emitted when the side has plausible local observers near
 *   the impact area. This warns about the strike area, not the battery.
 *
 * Arguments:
 *   0: Target position <ARRAY>
 *   1: Number of rounds <NUMBER>
 *   2: Accuracy / dispersion meters <NUMBER>
 *   3: Target side <SIDE>
 *   4: Alert payload <ARRAY>
 *
 * Return Value:
 *   HASHMAP - Published alert data
 */

params [
    ["_targetPos", [0, 0, 0], [[]], [3]],
    ["_rounds", 6, [0]],
    ["_accuracy", 100, [0]],
    ["_targetSide", sideUnknown],
    ["_payload", [], [[]]]
];

if !(_targetSide in [east, west]) exitWith { createHashMap };

private _impactRadius = ((_accuracy max 100) * 2.5) min 700;
if (_rounds >= 8) then {
    _impactRadius = _impactRadius + 50;
};
if (_impactRadius < 250) then {
    _impactRadius = 250;
};

if !([_targetPos, _impactRadius, _targetSide] call FLO_fnc_gtnCanSideObserveArea) exitWith {
    createHashMap
};

private _duration = 90;
private _etaText = "";
if ((count _payload) >= 2) then {
    private _etaMin = _payload select 0;
    private _etaMax = _payload select 1;

    if (_etaMax > 0) then {
        _etaText = if (_etaMax > _etaMin) then {
            format [" ETA %1-%2s", _etaMin, _etaMax]
        } else {
            format [" ETA %1s", _etaMax]
        };

        private _requiredDuration = _etaMax + 25;
        if (_requiredDuration > _duration) then {
            _duration = _requiredDuration;
        };
    };
};

private _grid = mapGridPosition _targetPos;
private _message = format ["ARTILLERY IMPACTS reported near grid %1%2", _grid, _etaText];

[_targetSide, "ARTILLERY_INCOMING", _targetPos, _impactRadius, _duration, _message, _payload] call FLO_fnc_gtnPublishAlert
