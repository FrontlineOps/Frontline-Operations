/*
 * Function: FLO_fnc_virtualizationSerializeGroup
 * Author: Frontline Operations Development Group
 * Description:
 *   Serializes the canonical virtual-group schema for persistence.
 *
 * Arguments:
 * 0: Group data <HASHMAP>
 *
 * Return Value:
 * HASHMAP - Serialized group record
 */

params ["_groupData"];

createHashMapFromArray [
    ["position", _groupData get "position"],
    ["groupType", _groupData get "groupType"],
    ["spawnClass", _groupData get "spawnClass"],
    ["homeObjective", _groupData get "homeObjective"],
    ["unitCount", _groupData get "unitCount"],
    ["side", _groupData get "side"],
    ["state", _groupData get "state"],
    ["waypoints", _groupData get "waypoints"],
    ["currentWaypointIndex", _groupData get "currentWaypointIndex"],
    ["autoPatrol", _groupData get "autoPatrol"],
    ["patrolConfig", _groupData get "patrolConfig"],
    ["missionLock", _groupData get "missionLock"],
    ["missionType", _groupData get "missionType"],
    ["replacementState", _groupData get "replacementState"],
    ["engagementActive", _groupData get "engagementActive"],
    ["engagementTargetGroupId", _groupData get "engagementTargetGroupId"],
    ["engagementTargetPos", _groupData get "engagementTargetPos"],
    ["engagementTargetObjective", _groupData get "engagementTargetObjective"],
    ["engagementReason", _groupData get "engagementReason"],
    ["engagementExpiresAt", _groupData get "engagementExpiresAt"],
    ["engagementLeashMeters", _groupData get "engagementLeashMeters"],
    ["reinforcementTargetPos", _groupData get "reinforcementTargetPos"],
    ["reinforcementRequestedObjective", _groupData get "reinforcementRequestedObjective"],
    ["reinforcementDeliveryObjective", _groupData get "reinforcementDeliveryObjective"],
    ["pathToken", _groupData get "pathToken"],
    ["pathTargetPos", _groupData get "pathTargetPos"],
    ["pathAllowTrails", _groupData get "pathAllowTrails"],
    ["pathStartedAt", _groupData get "pathStartedAt"],
    ["pathSource", _groupData get "pathSource"],
    ["pathWaypointSettings", _groupData get "pathWaypointSettings"],
    ["comp", _groupData get "comp"],
    ["alwaysActive", _groupData get "alwaysActive"],
    ["commanderOrder", _groupData get "commanderOrder"],
    ["executionState", _groupData get "executionState"],
    ["orderTargetPos", _groupData get "orderTargetPos"],
    ["orderMode", _groupData get "orderMode"],
    ["attackObjective", _groupData get "attackObjective"],
    ["campaignOperationId", _groupData get "campaignOperationId"],
    ["defendObjective", _groupData get "defendObjective"],
    ["defendLeaseIssuedAt", _groupData get "defendLeaseIssuedAt"],
    ["defendLeaseUntil", _groupData get "defendLeaseUntil"],
    ["noWaypoints", _groupData get "noWaypoints"],
    ["forceVirtual", _groupData get "forceVirtual"],
    ["aaDeployState", _groupData get "aaDeployState"],
    ["aaDeployTargetPos", _groupData get "aaDeployTargetPos"],
    ["aaDeployTargetObjective", _groupData get "aaDeployTargetObjective"],
    ["isStrategicAA", _groupData get "isStrategicAA"],
    ["attachedTo", _groupData get "attachedTo"],
    ["attachedGroups", _groupData get "attachedGroups"],
    ["attachedType", _groupData get "attachedType"],
    ["transportRole", _groupData get "transportRole"],
    ["isTransport", _groupData get "isTransport"],
    ["dismountAtWaypoint", _groupData get "dismountAtWaypoint"],
    ["transportInsertMode", _groupData get "transportInsertMode"],
    ["transportInsertPos", _groupData get "transportInsertPos"],
    ["transportLandCommandIssued", _groupData get "transportLandCommandIssued"],
    ["transportUnloadCommandIssued", _groupData get "transportUnloadCommandIssued"],
    ["transportUnloadIssuedAt", _groupData get "transportUnloadIssuedAt"],
    ["postDismountWaypoint", _groupData get "postDismountWaypoint"],
    ["mountedIn", _groupData get "mountedIn"],
    ["organicPackageRole", _groupData get "organicPackageRole"],
    ["organicPackageParentGroupId", _groupData get "organicPackageParentGroupId"],
    ["garrisonPosition", _groupData get "garrisonPosition"],
    ["garrisonObjective", _groupData get "garrisonObjective"],
    ["civilianRole", _groupData get "civilianRole"],
    ["civilianObjective", _groupData get "civilianObjective"],
    ["civilianAnchorPos", _groupData get "civilianAnchorPos"],
    ["civilianHomeAnchorPos", _groupData get "civilianHomeAnchorPos"],
    ["civilianRoutineAnchorPos", _groupData get "civilianRoutineAnchorPos"],
    ["civilianRouteAnchors", _groupData get "civilianRouteAnchors"],
    ["civilianKnowledgeBias", _groupData get "civilianKnowledgeBias"],
    ["civilianTrustBias", _groupData get "civilianTrustBias"],
    ["civilianLastIntelAt", _groupData get "civilianLastIntelAt"],
    ["civilianLastMood", _groupData get "civilianLastMood"],
    ["civilianRoutineState", _groupData get "civilianRoutineState"],
    ["civilianLastRoutineAt", _groupData get "civilianLastRoutineAt"],
    ["civilianRoutineUntil", _groupData get "civilianRoutineUntil"]
]

