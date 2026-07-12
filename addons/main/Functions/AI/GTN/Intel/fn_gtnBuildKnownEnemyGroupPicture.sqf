/*
 * Function: FLO_fnc_gtnBuildKnownEnemyGroupPicture
 * Author: Frontline Operations Development Group
 * Description:
 *   Resolves fresh commander contact reports into the maintained hostile-group
 *   picture used by the common operating picture and transport safety logic.
 *   This is intelligence only and never owns or changes group orders.
 *
 * Arguments:
 * 0: Contact reports <ARRAY>
 * 1: Objective states <HASHMAP>
 * 2: Enemy side <SIDE>
 * 3: Freshness seconds <NUMBER>
 *
 * Return Value:
 * HASHMAP with groups, objectiveGroups, counts, and build time
 */

params [
    ["_contacts", [], [[]]],
    ["_objectives", createHashMap, [createHashMap]],
    ["_enemySide", east],
    ["_freshSeconds", 180, [0]]
];

private _resolvedGroups = createHashMap;
private _objectiveGroups = createHashMap;
private _groups = call FLO_fnc_virtualizationGetGroupMap;
private _cutoffTime = diag_tickTime - _freshSeconds;
private _reportResolutionRadius = 220;
private _freshContactCount = 0;

{
    _x params ["_contactPos", "_contactTime", "_contactStrength", "_contactType", "_contactConfidence", ["_sourceObject", objNull, [objNull]]];
    if (_contactTime < _cutoffTime) then { continue };

    _freshContactCount = _freshContactCount + 1;

    private _candidateIds = ["queryRadius", [_contactPos, _reportResolutionRadius, _enemySide, true]] call FLO_fnc_virtualizationSpatialIndex;
    private _resolvedAny = false;
    {
        private _groupId = _x;
        private _groupData = _groups get _groupId;
        if (isNil "_groupData") then { continue };

        private _groupType = _groupData get "groupType";
        if (_groupType in ["civilian", "ambient", "civ_pedestrian", "civ_building", "civilianVehicle", "civ_car", "helicopter", "jet", "air", "boat", "naval", "submarine"]) then {
            continue;
        };
        if (([_groupData] call FLO_fnc_virtualizationGetMountedTransport) != "") then { continue };
        if (([_groupData] call FLO_fnc_virtualizationGetTransportAttachment) != "") then { continue };

        private _entry = if (_groupId in _resolvedGroups) then {
            _resolvedGroups get _groupId
        } else {
            createHashMapFromArray [
                ["position", _groupData get "position"],
                ["lastSeen", _contactTime],
                ["confidence", _contactConfidence],
                ["contactCount", 0],
                ["groupType", _groupType],
                ["unitCount", _groupData get "unitCount"],
                ["commanderOrder", _groupData get "commanderOrder"],
                ["objectiveIds", []],
                ["isPlayerControlled", false]
            ]
        };

        _entry set ["position", _groupData get "position"];
        _entry set ["groupType", _groupType];
        _entry set ["unitCount", _groupData get "unitCount"];
        _entry set ["commanderOrder", _groupData get "commanderOrder"];
        _entry set ["isPlayerControlled", false];
        _entry set ["contactCount", (_entry get "contactCount") + 1];
        if (_contactTime > (_entry get "lastSeen")) then {
            _entry set ["lastSeen", _contactTime];
        };
        if (_contactConfidence > (_entry get "confidence")) then {
            _entry set ["confidence", _contactConfidence];
        };

        _resolvedGroups set [_groupId, _entry];
        _resolvedAny = true;
    } forEach _candidateIds;

    if (_resolvedAny) then { continue };
    if (isNull _sourceObject) then { continue };

    private _realTarget = [_sourceObject, _contactPos, _contactTime, _contactStrength, _contactConfidence] call FLO_fnc_gtnBuildObservedRealEnemyTarget;
    if ((keys _realTarget) isEqualTo []) then { continue };

    private _realGroupId = _realTarget get "groupId";
    private _realEntry = if (_realGroupId in _resolvedGroups) then {
        _resolvedGroups get _realGroupId
    } else {
        _realTarget
    };

    _realEntry set ["position", _realTarget get "position"];
    _realEntry set ["groupType", _realTarget get "groupType"];
    _realEntry set ["unitCount", _realTarget get "unitCount"];
    _realEntry set ["commanderOrder", _realTarget get "commanderOrder"];
    _realEntry set ["isPlayerControlled", true];
    _realEntry set ["contactCount", (_realEntry get "contactCount") + 1];
    if (_contactTime > (_realEntry get "lastSeen")) then {
        _realEntry set ["lastSeen", _contactTime];
    };
    if (_contactConfidence > (_realEntry get "confidence")) then {
        _realEntry set ["confidence", _contactConfidence];
    };

    _resolvedGroups set [_realGroupId, _realEntry];
} forEach _contacts;

{
    private _objectiveId = _x;
    private _objectiveGroupIds = [];

    {
        private _groupId = _x;
        private _entry = _resolvedGroups get _groupId;
        if ([(_entry get "position"), _objectiveId] call FLO_fnc_isPositionInObjective) then {
            _objectiveGroupIds pushBack _groupId;

            private _objectiveIds = _entry get "objectiveIds";
            _objectiveIds pushBackUnique _objectiveId;
            _entry set ["objectiveIds", _objectiveIds];
        };
    } forEach _resolvedGroups;

    if (_objectiveGroupIds isNotEqualTo []) then {
        _objectiveGroups set [_objectiveId, _objectiveGroupIds];
    };
} forEach _objectives;

createHashMapFromArray [
    ["groups", _resolvedGroups],
    ["objectiveGroups", _objectiveGroups],
    ["freshContactCount", _freshContactCount],
    ["groupCount", count _resolvedGroups],
    ["objectiveCount", count _objectiveGroups],
    ["builtAt", diag_tickTime]
]
