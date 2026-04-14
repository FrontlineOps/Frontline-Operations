/*
 * Function: FLO_fnc_gtnCombatCollectEngagementZones
 * Author: Frontline Operations Development Group
 * Description:
 *   Builds local engagement zones from cached combat cell buckets. Zones are
 *   anchored on the nearest opposing contact so fights do not merge across
 *   long transitive chains.
 *
 * Arguments:
 *   0: Direct-combat virtual groups map <HASHMAP>
 *   1: Seed group IDs <ARRAY>
 *   2: Seed side <SIDE>
 *   3: Opponent side <SIDE>
 *   4: Engagement distance <NUMBER>
 *   5: Seed cell size <NUMBER>
 *   6: Opponent threat cells <HASHMAP>
 *   7: Seed-side groups by cell <HASHMAP>
 *   8: Opponent-side groups by cell <HASHMAP>
 *   9: Cell key base <NUMBER>
 *  10: Cell key stride <NUMBER>
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
    ["_opponentThreatCells", createHashMap],
    ["_seedGroupsByCell", createHashMap],
    ["_opponentGroupsByCell", createHashMap],
    ["_cellKeyBase", -1, [0]],
    ["_cellKeyStride", -1, [0]]
];

private _threatCellRadius = ceil (_engagementDist / _seedCellSize);
if (_cellKeyBase < 0 || {_cellKeyStride < 1}) then {
    _cellKeyBase = ceil (worldSize / _seedCellSize) + _threatCellRadius + 8;
    _cellKeyStride = (_cellKeyBase * 2) + 1;
};

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
    if !(_opponentThreatCells getOrDefault [_seedCellKey, false]) then { continue };

    private _closestOpponentId = "";
    private _closestOpponentData = createHashMap;
    private _closestDist = _engagementDist + 1;

    for "_xCell" from (_seedCellX - _threatCellRadius) to (_seedCellX + _threatCellRadius) do {
        for "_yCell" from (_seedCellY - _threatCellRadius) to (_seedCellY + _threatCellRadius) do {
            private _cellKey = ((_xCell + _cellKeyBase) * _cellKeyStride) + (_yCell + _cellKeyBase);
            private _opponentIds = _opponentGroupsByCell getOrDefault [_cellKey, []];

            {
                private _otherId = _x;
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
            } forEach _opponentIds;
        };
    };

    if (_closestOpponentId == "") then { continue };

    private _closestOpponentPos = _closestOpponentData get "position";
    private _anchorPos = [
        ((_seedPos select 0) + (_closestOpponentPos select 0)) * 0.5,
        ((_seedPos select 1) + (_closestOpponentPos select 1)) * 0.5,
        0
    ];
    private _anchorCellX = floor ((_anchorPos select 0) / _seedCellSize);
    private _anchorCellY = floor ((_anchorPos select 1) / _seedCellSize);
    private _seedCandidates = [];
    private _opponentCandidates = [];

    for "_xCell" from (_anchorCellX - _threatCellRadius) to (_anchorCellX + _threatCellRadius) do {
        for "_yCell" from (_anchorCellY - _threatCellRadius) to (_anchorCellY + _threatCellRadius) do {
            private _cellKey = ((_xCell + _cellKeyBase) * _cellKeyStride) + (_yCell + _cellKeyBase);

            {
                private _candidateId = _x;
                if (_assigned getOrDefault [_candidateId, false]) then { continue };

                private _candidateData = _combatGroups get _candidateId;
                if (isNil "_candidateData") then { continue };
                if ((_candidateData get "position") distance2D _anchorPos > _engagementDist) then { continue };

                _seedCandidates pushBack [_candidateId, _candidateData];
            } forEach (_seedGroupsByCell getOrDefault [_cellKey, []]);

            {
                private _candidateId = _x;
                if (_assigned getOrDefault [_candidateId, false]) then { continue };

                private _candidateData = _combatGroups get _candidateId;
                if (isNil "_candidateData") then { continue };
                if ((_candidateData get "position") distance2D _anchorPos > _engagementDist) then { continue };

                _opponentCandidates pushBack [_candidateId, _candidateData];
            } forEach (_opponentGroupsByCell getOrDefault [_cellKey, []]);
        };
    };

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

    private _eastRefs = [];
    private _westRefs = [];
    private _eastSeen = createHashMap;
    private _westSeen = createHashMap;
    private _minContactDist = 1e9;
    private _contactPos = _anchorPos;

    {
        private _eastRef = _x;
        private _eastId = _eastRef select 0;
        private _eastPos = (_eastRef select 1) get "position";

        {
            private _westRef = _x;
            private _westId = _westRef select 0;
            private _westPos = (_westRef select 1) get "position";
            private _dist = _eastPos distance2D _westPos;
            if (_dist > _engagementDist) then { continue };

            if !(_eastSeen getOrDefault [_eastId, false]) then {
                _eastSeen set [_eastId, true];
                _eastRefs pushBack _eastRef;
            };

            if !(_westSeen getOrDefault [_westId, false]) then {
                _westSeen set [_westId, true];
                _westRefs pushBack _westRef;
            };

            if (_dist >= _minContactDist) then { continue };

            _minContactDist = _dist;
            _contactPos = [
                ((_eastPos select 0) + (_westPos select 0)) * 0.5,
                ((_eastPos select 1) + (_westPos select 1)) * 0.5,
                0
            ];
        } forEach _westCandidates;
    } forEach _eastCandidates;

    if (count _eastRefs == 0 || {count _westRefs == 0}) then { continue };
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
