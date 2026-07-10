/*
 * Function: FLO_fnc_logisticsNetworkCreateReplacement
 * Author: Frontline Operations Development Group
 * Description:
 *   Creates a replacement virtual group and assigns its reinforcement route.
 *
 * Arguments:
 *   0: Logistics network object <HASHMAP>
 *   1: Group type <STRING>
 *   2: Spawn position <ARRAY>
 *   3: Delivery objective ID <STRING>
 *   4: Source objective ID <STRING> - Default ""
 *   5: Requested objective ID <STRING> - Default delivery objective
 *   6: Perf accumulator <HASHMAP> - Optional
 *
 * Return Value:
 *   STRING - New virtual group ID or empty string
 */

params ["_net", "_groupType", "_spawnPos", "_deliveryObjectiveId", ["_sourceObjId", ""], ["_requestedObjectiveId", ""], ["_perf", nil]];

private _managedSide = _net get "_managedSide";
private _hasPerf = !isNil "_perf" && {_perf isEqualType createHashMap};
if (_requestedObjectiveId == "") then {
    _requestedObjectiveId = _deliveryObjectiveId;
};

if !([_spawnPos] call FLO_fnc_validateGroupPosition) exitWith {
    ["LOGISTICS", 1, format ["Invalid spawn position %1 for %2 reinforcement", _spawnPos, _groupType]] call FLO_fnc_log;
    ""
};

private _targetPos = _spawnPos;
if (_deliveryObjectiveId != "") then {
    private _objData = FLO_Objectives get _deliveryObjectiveId;
    if ((_objData get "owner") isNotEqualTo _managedSide) exitWith {
        ["LOGISTICS", 2, format ["Delivery objective %1 no longer owned by managed side", _deliveryObjectiveId]] call FLO_fnc_log;
        ""
    };
    if !([_deliveryObjectiveId] call FLO_fnc_campaignIsObjectiveIntegrated) exitWith {
        ["LOGISTICS", 2, format ["Delivery objective %1 is not integrated territory", _deliveryObjectiveId]] call FLO_fnc_log;
        ""
    };
    _targetPos = _objData get "position";
};

if !([_targetPos] call FLO_fnc_validateGroupPosition) exitWith {
    ["LOGISTICS", 1, format ["Invalid target position %1 for %2 reinforcement to %3", _targetPos, _groupType, _deliveryObjectiveId]] call FLO_fnc_log;
    ""
};

private _createGroupT0 = diag_tickTime;
private _unitCount = [_groupType, _managedSide] call FLO_fnc_getGroupTypeCount;
private _newGroupId = [_spawnPos, _groupType, nil, _deliveryObjectiveId, _unitCount, _managedSide] call FLO_fnc_createVirtualGroup;
if (_hasPerf) then {
    _perf set ["dispatchCreateGroupMs", (_perf get "dispatchCreateGroupMs") + ((diag_tickTime - _createGroupT0) * 1000)];
};
if (_newGroupId == "") exitWith { "" };

private _groups = FLO_virtualGroups get "_groups";
private _groupData = _groups get _newGroupId;
private _wps = [[_targetPos, "MOVE", "SAFE", "NORMAL", "COLUMN", "GREEN", 20]];

private _transitT0 = diag_tickTime;
[_groupData, _targetPos, _requestedObjectiveId, _deliveryObjectiveId] call FLO_fnc_virtualizationMarkReinforcementTransit;
if (_hasPerf) then {
    _perf set ["dispatchCreateTransitMs", (_perf get "dispatchCreateTransitMs") + ((diag_tickTime - _transitT0) * 1000)];
};

if (_groupType in ["motorized", "mechanized"]) then {
    private _organicT0 = diag_tickTime;
    [_newGroupId, _groupData, true, _targetPos] call FLO_fnc_virtualizationCreateOrganicPackageDismount;
    if (_hasPerf) then {
        _perf set ["dispatchCreateOrganicMs", (_perf get "dispatchCreateOrganicMs") + ((diag_tickTime - _organicT0) * 1000)];
    };
};

if (_groupType isEqualTo "static_aa") then {
    private _staticTransitT0 = diag_tickTime;
    _groupData set ["forceVirtual", true];
    _groupData set ["alwaysActive", false];
    _groupData set ["noWaypoints", false];
    [_groupData, _targetPos, _requestedObjectiveId, _deliveryObjectiveId] call FLO_fnc_virtualizationMarkStaticAAReplacementTransit;
    _groupData set ["homeObjective", _deliveryObjectiveId];
    _wps = [[_targetPos, "MOVE", "SAFE", "NORMAL", "COLUMN", "GREEN", 80]];
    if (_hasPerf) then {
        _perf set ["dispatchCreateTransitMs", (_perf get "dispatchCreateTransitMs") + ((diag_tickTime - _staticTransitT0) * 1000)];
    };
};

private _usesRoadRouting = !(_groupType in ["helicopter", "air", "jet", "boat", "naval", "submarine"]);
private _allowTrails = _groupType in ["infantry"];
private _sourceTag = ["LOGI_REINF", "LOGI_STATIC_AA"] select (_groupType isEqualTo "static_aa");
private _waypointT0 = diag_tickTime;
[_newGroupId, _wps, _usesRoadRouting, _allowTrails, _sourceTag] call FLO_fnc_updateVirtualGroupWaypoints;
if (_hasPerf) then {
    _perf set ["dispatchCreateWaypointMs", (_perf get "dispatchCreateWaypointMs") + ((diag_tickTime - _waypointT0) * 1000)];
};

_newGroupId
