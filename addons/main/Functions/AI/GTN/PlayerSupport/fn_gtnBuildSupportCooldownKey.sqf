/*
 * Function: FLO_fnc_gtnBuildSupportCooldownKey
 * Author: Frontline Operations Development Group
 * Description:
 *   Builds the objective or area cooldown key for a player support request.
 *   Objective-linked requests lock by objective. Free-point requests lock by
 *   a coarse map bucket around the clicked position.
 *
 * Arguments:
 *   0: Support type <STRING>
 *   1: Objective ID <STRING>
 *   2: Target position <ARRAY>
 *   3: Bucket size meters <NUMBER>
 *
 * Return Value:
 *   STRING
 */

params [
    ["_supportType", "", [""]],
    ["_objectiveId", "", [""]],
    ["_targetPos", [0, 0, 0], [[]], [3]],
    ["_bucketSizeMeters", 500, [0]]
];

private _type = toUpper _supportType;

if (_objectiveId != "") exitWith {
    format ["%1:OBJ:%2", _type, _objectiveId]
};

if (_bucketSizeMeters <= 0) then {
    _bucketSizeMeters = 500;
};

private _bucketX = floor ((_targetPos select 0) / _bucketSizeMeters);
private _bucketY = floor ((_targetPos select 1) / _bucketSizeMeters);

format ["%1:GRID:%2_%3", _type, _bucketX, _bucketY]
