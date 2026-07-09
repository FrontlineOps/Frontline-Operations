/*
 * Function: FLO_fnc_transportFindRequestCandidates
 * Author: Frontline Operations Development Group
 * Description:
 *   Collects the nearest transport request candidates across the dedicated and
 *   fallback search tiers used by transportRequest. This preserves the existing
 *   request precedence while avoiding repeated scans over the same transport
 *   pool and virtual group registries.
 *
 * Arguments:
 *   0: Required capacity <NUMBER>
 *   1: Search origin <ARRAY>
 *   2: Side <SIDE>
 *   3: Ground carrier types <ARRAY>
 *   4: Air carrier types <ARRAY>
 *
 * Return Value:
 *   Candidate ids keyed by search tier <HASHMAP>
 */

params [
    ["_requiredCapacity", 1, [0]],
    ["_nearPos", [0, 0, 0], [[]]],
    ["_side", sideUnknown, [east]],
    ["_groundCarrierTypes", [], [[]]],
    ["_airCarrierTypes", [], [[]]]
];

private _groups = FLO_virtualGroups get "_groups";
private _available = FLO_TransportPool get "available";
private _active = FLO_TransportPool get "active";

private _groundAvailableMaxDistance = 3000;
private _groundExistingMaxDistance = FLO_Transport_SearchRadius;
private _airMaxDistance = FLO_Transport_AirSearchRadius;

private _state = createHashMapFromArray [
    ["groundAvailableActiveDedicated", ["", _groundAvailableMaxDistance + 1]],
    ["groundAvailableVirtualDedicated", ["", _groundAvailableMaxDistance + 1]],
    ["groundAvailableActiveFallback", ["", _groundAvailableMaxDistance + 1]],
    ["groundAvailableVirtualFallback", ["", _groundAvailableMaxDistance + 1]],
    ["groundExistingActiveDedicated", ["", _groundExistingMaxDistance + 1]],
    ["groundExistingVirtualDedicated", ["", _groundExistingMaxDistance + 1]],
    ["groundExistingActiveFallback", ["", _groundExistingMaxDistance + 1]],
    ["groundExistingVirtualFallback", ["", _groundExistingMaxDistance + 1]],
    ["airAvailableActiveDedicated", ["", _airMaxDistance + 1]],
    ["airAvailableVirtualDedicated", ["", _airMaxDistance + 1]],
    ["airExistingActiveDedicated", ["", _airMaxDistance + 1]],
    ["airExistingVirtualDedicated", ["", _airMaxDistance + 1]]
];

private _updateCandidate = {
    params ["_candidateState", "_key", "_groupId", "_dist"];
    private _current = _candidateState get _key;
    if (_dist < (_current select 1)) then {
        _candidateState set [_key, [_groupId, _dist]];
    };
};

{
    private _groupId = _x;
    private _groupData = _groups get _groupId;
    if (isNil "_groupData") then { continue };
    if (_side != sideUnknown && {(_groupData get "side") != _side}) then { continue };

    private _groupType = _groupData get "groupType";
    private _transportRole = _groupData get "transportRole";
    private _isGroundCarrier = _groupType in _groundCarrierTypes;
    private _isAirCarrier = _groupType in _airCarrierTypes;
    if !(_isGroundCarrier || _isAirCarrier) then { continue };

    private _position = _groupData get "position";
    private _dist = _position distance2D _nearPos;
    private _activationKey = ["Virtual", "Active"] select (_groupData get "isActive");

    if (_isGroundCarrier) then {
        if (_dist > _groundAvailableMaxDistance) then { continue };
    } else {
        if (_dist > _airMaxDistance || {!_transportRole}) then { continue };
    };

    private _pickupCapacity = [_groupData] call FLO_fnc_transportGetPickupCapacity;
    if (_pickupCapacity < _requiredCapacity) then { continue };

    if (_isGroundCarrier) then {
        private _key = if (_transportRole) then {
            format ["groundAvailable%1Dedicated", _activationKey]
        } else {
            format ["groundAvailable%1Fallback", _activationKey]
        };
        [_state, _key, _groupId, _dist] call _updateCandidate;
    } else {
        [_state, format ["airAvailable%1Dedicated", _activationKey], _groupId, _dist] call _updateCandidate;
    };
} forEach _available;

{
    private _groupId = _x;
    private _groupData = _y;

    if (_groupId in _available || {_groupId in _active}) then { continue };
    if ((_groupData get "side") != _side) then { continue };
    if ((_groupData get "attachedGroups") isNotEqualTo []) then { continue };
    if ((_groupData get "missionLock") != "") then { continue };

    private _commanderOrder = _groupData get "commanderOrder";
    if (_commanderOrder != "" && {!(_commanderOrder in ["PATROL", "DEFEND", "", "TRANSPORT"])}) then { continue };

    private _groupType = _groupData get "groupType";
    private _transportRole = _groupData get "transportRole";
    private _isGroundCarrier = _groupType in _groundCarrierTypes;
    private _isAirCarrier = _groupType in _airCarrierTypes;
    if !(_isGroundCarrier || _isAirCarrier) then { continue };

    private _position = _groupData get "position";
    private _dist = _position distance2D _nearPos;
    private _activationKey = ["Virtual", "Active"] select (_groupData get "isActive");

    if (_isGroundCarrier) then {
        if (_dist > _groundExistingMaxDistance) then { continue };
    } else {
        if (_dist > _airMaxDistance || {!_transportRole}) then { continue };
    };

    private _pickupCapacity = [_groupData] call FLO_fnc_transportGetPickupCapacity;
    if (_pickupCapacity < _requiredCapacity) then { continue };

    if (_isGroundCarrier) then {
        private _key = if (_transportRole) then {
            format ["groundExisting%1Dedicated", _activationKey]
        } else {
            format ["groundExisting%1Fallback", _activationKey]
        };
        [_state, _key, _groupId, _dist] call _updateCandidate;
    } else {
        [_state, format ["airExisting%1Dedicated", _activationKey], _groupId, _dist] call _updateCandidate;
    };
} forEach _groups;

private _candidates = createHashMap;
{
    _candidates set [_x, (_state get _x) select 0];
} forEach (keys _state);

_candidates
