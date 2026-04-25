/*
 * Function: FLO_fnc_minefieldDeleteField
 * Author: Frontline Operations Development Group
 * Description:
 *   Deletes a tracked objective minefield and updates registry state.
 *
 * Arguments:
 * 0: Field ID <STRING>
 * 1: Reason <STRING> (optional)
 *
 * Return Value:
 * BOOL
 */

params [
    ["_fieldId", ""],
    ["_reason", "STALE"]
];

if (_fieldId == "") exitWith { false };
if (isNil "FLO_Minefields") exitWith { false };

private _field = FLO_Minefields get _fieldId;
if (isNil "_field") exitWith { false };

private _objectiveId = _field get "objectiveId";
private _markerName = _field get "markerName";

{
    if (isNull _x) then { continue };
    deleteVehicle _x;
} forEach (_field get "mineObjects");

if (_markerName != "" && {getMarkerColor _markerName != ""}) then {
    deleteMarker _markerName;
};

FLO_Minefields deleteAt _fieldId;
FLO_MinefieldObjectiveIndex deleteAt _objectiveId;

if (_reason isEqualTo "CLEARED") then {
    private _cooldownDays = (FLO_MinefieldConfig get "clearCooldownSeconds") / 86400;
    FLO_MinefieldObjectiveCooldowns set [_objectiveId, (dateToNumber date) + _cooldownDays];
};

if (_reason isEqualTo "FLIPPED") then {
    FLO_MinefieldObjectiveCooldowns deleteAt _objectiveId;
};

["MINEFIELD", 3, format ["Deleted objective minefield %1 (%2)", _objectiveId, _reason]] call FLO_fnc_log;

true
