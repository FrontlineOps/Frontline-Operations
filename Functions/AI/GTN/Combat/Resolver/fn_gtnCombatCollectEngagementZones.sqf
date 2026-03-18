/*
 * Function: FLO_fnc_gtnCombatCollectEngagementZones
 * Author: Frontline Operations Development Group
 * Description:
 *   Builds local EAST/WEST engagement zones from the shared virtualization
 *   spatial index. Zones are anchored on the nearest opposing contact so fights
 *   do not merge across long transitive chains.
 *
 * Arguments:
 *   0: Direct-combat virtual groups map <HASHMAP>
 *   1: EAST seed group IDs <ARRAY>
 *   2: Engagement distance <NUMBER>
 *
 * Return Value:
 *   Engagement zones <ARRAY>
 */

params ["_combatGroups", "_eastSeeds", "_engagementDist"];

private _zones = [];
private _assigned = createHashMap;

{
    private _seedEastId = _x;
    if (_assigned getOrDefault [_seedEastId, false]) then { continue };

    private _seedEastData = _combatGroups get _seedEastId;
    if (isNil "_seedEastData") then { continue };

    private _seedEastPos = _seedEastData get "position";
    private _nearIds = ["queryRadius", [_seedEastPos, _engagementDist]] call FLO_fnc_virtualizationSpatialIndex;
    private _closestWestId = "";
    private _closestWestData = createHashMap;
    private _closestDist = _engagementDist + 1;

    {
        private _otherId = _x;
        if (_otherId isEqualTo _seedEastId) then { continue };
        if (_assigned getOrDefault [_otherId, false]) then { continue };

        private _otherData = _combatGroups get _otherId;
        if (isNil "_otherData") then { continue };
        if !((_otherData get "side") isEqualTo west) then { continue };

        private _dist = _seedEastPos distance2D (_otherData get "position");
        if (_dist > _engagementDist) then { continue };
        if (_dist >= _closestDist) then { continue };

        _closestWestId = _otherId;
        _closestWestData = _otherData;
        _closestDist = _dist;
    } forEach _nearIds;

    if (_closestWestId == "") then { continue };

    private _closestWestPos = _closestWestData get "position";
    private _anchorPos = [
        ((_seedEastPos select 0) + (_closestWestPos select 0)) * 0.5,
        ((_seedEastPos select 1) + (_closestWestPos select 1)) * 0.5,
        0
    ];
    private _candidateIds = ["queryRadius", [_anchorPos, _engagementDist]] call FLO_fnc_virtualizationSpatialIndex;
    private _eastCandidates = [];
    private _westCandidates = [];

    {
        private _candidateId = _x;
        if (_assigned getOrDefault [_candidateId, false]) then { continue };

        private _candidateData = _combatGroups get _candidateId;
        if (isNil "_candidateData") then { continue };

        private _candidateSide = _candidateData get "side";
        if !(_candidateSide in [east, west]) then { continue };
        if ((_candidateData get "position") distance2D _anchorPos > _engagementDist) then { continue };

        if (_candidateSide isEqualTo east) then {
            _eastCandidates pushBack [_candidateId, _candidateData];
        } else {
            _westCandidates pushBack [_candidateId, _candidateData];
        };
    } forEach _candidateIds;

    if (count _eastCandidates == 0 || {count _westCandidates == 0}) then { continue };

    private _eastRefs = _eastCandidates select {
        private _candidatePos = (_x select 1) get "position";
        private _hasEnemyContact = false;
        {
            if (_candidatePos distance2D ((_x select 1) get "position") <= _engagementDist) exitWith {
                _hasEnemyContact = true;
            };
        } forEach _westCandidates;
        _hasEnemyContact
    };

    if (count _eastRefs == 0) then { continue };

    private _westRefs = _westCandidates select {
        private _candidatePos = (_x select 1) get "position";
        private _hasEnemyContact = false;
        {
            if (_candidatePos distance2D ((_x select 1) get "position") <= _engagementDist) exitWith {
                _hasEnemyContact = true;
            };
        } forEach _eastRefs;
        _hasEnemyContact
    };

    if (count _westRefs == 0) then { continue };

    _eastRefs = _eastRefs select {
        private _candidatePos = (_x select 1) get "position";
        private _hasEnemyContact = false;
        {
            if (_candidatePos distance2D ((_x select 1) get "position") <= _engagementDist) exitWith {
                _hasEnemyContact = true;
            };
        } forEach _westRefs;
        _hasEnemyContact
    };

    if (count _eastRefs == 0) then { continue };

    private _minContactDist = 1e9;
    private _contactPos = _anchorPos;

    {
        private _eastPos = (_x select 1) get "position";
        {
            private _westPos = (_x select 1) get "position";
            private _dist = _eastPos distance2D _westPos;
            if (_dist > _engagementDist) then { continue };
            if (_dist >= _minContactDist) then { continue };

            _minContactDist = _dist;
            _contactPos = [
                ((_eastPos select 0) + (_westPos select 0)) * 0.5,
                ((_eastPos select 1) + (_westPos select 1)) * 0.5,
                0
            ];
        } forEach _westRefs;
    } forEach _eastRefs;

    if (_minContactDist > _engagementDist) then { continue };

    _zones pushBack [_eastRefs, _westRefs, _contactPos, _minContactDist];

    {
        _assigned set [_x select 0, true];
    } forEach _eastRefs;

    {
        _assigned set [_x select 0, true];
    } forEach _westRefs;
} forEach _eastSeeds;

_zones
