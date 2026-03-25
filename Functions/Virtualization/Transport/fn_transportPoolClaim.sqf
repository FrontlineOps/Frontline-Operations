/*
 * Function: FLO_fnc_transportPoolClaim
 */

params [["_groupId", "", [""]], ["_infantryId", "", [""]]];

if (_groupId == "") exitWith { false };

private _available = FLO_TransportPool get "available";
private _active = FLO_TransportPool get "active";

if (_groupId in _available) then {
    private _data = _available get _groupId;
    _available deleteAt _groupId;
    _active set [_groupId, [_data select 0, _infantryId]];
} else {
    private _groupData = [_groupId] call FLO_fnc_transportGetTrackedGroup;
    private _capacity = [_groupData] call FLO_fnc_transportGetGroupCapacity;
    _active set [_groupId, [_capacity, _infantryId]];
};

["TRANSPORT", 3, format ["Pool: Claimed transport %1 for %2", _groupId, _infantryId]] call FLO_fnc_log;
true
