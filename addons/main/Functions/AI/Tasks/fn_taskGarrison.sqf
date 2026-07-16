/* Occupies nearby roofed building positions without changing the canonical group route. */
params [
    ["_group", grpNull, [grpNull]],
    ["_anchor", [], [[]]],
    ["_radius", 200, [0]]
];

if (isNull _group) then {
    ["VIRTUALIZATION", 1, "Cannot apply physical garrison to a null group"] call FLO_fnc_log;
    throw "FLO_fnc_taskGarrison: group is null";
};
if !(local _group) then {
    ["VIRTUALIZATION", 1, format ["Cannot apply physical garrison to non-local group %1", _group]] call FLO_fnc_log;
    throw format ["FLO_fnc_taskGarrison: group %1 is not local", _group];
};
if (!(count _anchor in [2, 3]) || {_anchor findIf {!(_x isEqualType 0)} >= 0}) then {
    ["VIRTUALIZATION", 1, format ["Physical garrison %1 received invalid anchor %2", _group, _anchor]] call FLO_fnc_log;
    throw format ["FLO_fnc_taskGarrison: invalid anchor %1", _anchor];
};
if (_radius <= 0) then {
    ["VIRTUALIZATION", 1, format ["Physical garrison %1 received invalid radius %2", _group, _radius]] call FLO_fnc_log;
    throw format ["FLO_fnc_taskGarrison: invalid radius %1", _radius];
};

if (_group getVariable ["FLO_buildingGarrisonAttempted", false]) then {
    [_group] call FLO_fnc_taskReleaseGarrison;
};

private _metrics = createHashMapFromArray [
    ["candidateUnits", 0],
    ["buildingPositions", 0],
    ["assigned", 0],
    ["rejected", 0]
];
_group setVariable ["FLO_buildingGarrisonAttempted", true];
_group setVariable ["FLO_buildingGarrisonAnchor", +_anchor];
_group setVariable ["FLO_buildingGarrisonAssigned", 0];

private _eligibleUnits = (units _group) select {
    alive _x
    && {local _x}
    && {!isPlayer _x}
    && {_x isKindOf "CAManBase"}
    && {isNull objectParent _x}
};
_metrics set ["candidateUnits", count _eligibleUnits];

private _rankedPositions = [];
{
    private _building = _x;
    if (isObjectHidden _building) then { continue };
    {
        private _position = _x;
        if (_position isEqualTo [0, 0, 0] || {surfaceIsWater _position}) then { continue };
        private _positionAsl = AGLToASL _position;
        if !(lineIntersects [_positionAsl, _positionAsl vectorAdd [0, 0, 6], objNull, objNull]) then { continue };
        _rankedPositions pushBack [
            _position distance2D _anchor,
            -(_position select 2),
            _position
        ];
    } forEach (_building buildingPos -1);
} forEach (nearestObjects [_anchor, ["House"], _radius, true]);
_rankedPositions sort true;
_metrics set ["buildingPositions", count _rankedPositions];

private _assignmentCount = (count _eligibleUnits) min (count _rankedPositions);
for "_index" from 0 to (_assignmentCount - 1) do {
    private _unit = _eligibleUnits select _index;
    private _position = (_rankedPositions select _index) select 2;
    doStop _unit;
    _unit setVehiclePosition [_position, [], 0, "CAN_COLLIDE"];

    if ((getPosATL _unit) distance _position > 3) then {
        _metrics set ["rejected", (_metrics get "rejected") + 1];
        _unit doFollow (leader _group);
        continue;
    };

    _unit disableAI "PATH";
    _unit setUnitPos (["UP", "MIDDLE"] select ((_index mod 3) == 2));
    _unit setVariable ["FLO_garrisonPosition", +_position];

    private _handlers = [];
    _handlers pushBack ["Hit", _unit addEventHandler ["Hit", {
        params ["_unit"];
        [_unit, true] call FLO_fnc_taskReleaseGarrisonUnit;
    }]];
    _handlers pushBack ["Suppressed", _unit addEventHandler ["Suppressed", {
        params ["_unit"];
        [_unit, true] call FLO_fnc_taskReleaseGarrisonUnit;
    }]];
    _handlers pushBack ["FiredNear", _unit addEventHandler ["FiredNear", {
        params ["_unit", "_shooter", "_distance"];
        if (
            !isNull _shooter
            && {_distance <= 25}
            && {(side _unit) getFriend (side _shooter) < 0.6}
        ) then {
            [_unit, true] call FLO_fnc_taskReleaseGarrisonUnit;
        };
    }]];
    _unit setVariable ["FLO_garrisonEventHandlers", _handlers];
    _metrics set ["assigned", (_metrics get "assigned") + 1];
};

_group setBehaviour "AWARE";
_group setCombatMode "YELLOW";
_group enableAttack true;
_group setVariable ["FLO_buildingGarrisonAssigned", _metrics get "assigned"];

["VIRTUALIZATION", 4, format [
    "Physical building garrison group=%1 candidates=%2 positions=%3 assigned=%4 rejected=%5",
    _group,
    _metrics get "candidateUnits",
    _metrics get "buildingPositions",
    _metrics get "assigned",
    _metrics get "rejected"
]] call FLO_fnc_log;

_metrics
