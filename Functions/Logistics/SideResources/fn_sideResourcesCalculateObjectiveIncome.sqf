/*
 * Function: FLO_fnc_sideResourcesCalculateObjectiveIncome
 * Author: Frontline Operations Development Group
 * Description:
 *   Calculates one owned objective's current resource contribution using
 *   maintained objective counts instead of raw world rescans.
 *
 * Arguments:
 *   0: Resource object <HASHMAP>
 *   1: Objective data <HASHMAP>
 *
 * Return Value:
 *   [income, status] <ARRAY>
 *
 * Example:
 *   private _income = [_resourceObj, _objData] call FLO_fnc_sideResourcesCalculateObjectiveIncome;
 */

params ["_resourceObj", "_objectiveData"];

private _side = _resourceObj get "_side";
private _resourceValues = _resourceObj get "RESOURCE_VALUES";
private _contestModifiers = _resourceObj get "CONTEST_MODIFIERS";
private _baseValue = _resourceValues get (_objectiveData get "subtype");
private _friendlyCount = if (_side isEqualTo west) then {
    _objectiveData get "bluforCount"
} else {
    _objectiveData get "opforCount"
};
private _enemyCount = if (_side isEqualTo west) then {
    _objectiveData get "opforCount"
} else {
    _objectiveData get "bluforCount"
};
private _captureProgress = _objectiveData get "captureProgress";
private _status = "SECURE";

if (_enemyCount > 0) then {
    if (_friendlyCount <= 0) then {
        _status = "OVERRUN";
    } else {
        if (_friendlyCount > _enemyCount) then {
            _status = "DEFENDED";
        } else {
            _status = "CONTESTED";
        };
    };
};

private _multiplier = _contestModifiers get _status;
private _underPressure = if (_side isEqualTo west) then {
    _captureProgress < 0
} else {
    _captureProgress > 0
};

if (_underPressure) then {
    _multiplier = _multiplier * 0.85;
};

[_baseValue * _multiplier, _status]
