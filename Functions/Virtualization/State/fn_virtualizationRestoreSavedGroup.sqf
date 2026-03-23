/*
 * Function: FLO_fnc_virtualizationRestoreSavedGroup
 * Author: Frontline Operations Development Group
 * Description:
 *   Restores the canonical saved virtualization schema onto a newly created
 *   virtual-group record.
 *
 * Arguments:
 * 0: Live group data <HASHMAP>
 * 1: Saved group data <HASHMAP>
 *
 * Return Value:
 * BOOL - True when restore completed
 */

params ["_groupData", "_savedData"];

[_groupData, _savedData get "state"] call FLO_fnc_virtualizationSetRuntimeState;
_groupData set ["waypoints", _savedData get "waypoints"];
_groupData set ["currentWaypointIndex", _savedData get "currentWaypointIndex"];
_groupData set ["alwaysActive", _savedData get "alwaysActive"];
_groupData set ["noWaypoints", _savedData get "noWaypoints"];
_groupData set ["forceVirtual", _savedData get "forceVirtual"];
_groupData set ["garrisonPosition", _savedData get "garrisonPosition"];
_groupData set ["garrisonObjective", _savedData get "garrisonObjective"];

[_groupData] call FLO_fnc_virtualizationClearMissionLock;
private _missionLock = _savedData get "missionLock";
if (_missionLock != "") then {
    [_groupData, _missionLock, _savedData get "missionType"] call FLO_fnc_virtualizationSetMissionLock;
};

[_groupData] call FLO_fnc_virtualizationClearCommanderOrder;
private _commanderOrder = _savedData get "commanderOrder";
if (_commanderOrder != "") then {
    _groupData set ["commanderOrder", _commanderOrder];
    _groupData set ["orderTargetPos", _savedData get "orderTargetPos"];
    _groupData set ["orderMode", _savedData get "orderMode"];
    _groupData set ["attackObjective", _savedData get "attackObjective"];
    _groupData set ["defendObjective", _savedData get "defendObjective"];
    _groupData set ["defendLeaseIssuedAt", _savedData get "defendLeaseIssuedAt"];
    _groupData set ["defendLeaseUntil", _savedData get "defendLeaseUntil"];
};

[_groupData] call FLO_fnc_virtualizationClearExecutionState;
private _executionState = _savedData get "executionState";
if (_executionState != "") then {
    [_groupData, _executionState] call FLO_fnc_virtualizationSetExecutionState;
};

[_groupData] call FLO_fnc_virtualizationClearPathRequest;
if ((_savedData get "pathToken") >= 0) then {
    [
        _groupData,
        _savedData get "pathToken",
        _savedData get "pathTargetPos",
        _savedData get "pathAllowTrails",
        _savedData get "pathStartedAt",
        _savedData get "pathSource",
        _savedData get "pathWaypointSettings"
    ] call FLO_fnc_virtualizationSetPendingPathRequest;
};

[_groupData] call FLO_fnc_virtualizationClearAADeployState;
private _aaDeployState = _savedData get "aaDeployState";
if (_aaDeployState != "") then {
    [
        _groupData,
        _aaDeployState,
        _savedData get "aaDeployTargetPos",
        _savedData get "aaDeployTargetObjective",
        _savedData get "isStrategicAA"
    ] call FLO_fnc_virtualizationSetAADeployState;
};

[_groupData] call FLO_fnc_virtualizationClearTransportAttachment;
private _attachedTo = _savedData get "attachedTo";
if (_attachedTo != "") then {
    [_groupData, _attachedTo, _savedData get "attachedType"] call FLO_fnc_virtualizationSetTransportAttachment;
};
[_groupData, _savedData get "attachedGroups"] call FLO_fnc_virtualizationSetTransportPassengers;
_groupData set ["dismountAtWaypoint", _savedData get "dismountAtWaypoint"];
[_groupData] call FLO_fnc_virtualizationClearMountedIn;
private _mountedIn = _savedData get "mountedIn";
if (_mountedIn != "") then {
    [_groupData, _mountedIn] call FLO_fnc_virtualizationSetMountedIn;
};

[_groupData] call FLO_fnc_virtualizationClearReplacementTransit;
switch (_savedData get "replacementState") do {
    case "REINFORCE": {
        [
            _groupData,
            _savedData get "reinforcementTargetPos",
            _savedData get "reinforcementRequestedObjective",
            _savedData get "reinforcementDeliveryObjective"
        ] call FLO_fnc_virtualizationMarkReinforcementTransit;
    };
    case "AA_DEPLOY": {
        [
            _groupData,
            _savedData get "reinforcementTargetPos",
            _savedData get "reinforcementRequestedObjective",
            _savedData get "reinforcementDeliveryObjective"
        ] call FLO_fnc_virtualizationMarkStaticAAReplacementTransit;
    };
};

true

