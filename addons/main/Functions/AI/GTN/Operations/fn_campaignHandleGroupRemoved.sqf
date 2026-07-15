/* Reconciles canonical probe ownership synchronously when a virtual group is removed. */
params [
    "_director",
    ["_groupId", "", [""]]
];

if (_groupId == "") then {
    throw "Campaign group-removal reconciliation requires a group ID";
};

private _state = _director get "_state";
private _fronts = _state get "frontlineProbes";
private _owners = [];
{
    if (_groupId in (_y get "committedGroupIds")) then {
        _owners pushBack [_x, _y];
    };
} forEach _fronts;

if (_owners isEqualTo []) exitWith { false };
if ((count _owners) != 1) then {
    private _ownerIds = _owners apply { _x select 0 };
    private _message = format [
        "Removed group %1 was committed to multiple probe fronts %2",
        _groupId,
        _ownerIds
    ];
    ["CAMPAIGN", 1, _message] call FLO_fnc_log;
    throw _message;
};

(_owners select 0) params ["_probeId", "_front"];
private _committedGroupIds = +(_front get "committedGroupIds");
_committedGroupIds deleteAt (_committedGroupIds find _groupId);
_front set ["committedGroupIds", _committedGroupIds];
_state set ["revision", (_state get "revision") + 1];

["CAMPAIGN", 4, format [
    "Probe front %1 reconciled destroyed group %2 remaining=%3 baseline=%4",
    _probeId,
    _groupId,
    count _committedGroupIds,
    _front get "committedUnitBaseline"
]] call FLO_fnc_log;

true
