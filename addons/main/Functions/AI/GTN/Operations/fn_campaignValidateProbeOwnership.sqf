/* Validates live group ownership for every canonical probe task force. */
params [["_state", createHashMap, [createHashMap]]];

private _fail = {
    params ["_message"];
    ["CAMPAIGN", 1, _message] call FLO_fnc_log;
    throw _message;
};
private _fronts = _state get "frontlineProbes";
private _groups = call FLO_fnc_virtualizationGetGroupMap;
private _groupOwners = createHashMap;

{
    private _probeId = _x;
    private _front = _y;
    [_probeId, _front] call FLO_fnc_campaignValidateProbeFrontState;
    private _assignmentId = _front get "formalOperationId";
    if (_assignmentId == "") then { _assignmentId = _probeId; };

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
        _groupOwners set [_groupId, _probeId];
    } forEach (_front get "committedGroupIds");
} forEach _fronts;

true
