/*
 * Function: FLO_fnc_virtualizationAdvanceDefaultWaypoint
 */

params ["_groupId", "_groupData", "_currentIdx", "_waypoints", "_isPatrol"];

if (_isPatrol) exitWith {
    private _nextIdx = _currentIdx + 1;
    if (_nextIdx >= count _waypoints) then {
        _nextIdx = 0;
    };
    _groupData set ["currentWaypointIndex", _nextIdx];
};

_waypoints deleteAt _currentIdx;
_groupData set ["waypoints", _waypoints];
private _dismountIdx = _groupData get "dismountAtWaypoint";
if (_dismountIdx > _currentIdx) then {
    _groupData set ["dismountAtWaypoint", _dismountIdx - 1];
};

if (_waypoints isNotEqualTo []) exitWith {
    _groupData set ["currentWaypointIndex", _currentIdx min (count _waypoints - 1)];
    [_groupData, "moving"] call FLO_fnc_virtualizationSetRuntimeState;
};

private _commanderOrder = _groupData get "commanderOrder";
private _replacementState = _groupData get "replacementState";
private _holdAtDestination = _commanderOrder in ["ATTACK", "DEFEND"] || {([_groupData] call FLO_fnc_virtualizationGetAADeployState) == "DEPLOYED"};

[_groupData, [["idle", "holding"] select (_holdAtDestination), "moving"] select (_replacementState != "")] call FLO_fnc_virtualizationSetRuntimeState;
_groupData set ["currentWaypointIndex", 0];

if (_replacementState == "REINFORCE") then {
    [_groupId] call FLO_fnc_virtualizationFinalizeReinforcement;
};
