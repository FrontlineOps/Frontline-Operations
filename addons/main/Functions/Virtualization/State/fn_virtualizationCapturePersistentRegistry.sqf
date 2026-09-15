/* Settle pending crew transitions, then capture physical outcomes into an isolated copy. */
if (canSuspend) then {
    throw "[VIRTUALIZATION] Persistent registry capture requires an unscheduled snapshot boundary";
};

private _groups = call FLO_fnc_virtualizationGetGroupMap;
// A save can arrive before the active-update slice following vehicle loss.
// Let the lifecycle owner detach passengers and preserve surviving crew first.
{
    private _groupData = _groups get _x;
    if (_groupData get "isActive") then {
        [_x, _groupData, _groupData get "realGroup"] call FLO_fnc_virtualizationConvertAssetCrewToInfantryRemnant;
    };
} forEach (keys _groups);

private _snapshot = +_groups;
{
    private _groupId = _x;
    private _groupData = _y;
    if !(_groupData get "isActive") then { continue };

    private _realGroup = _groupData get "realGroup";
    [_groupId, _groupData, _realGroup] call FLO_fnc_virtualizationSyncRealGroupOutcome;
    private _leader = leader _realGroup;
    if (!isNull _leader && {alive _leader}) then {
        private _position = getPosATL vehicle _leader;
        if !([_position] call FLO_fnc_validateGroupPosition) then {
            throw format ["[VIRTUALIZATION] Cannot save invalid physical position for %1", _groupId];
        };
        _groupData set ["position", _position];
        _groupData set ["direction", getDir vehicle _leader];
    };
    // Mounted passengers retain their own post-dismount route, not the carrier's.
    if ((_groupData get "attachedTo") == "") then {
        [_groupId, _groupData, _realGroup] call FLO_fnc_virtualizationCaptureRealGroupWaypoints;
    };
    [_groupData, _realGroup] call FLO_fnc_virtualizationCaptureRealGroupRuntimeState;
} forEach _snapshot;

// Validate physical ownership while engine handles still describe this capture.
// Scheduled serialization must not re-read those handles after simulation resumes.
{ [_y, _x] call FLO_fnc_virtualizationValidateGroup } forEach _snapshot;

_snapshot
