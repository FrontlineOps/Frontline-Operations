/* Selects one whole ready maneuver formation for a probe commitment. */
params [
    "_director",
    "_cmdr",
    ["_front", createHashMap, [createHashMap]],
    ["_diagnostics", createHashMap, [createHashMap]]
];

private _reject = {
    params ["_reason"];
    private _count = if (_reason in _diagnostics) then { _diagnostics get _reason } else { 0 };
    _diagnostics set [_reason, _count + 1];
};
["ATTEMPTS"] call _reject;

private _formationState = (_director get "_state") get "formationState";
private _formations = _formationState get "formations";
private _fronts = ((_director get "_state") get "frontlineProbes");
private _formationOwners = createHashMap;
{
    private _ownerProbeId = _x;
    {
        if (_x in _formationOwners && {(_formationOwners get _x) != _ownerProbeId}) then {
            private _message = format [
                "Probe fronts %1 and %2 both own formation %3",
                _formationOwners get _x,
                _ownerProbeId,
                _x
            ];
            ["CAMPAIGN", 1, _message] call FLO_fnc_log;
            throw _message;
        };
        _formationOwners set [_x, _ownerProbeId];
    } forEach (_y get "formationIds");
} forEach _fronts;
private _groups = call FLO_fnc_virtualizationGetGroupMap;
private _sideKey = _front get "sideKey";
private _ownSide = _cmdr get "_ownSide";
private _sourceObjectiveId = _front get "primarySourceObjectiveId";
private _sourcePos = (FLO_Objectives get _sourceObjectiveId) get "position";
private _minimumReadiness = ((_director get "_config") get "probeFormationMinimumReadiness");
private _ranked = [];

{
    private _formationId = _x;
    private _formation = _y;
    if ((_formation get "sideKey") != _sideKey) then { ["FORMATION_SIDE"] call _reject; continue };
    if ((_formation get "role") != "RESERVE") then { ["FORMATION_ROLE"] call _reject; continue };
    if (_formationId in _formationOwners) then {
        ["FORMATION_FRONT_OWNER"] call _reject;
        continue
    };
    if ((_formation get "roleOperationId") != "") then {
        ["FORMATION_OWNER"] call _reject;
        continue
    };
    if !((_formation get "branch") in ["infantry", "motorized", "mechanized", "armor"]) then {
        ["FORMATION_BRANCH"] call _reject;
        continue
    };
    if ((_formation get "readiness") < _minimumReadiness) then { ["FORMATION_READINESS"] call _reject; continue };

    private _memberIds = (_formation get "memberIds") select {
        _x in _groups && {((_groups get _x) get "unitCount") > 0}
    };
    if ((count _memberIds) < 3) then { ["MEMBER_COUNT"] call _reject; continue };
    private _allAssignable = {
        [
            _groups get _x,
            _ownSide,
            ["infantry", "motorized", "mechanized", "armor"],
            ["PATROL", "DEFEND"],
            _front get "probeId",
            _diagnostics
        ]
            call FLO_fnc_gtnGroupIsStrategicallyAssignable
    } count _memberIds == count _memberIds;
    if (!_allAssignable) then { ["GROUP_ASSIGNABILITY"] call _reject; continue };

    ["ELIGIBLE"] call _reject;

    private _leadId = _formation get "leadGroupId";
    private _leadPos = (_groups get _leadId) get "position";
    _ranked pushBack [
        _leadPos distance2D _sourcePos,
        -(_formation get "readiness"),
        _formationId,
        _memberIds
    ];
} forEach _formations;

if (_ranked isEqualTo []) exitWith { createHashMap };
_ranked sort true;
private _selected = _ranked select 0;
["SELECTED"] call _reject;
createHashMapFromArray [
    ["formationId", _selected select 2],
    ["memberIds", _selected select 3]
]
