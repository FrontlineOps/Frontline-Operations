/* Validates live probe ownership across campaign, formation, and virtual-group state. */
params [["_state", createHashMap, [createHashMap]]];

private _fail = {
    params ["_message"];
    ["CAMPAIGN", 1, _message] call FLO_fnc_log;
    throw _message;
};
private _fronts = _state get "frontlineProbes";
private _formationState = _state get "formationState";
private _formations = _formationState get "formations";
private _groupToFormation = _formationState get "groupToFormation";
private _groups = call FLO_fnc_virtualizationGetGroupMap;
private _formationOwners = createHashMap;
private _groupOwners = createHashMap;

{
    private _probeId = _x;
    private _front = _y;
    [_probeId, _front] call FLO_fnc_campaignValidateProbeFrontState;
    private _assignmentId = _front get "formalOperationId";
    if (_assignmentId == "") then { _assignmentId = _probeId; };
    private _formationIds = _front get "formationIds";

    {
        private _formationId = _x;
        if (_formationId in _formationOwners) then {
            [format [
                "Probe fronts %1 and %2 both own formation %3",
                _formationOwners get _formationId,
                _probeId,
                _formationId
            ]] call _fail;
        };
        if !(_formationId in _formations) then {
            [format ["Probe front %1 references missing formation %2", _probeId, _formationId]] call _fail;
        };
        private _formation = _formations get _formationId;
        if ((_formation get "sideKey") != (_front get "sideKey")) then {
            [format ["Probe front %1 owns wrong-side formation %2", _probeId, _formationId]] call _fail;
        };
        if !((_formation get "role") in ["MAIN", "RECOVERY"]) then {
            [format [
                "Probe front %1 owns formation %2 in invalid role %3",
                _probeId,
                _formationId,
                _formation get "role"
            ]] call _fail;
        };
        if ((_formation get "roleOperationId") != _assignmentId) then {
            [format [
                "Probe front %1 formation %2 owner %3 does not match %4",
                _probeId,
                _formationId,
                _formation get "roleOperationId",
                _assignmentId
            ]] call _fail;
        };
        _formationOwners set [_formationId, _probeId];
    } forEach _formationIds;

    {
        private _groupId = _x;
        if (_groupId in _groupOwners) then {
            [format [
                "Probe fronts %1 and %2 both own committed group %3",
                _groupOwners get _groupId,
                _probeId,
                _groupId
            ]] call _fail;
        };
        if !(_groupId in _groups) then {
            [format ["Probe front %1 references missing committed group %2", _probeId, _groupId]] call _fail;
        };
        private _groupData = _groups get _groupId;
        if ((_groupData get "unitCount") <= 0) then {
            [format ["Probe front %1 retains depleted committed group %2", _probeId, _groupId]] call _fail;
        };
        if (([_groupData get "side"] call FLO_fnc_sideKey) != (_front get "sideKey")) then {
            [format ["Probe front %1 owns wrong-side group %2", _probeId, _groupId]] call _fail;
        };
        if (
            (_groupData get "commanderOrder") != "ATTACK"
            || {(_groupData get "attackObjective") != (_front get "objectiveId")}
            || {(_groupData get "campaignOperationId") != _assignmentId}
        ) then {
            [format ["Probe front %1 group %2 has inconsistent ATTACK ownership", _probeId, _groupId]] call _fail;
        };
        if !(_groupId in _groupToFormation) then {
            [format ["Probe front %1 group %2 has no formation", _probeId, _groupId]] call _fail;
        };
        private _formationId = _groupToFormation get _groupId;
        if !(_formationId in _formationIds) then {
            [format [
                "Probe front %1 group %2 belongs to unowned formation %3",
                _probeId,
                _groupId,
                _formationId
            ]] call _fail;
        };
        _groupOwners set [_groupId, _probeId];
    } forEach (_front get "committedGroupIds");
} forEach _fronts;

true
