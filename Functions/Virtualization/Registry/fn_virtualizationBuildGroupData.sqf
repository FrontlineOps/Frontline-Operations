/*
 * Function: FLO_fnc_virtualizationBuildGroupData
 */

params [
    ["_position", [0,0,0], [[]]],
    ["_groupType", "infantry", [""]],
    ["_groupCfg", configNull, [configNull, []]],
    ["_homeObjective", "", [""]],
    ["_unitCount", -1, [0]],
    ["_side", east, [east]],
    ["_spawnClass", "", [""]]
];

if (isNil "_groupCfg") then {
    _groupCfg = configNull;
};

if (isNil "_spawnClass") then {
    _spawnClass = "";
};

_position = [_position] call FLO_fnc_virtualizationNormalizePosition;

private _resolvedUnitCount = _unitCount;
if (_resolvedUnitCount <= 0) then {
    if (_groupType in ["civilian", "civ_pedestrian", "civ_building"]) then {
        _resolvedUnitCount = 1 + floor random 3;
    } else {
        if (_groupType in ["civilianVehicle", "civ_car"]) then {
            _resolvedUnitCount = 1;
        } else {
            _resolvedUnitCount = [_groupType, _side] call FLO_fnc_getGroupTypeCount;
        };
    };
};

private _groupData = createHashMapFromArray [
    ["position", _position],
    ["spawnPosition", _position],
    ["groupType", _groupType],
    ["groupCfg", _groupCfg],
    ["spawnClass", _spawnClass],
    ["homeObjective", _homeObjective],
    ["unitCount", _resolvedUnitCount],
    ["side", _side],
    ["isActive", false],
    ["alwaysActive", false],
    ["realGroup", grpNull],
    ["realVehicles", []],
    ["state", "idle"],
    ["lastStateChangeTime", diag_tickTime],
    ["inCombat", false],
    ["waypoints", []],
    ["currentWaypointIndex", 0],
    ["autoPatrol", false],
    ["patrolConfig", []],
    ["noWaypoints", false],
    ["virtualSpeed", 0],
    ["lastMoveTime", -1],
    ["lastSentryTime", 0],
    ["loiterStartTime", 0],
    ["tempWaypointCount", 0],
    ["updatePhase", -1],
    ["pathToken", -1],
    ["pathTargetPos", []],
    ["pathAllowTrails", false],
    ["pathStartedAt", -1],
    ["pathSource", ""],
    ["pathWaypointSettings", []],
    ["vehicleType", ""],
    ["comp", []],
    ["missionLock", ""],
    ["missionType", ""],
    ["replacementState", ""],
    ["activationDeferred", false],
    ["activationDeferredAt", -1],
    ["activationDeferredPos", []],
    ["engagementActive", false],
    ["engagementTargetGroupId", ""],
    ["engagementTargetPos", []],
    ["engagementTargetObjective", ""],
    ["engagementReason", ""],
    ["engagementExpiresAt", -1],
    ["engagementLeashMeters", 0],
    ["reinforcementTargetPos", []],
    ["reinforcementRequestedObjective", ""],
    ["reinforcementDeliveryObjective", ""],
    ["forceVirtual", false],
    ["commanderOrder", ""],
    ["executionState", ""],
    ["orderTargetPos", []],
    ["orderMode", ""],
    ["attackObjective", ""],
    ["defendObjective", ""],
    ["defendLeaseIssuedAt", -1],
    ["defendLeaseUntil", -1],
    ["aaDeployState", ""],
    ["aaDeployTargetPos", []],
    ["aaDeployTargetObjective", ""],
    ["isStrategicAA", false],
    ["linkedObjectives", []],
    ["attachedTo", ""],
    ["attachedGroups", []],
    ["attachedType", ""],
    ["transportRole", false],
    ["isTransport", false],
    ["dismountAtWaypoint", -1],
    ["transportInsertMode", ""],
    ["transportInsertPos", []],
    ["transportLandCommandIssued", false],
    ["transportUnloadCommandIssued", false],
    ["transportUnloadIssuedAt", -1],
    ["postDismountWaypoint", []],
    ["mountedIn", ""],
    ["organicPackageRole", ""],
    ["organicPackageParentGroupId", ""],
    ["garrisonPosition", _position],
    ["garrisonObjective", ""],
    ["civilianRole", ""],
    ["civilianObjective", _homeObjective],
    ["civilianAnchorPos", _position],
    ["civilianRouteAnchors", []],
    ["civilianKnowledgeBias", 1],
    ["civilianTrustBias", 1],
    ["civilianLastIntelAt", -1],
    ["civilianLastMood", ""],
    ["civilianRoutineState", ""]
];

private _initialAssetComposition = [_groupType, _resolvedUnitCount, _side] call FLO_fnc_virtualizationSelectInitialAssetComposition;
if (_initialAssetComposition isNotEqualTo []) then {
    [_groupData, _initialAssetComposition] call FLO_fnc_virtualizationSetAssetComposition;
};

_groupData
