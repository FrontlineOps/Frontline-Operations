/*
 * Function: FLO_fnc_sideResourcesCreate
 * Author: Frontline Operations Development Group
 * Description:
 *   Initializes one side resource object from either saved state or current
 *   objective ownership.
 *
 * Arguments:
 *   0: Resource object <HASHMAP>
 *   1: Side <SIDE>
 *   2: Saved payload <HASHMAP|OBJECT>
 *
 * Return Value:
 *   None
 *
 * Example:
 *   [createHashMapObject [], east, objNull] call FLO_fnc_sideResourcesCreate;
 */

params ["_resourceObj", ["_side", east], ["_savedPayload", objNull]];

private _sideContext = [_side] call FLO_fnc_gtnSideContext;
private _spendingTypes = _resourceObj get "SPENDING_TYPES";
private _efficiencyFloor = _resourceObj get "EFFICIENCY_FLOOR";
private _efficiencies = createHashMap;
{
    _efficiencies set [_x, 1.0];
} forEach (keys _spendingTypes);

_resourceObj set ["_side", _side];
_resourceObj set ["_sideKey", _sideContext get "sideKey"];
_resourceObj set ["_enemySide", _sideContext get "enemySide"];

if (_savedPayload isNotEqualTo objNull) then {
    private _savedEfficiencies = _savedPayload get "efficiencies";
    {
        if (_x in _efficiencies) then {
            _efficiencies set [_x, (_savedEfficiencies get _x) max _efficiencyFloor];
        };
    } forEach (keys _savedEfficiencies);

    _resourceObj set ["_resources", _savedPayload get "resources"];
} else {
    _resourceObj set ["_resources", [_resourceObj] call FLO_fnc_sideResourcesCalculateStartingResources];
};

_resourceObj set ["_efficiencies", _efficiencies];
_resourceObj set ["_lastUpdate", time];
