/* Selects the nearest live-capable battery that can produce a valid fire plan. */
params [
    "_manager",
    ["_artilleryGroups", [], [[]]],
    ["_targetPos", [0, 0, 0], [[]], [3]],
    ["_rounds", 1, [0]],
    ["_accuracy", 100, [0]]
];

private _now = diag_tickTime;
private _rejections = _manager get "firePlanRejections";
{
    if ((_rejections get _x) <= _now) then {
        _rejections deleteAt _x;
    };
} forEach (keys _rejections);

private _bucketX = floor ((_targetPos select 0) / 250);
private _bucketY = floor ((_targetPos select 1) / 250);
private _ranked = _artilleryGroups apply {
    [_targetPos distance2D ((_x select 1) get "position"), _x select 0, _x select 1]
};
_ranked sort true;

private _selected = createHashMapFromArray [
    ["groupId", ""],
    ["groupData", createHashMap],
    ["realGroup", grpNull],
    ["firePlan", createHashMap],
    ["activatedForSelection", false],
    ["rejectedCooldown", 0],
    ["activationFailures", 0],
    ["emptyPlans", 0]
];

{
    if ((_selected get "groupId") != "") then { continue };
    private _groupId = _x select 1;
    private _groupData = _x select 2;
    private _rejectionKey = format ["%1:%2:%3", _groupId, _bucketX, _bucketY];
    if (_rejectionKey in _rejections) then {
        _selected set ["rejectedCooldown", (_selected get "rejectedCooldown") + 1];
        continue;
    };

    private _wasActive = _groupData get "isActive";
    if (!_wasActive && {!([_groupId] call FLO_fnc_virtualizationTryActivateGroup)}) then {
        _rejections set [_rejectionKey, _now + 60];
        _selected set ["activationFailures", (_selected get "activationFailures") + 1];
        continue;
    };

    private _realGroup = _groupData get "realGroup";
    if (isNull _realGroup) then {
        ["GTN Artillery", 1, format [
            "Battery %1 activated for target %2 without a realGroup",
            _groupId,
            _targetPos
        ]] call FLO_fnc_log;
        throw format ["Activated artillery battery %1 has no realGroup", _groupId];
    };

    private _firePlan = [_realGroup, _targetPos, _rounds, _accuracy] call FLO_fnc_gtnBuildArtilleryFirePlan;
    if ((keys _firePlan) isEqualTo []) then {
        _rejections set [_rejectionKey, _now + (_manager get "firePlanRejectSeconds")];
        _selected set ["emptyPlans", (_selected get "emptyPlans") + 1];
        if (!_wasActive) then {
            [_groupId, _groupData] call FLO_fnc_deactivateVirtualGroup;
        };
        continue;
    };

    _selected set ["groupId", _groupId];
    _selected set ["groupData", _groupData];
    _selected set ["realGroup", _realGroup];
    _selected set ["firePlan", _firePlan];
    _selected set ["activatedForSelection", !_wasActive];
} forEach _ranked;

_selected
