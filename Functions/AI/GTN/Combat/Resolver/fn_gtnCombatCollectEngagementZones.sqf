/*
 * Function: FLO_fnc_gtnCombatCollectEngagementZones
 * Author: Frontline Operations Development Group
 * Description:
 *   Builds local engagement zones from the shared virtualization spatial index.
 *   Zones are anchored on the nearest opposing contact so fights do not merge
 *   across long transitive chains.
 *
 * Arguments:
 *   0: Direct-combat virtual groups map <HASHMAP>
 *   1: Seed group IDs <ARRAY>
 *   2: Seed side <SIDE>
 *   3: Opponent side <SIDE>
 *   4: Engagement distance <NUMBER>
 *   5: Seed cell size <NUMBER>
 *   6: Opponent threat cells <HASHMAP>
 *
 * Return Value:
 *   Engagement zones <ARRAY>
 */

params [
    "_combatGroups",
    "_seedIds",
    "_seedSide",
    "_opponentSide",
    "_engagementDist",
    ["_seedCellSize", 150, [0]],
    ["_opponentThreatCells", createHashMap]
];

private _threatCellRadius = ceil (_engagementDist / _seedCellSize);
private _cellKeyBase = ceil (worldSize / _seedCellSize) + _threatCellRadius + 8;
private _cellKeyStride = (_cellKeyBase * 2) + 1;

private _zones = [];
private _assigned = createHashMap;

{
    private _seedId = _x;
    if (_assigned getOrDefault [_seedId, false]) then { continue };

    private _seedData = _combatGroups get _seedId;
    if (isNil "_seedData") then { continue };

    private _seedPos = _seedData get "position";
    private _seedCellX = floor ((_seedPos select 0) / _seedCellSize);
    private _seedCellY = floor ((_seedPos select 1) / _seedCellSize);
    private _seedCellKey = ((_seedCellX + _cellKeyBase) * _cellKeyStride) + (_seedCellY + _cellKeyBase);
    private _hasOpponentCell = _opponentThreatCells getOrDefault [_seedCellKey, false];

    if (!_hasOpponentCell) then { continue };

    private _nearIds = ["queryRadius", [_seedPos, _engagementDist, _opponentSide, true]] call FLO_fnc_virtualizationSpatialIndex;
    private _closestOpponentId = "";
    private _closestOpponentData = createHashMap;
    private _closestDist = _engagementDist + 1;

    {
        private _otherId = _x;
        if (_otherId isEqualTo _seedId) then { continue };
        if (_assigned getOrDefault [_otherId, false]) then { continue };

        private _otherData = _combatGroups get _otherId;
        if (isNil "_otherData") then { continue };
        if !((_otherData get "side") isEqualTo _opponentSide) then { continue };

        private _dist = _seedPos distance2D (_otherData get "position");
        if (_dist > _engagementDist) then { continue };
        if (_dist >= _closestDist) then { continue };

        _closestOpponentId = _otherId;
        _closestOpponentData = _otherData;
        _closestDist = _dist;
    } forEach _nearIds;

    if (_closestOpponentId == "") then { continue };

    private _closestOpponentPos = _closestOpponentData get "position";
    private _anchorPos = [
        ((_seedPos select 0) + (_closestOpponentPos select 0)) * 0.5,
        ((_seedPos select 1) + (_closestOpponentPos select 1)) * 0.5,
        0
    ];
    private _seedCandidateIds = ["queryRadius", [_anchorPos, _engagementDist, _seedSide, true]] call FLO_fnc_virtualizationSpatialIndex;
    private _opponentCandidateIds = ["queryRadius", [_anchorPos, _engagementDist, _opponentSide, true]] call FLO_fnc_virtualizationSpatialIndex;
    private _seedCandidates = [];
    private _opponentCandidates = [];

    {
        private _candidateId = _x;
        if (_assigned getOrDefault [_candidateId, false]) then { continue };

        private _candidateData = _combatGroups get _candidateId;
        if (isNil "_candidateData") then { continue };

        _seedCandidates pushBack [_candidateId, _candidateData];
    } forEach _seedCandidateIds;

    {
        private _candidateId = _x;
        if (_assigned getOrDefault [_candidateId, false]) then { continue };

        private _candidateData = _combatGroups get _candidateId;
        if (isNil "_candidateData") then { continue };

        _opponentCandidates pushBack [_candidateId, _candidateData];
    } forEach _opponentCandidateIds;

    private _eastCandidates = [];
    private _westCandidates = [];
    if (_seedSide isEqualTo east) then {
        _eastCandidates = _seedCandidates;
        _westCandidates = _opponentCandidates;
    } else {
        _eastCandidates = _opponentCandidates;
        _westCandidates = _seedCandidates;
    };

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
} forEach _seedIds;

_zones
