/* Selects one eligible maneuver group for a paced probe commitment. */
params [
    "_director",
    "_cmdr",
    ["_front", createHashMap, [createHashMap]],
    ["_diagnostics", createHashMap, [createHashMap]]
];

private _recordRejection = {
    params ["_reason"];
    private _count = if (_reason in _diagnostics) then { _diagnostics get _reason } else { 0 };
    _diagnostics set [_reason, _count + 1];
};
["ATTEMPTS"] call _recordRejection;

private _state = _director get "_state";
[_state] call FLO_fnc_campaignValidateProbeOwnership;
private _groups = call FLO_fnc_virtualizationGetGroupMap;
private _ownedGroupIds = [];
{
    _ownedGroupIds append (_y get "committedGroupIds");
} forEach (_state get "frontlineProbes");

private _ownSide = _cmdr get "_ownSide";
private _sourcePos = (FLO_Objectives get (_front get "primarySourceObjectiveId")) get "position";
private _ranked = [];
{
    private _groupId = _x;
    private _groupData = _y;
    if (_groupId in _ownedGroupIds) then { ["PROBE_OWNER"] call _recordRejection; continue };
    if !([
        _groupData,
        _ownSide,
        ["infantry", "motorized", "mechanized", "armor"],
        ["PATROL", "DEFEND"],
        "",
        _diagnostics
    ] call FLO_fnc_gtnGroupIsStrategicallyAssignable) then {
        ["GROUP_ASSIGNABILITY"] call _recordRejection;
        continue;
    };
    if ((_groupData get "unitCount") <= 0) then { ["DEPLETED"] call _recordRejection; continue };
    ["ELIGIBLE"] call _recordRejection;
    _ranked pushBack [
        (_groupData get "position") distance2D _sourcePos,
        -(_groupData get "combatExperience"),
        _groupId
    ];
} forEach _groups;

if (_ranked isEqualTo []) exitWith { "" };
_ranked sort true;
["SELECTED"] call _recordRejection;
(_ranked select 0) select 2
