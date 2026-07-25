/* Resolves a terrain-backed direct-attack anchor inside one objective. */
params [
    ["_objectiveId", "", [""]],
    ["_objective", createHashMap, [createHashMap]]
];

if (_objectiveId == "") then {
    throw "FLO_fnc_gtnResolveAttackLandAnchor: objective ID is required";
};

private _center = +(_objective get "position");
if ((count _center) < 2) then {
    throw format ["Objective %1 has invalid attack position %2", _objectiveId, _center];
};
if ((count _center) == 2) then { _center pushBack 0 } else { _center set [2, 0] };

private _radius = _objective get "radius";
if (_radius <= 0) then {
    throw format ["Objective %1 has invalid attack radius %2", _objectiveId, _radius];
};

if (!surfaceIsWater _center) exitWith { _center };

private _anchor = [_center, _radius] call FLO_fnc_getSafeLandPos;
if (surfaceIsWater _anchor || {(_anchor distance2D _center) > _radius}) exitWith { [] };
_anchor set [2, 0];
_anchor
