/*
 * Function: FLO_fnc_gtnBuildEnemyEngagementPicture
 * Author: Frontline Operations Development Group
 * Description:
 *   Resolves a commander-usable exact enemy-group picture from fresh contact
 *   reports using the maintained virtualization spatial index. This is the
 *   exact-target bridge between sensed commander intel and tactical group
 *   engagement behavior.
 *
 * Arguments:
 * 0: Contact reports <ARRAY>
 * 1: Objective states <HASHMAP>
 * 2: Enemy side <SIDE>
 * 3: Freshness seconds <NUMBER>
 *
 * Return Value:
 * HASHMAP with:
 *   "groups": HASHMAP groupId -> target data
 *   "objectiveGroups": HASHMAP objectiveId -> [groupIds]
 *   "freshContactCount": NUMBER
 *   "groupCount": NUMBER
 *   "objectiveCount": NUMBER
 *   "builtAt": NUMBER
 */

params [
    ["_contacts", [], [[]]],
    ["_objectives", createHashMap, [createHashMap]],
    ["_enemySide", east],
    ["_freshSeconds", 180, [0]]
];

private _resolvedGroups = createHashMap;
private _objectiveGroups = createHashMap;
private _groups = FLO_virtualGroups get "_groups";
private _cutoffTime = diag_tickTime - _freshSeconds;
private _reportResolutionRadius = 220;
private _freshContactCount = 0;

{
    _x params ["_contactPos", "_contactTime", "_contactStrength", "_contactType", "_contactConfidence"];
    if (_contactTime < _cutoffTime) then { continue };

    _freshContactCount = _freshContactCount + 1;

    private _candidateIds = ["queryRadius", [_contactPos, _reportResolutionRadius, _enemySide, true]] call FLO_fnc_virtualizationSpatialIndex;
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

        private _entry = if (_groupId in (keys _resolvedGroups)) then {
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
                ["objectiveIds", []]
            ]
        };

        _entry set ["position", _groupData get "position"];
        _entry set ["groupType", _groupType];
        _entry set ["unitCount", _groupData get "unitCount"];
        _entry set ["commanderOrder", _groupData get "commanderOrder"];
        _entry set ["contactCount", (_entry get "contactCount") + 1];
        if (_contactTime > (_entry get "lastSeen")) then {
            _entry set ["lastSeen", _contactTime];
        };
        if (_contactConfidence > (_entry get "confidence")) then {
            _entry set ["confidence", _contactConfidence];
        };

        _resolvedGroups set [_groupId, _entry];
    } forEach _candidateIds;
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
    } forEach (keys _resolvedGroups);

    if (count _objectiveGroupIds > 0) then {
        _objectiveGroups set [_objectiveId, _objectiveGroupIds];
    };
} forEach _objectives;

createHashMapFromArray [
    ["groups", _resolvedGroups],
    ["objectiveGroups", _objectiveGroups],
    ["freshContactCount", _freshContactCount],
    ["groupCount", count (keys _resolvedGroups)],
    ["objectiveCount", count (keys _objectiveGroups)],
    ["builtAt", diag_tickTime]
]
