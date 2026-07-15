/* Withdraws one exposed formation under ELASTIC_DEFENSE doctrine. */
params [
    "_state",
    ["_sideKey", "", [""]]
];

if (((_state get "doctrineBySide") get _sideKey) != "ELASTIC_DEFENSE") exitWith { false };
private _now = call FLO_fnc_operationalDateNumber;
private _lastWithdrawalAt = (_state get "lastWithdrawalAtBySide") get _sideKey;
if (_lastWithdrawalAt >= 0 && {([_lastWithdrawalAt, _now] call FLO_fnc_dateNumberDeltaSeconds) < 300}) exitWith { false };

private _side = [_sideKey] call FLO_fnc_campaignSideFromKey;
private _enemySide = [east, west] select (_side isEqualTo east);
private _candidateRows = [];
{
    private _objectiveId = _x;
    private _objective = _y;
    if ((_objective get "owner") isNotEqualTo _side) then { continue };
    if ((_objective get "campaignIntegrationState") != "INTEGRATED") then { continue };
    if ((_objective get "priority") >= 90 || {(_objective get "subtype") == "capital"}) then { continue };
    private _enemyLinks = 0;
    private _friendlyLinks = 0;
    private _fallbackRows = [];
    {
        private _linked = FLO_Objectives get _x;
        if ((_linked get "owner") isEqualTo _enemySide) then { _enemyLinks = _enemyLinks + 1; };
        if ((_linked get "owner") isEqualTo _side) then {
            _friendlyLinks = _friendlyLinks + 1;
            if ((_linked get "campaignIntegrationState") == "INTEGRATED") then {
                _fallbackRows pushBack [-(_linked get "priority"), _x];
            };
        };
    } forEach (_objective get "linkedObjectives");
    if (_enemyLinks >= 2 && {_friendlyLinks <= 1} && {_fallbackRows isNotEqualTo []}) then {
        _fallbackRows sort true;
        _candidateRows pushBack [_objective get "priority", -_enemyLinks, _objectiveId, (_fallbackRows select 0) select 1];
    };
} forEach FLO_Objectives;
_candidateRows sort true;
if (_candidateRows isEqualTo []) exitWith { false };

private _groups = call FLO_fnc_virtualizationGetGroupMap;
private _index = _state get "groupToFormation";
private _formations = _state get "formations";
private _selected = [];
{
    if (_selected isNotEqualTo []) then { continue };
    _x params ["_priority", "_enemyPressure", "_objectiveId", "_fallbackId"];
    private _membersByFormation = createHashMap;
    {
        private _groupId = _x;
        private _groupData = _y;
        if ((_groupData get "side") isNotEqualTo _side || {!(_groupId in _index)}) then { continue };
        if !((_groupData get "commanderOrder") in ["DEFEND", "GARRISON"]) then { continue };
        if ((_groupData get "defendObjective") != _objectiveId && {(_groupData get "garrisonObjective") != _objectiveId}) then { continue };
        private _formationId = _index get _groupId;
        private _formation = _formations get _formationId;
        if !((_formation get "role") in ["RESERVE", "RECOVERY"]) then { continue };
        if ((_formation get "roleOperationId") != "") then { continue };
        private _members = [];
        if (_formationId in _membersByFormation) then { _members = _membersByFormation get _formationId; };
        _members pushBack _groupId;
        _membersByFormation set [_formationId, _members];
    } forEach _groups;
    if ((keys _membersByFormation) isEqualTo []) then { continue };
    private _rows = [];
    {
        _rows pushBack [-(count _y), _x, _y];
    } forEach _membersByFormation;
    _rows sort true;
    _selected = [_objectiveId, _fallbackId, (_rows select 0) select 1, (_rows select 0) select 2];
} forEach _candidateRows;
if (_selected isEqualTo []) exitWith { false };

_selected params ["_objectiveId", "_fallbackId", "_formationId", "_memberIds"];
private _formation = _formations get _formationId;
private _cmdr = FLO_GTN_CommandersBySide get _sideKey;
private _fallbackPosition = (FLO_Objectives get _fallbackId) get "position";
_cmdr call ["_releaseGroups", [_memberIds, ""]];
{
    private _destination = _fallbackPosition getPos [(_forEachIndex mod 3) * 45, _forEachIndex * 120];
    _cmdr call ["_orderGroupMove", [_x, _destination, "AWARE"]];
} forEach _memberIds;

_formation set ["role", "WITHDRAW"];
_formation set ["roleMemberIds", _memberIds];
_formation set ["roleObjectiveId", _fallbackId];
_formation set ["roleOperationId", ""];
_formation set ["roleStartedAtDateNum", _now];
_formation set ["roleEndsAtDateNum", [_now, 300] call FLO_fnc_dateNumberAddSeconds];
_formation set ["returnObjectiveId", _objectiveId];
_formation set ["withdrawals", (_formation get "withdrawals") + 1];
(_state get "lastWithdrawalAtBySide") set [_sideKey, _now];
_state set ["revision", (_state get "revision") + 1];
["FORMATIONS", 3, format ["%1 withdrew from exposed %2 to %3", _formation get "name", [_objectiveId] call FLO_fnc_campaignObjectiveName, [_fallbackId] call FLO_fnc_campaignObjectiveName]] call FLO_fnc_log;
true
