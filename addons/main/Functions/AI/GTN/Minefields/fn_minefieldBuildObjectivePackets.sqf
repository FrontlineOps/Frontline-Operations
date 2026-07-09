/*
 * Function: FLO_fnc_minefieldBuildObjectivePackets
 * Author: Frontline Operations Development Group
 * Description:
 *   Builds a smaller set of irregular obstacle packets for one objective so
 *   the commander shapes likely assault lanes, roads, and bypass gaps instead
 *   of drawing one giant continuous field.
 *
 * Arguments:
 * 0: Frontline placement context <HASHMAP>
 *
 * Return Value:
 * ARRAY of packet HASHMAPs
 */

params [
    ["_context", createHashMap]
];

if (!(_context isEqualType createHashMap)) exitWith { [] };
if ((keys _context) isEqualTo []) exitWith { [] };

private _objectiveId = _context get "objectiveId";
private _objective = FLO_Objectives get _objectiveId;
private _objectivePos = _context get "objectivePos";
private _objectiveRadius = _context get "objectiveRadius";
private _anchorPos = _context get "anchorPos";
private _facingDir = _context get "facingDir";
private _frontageHalfWidth = _context get "frontageHalfWidth";
private _rowSpacing = _context get "rowSpacing";
private _laneSpacing = _context get "laneSpacing";
private _maxLayers = _context get "layerCount";
private _enemyLinkCount = _context get "enemyLinkCount";
private _blockingObjectiveIds = _context get "blockingObjectiveIds";
private _subtype = _context get "subtype";
private _allowAT = _context get "allowAT";
private _edgeBuffer = FLO_MinefieldConfig get "objectiveEdgeBuffer";
private _packetSearchRadius = _objectiveRadius + (_context get "fieldDepth") + 100;
private _coverPacketMaxCount = FLO_MinefieldConfig get "coverPacketMaxCount";

private _packets = [];
private _packetIndex = 0;
private _frontagePacketCount = switch (_subtype) do {
    case "capital": { 3 };
    case "city": { 3 };
    case "local": { 2 };
    case "marine": { 2 };
    default { 1 };
};
_frontagePacketCount = (_frontagePacketCount + ((_enemyLinkCount - 1) min 2)) min 4;

private _frontageOffsets = [];
if (_frontagePacketCount <= 1) then {
    _frontageOffsets pushBack 0;
} else {
    private _usableFrontageHalfWidth = _frontageHalfWidth * 0.72;
    for "_i" from 0 to (_frontagePacketCount - 1) do {
        private _baseOffset = linearConversion [0, _frontagePacketCount - 1, _i, -_usableFrontageHalfWidth, _usableFrontageHalfWidth, true];
        _frontageOffsets pushBack (_baseOffset + ((random 18) - 9));
    };
};

{
    private _offset = _x;
    private _packetAnchorPos = _anchorPos getPos [
        abs _offset,
        _facingDir + ([270, 90] select (_offset >= 0))
    ];
    _packetAnchorPos set [2, 0];

    if ((_objectivePos distance2D _packetAnchorPos) <= (_objectiveRadius + _edgeBuffer)) then { continue };
    if (([_packetAnchorPos, [_objectiveId], _blockingObjectiveIds] call FLO_fnc_minefieldGetBlockingObjectiveId) != "") then { continue };

    private _packetHalfWidth = (24 + ((_frontageHalfWidth / (_frontagePacketCount max 1)) * 0.35) + random 12) min 52;
    private _packetLayers = ((2 + floor random 2) + parseNumber (_subtype in ["capital", "city"])) min (_maxLayers max 2);
    private _packetDir = _facingDir + ((random 14) - 7);

    _packets pushBack (createHashMapFromArray [
        ["id", format ["pkt_%1", _packetIndex]],
        ["role", "frontage"],
        ["anchorPos", _packetAnchorPos],
        ["dir", _packetDir],
        ["halfWidth", _packetHalfWidth],
        ["layers", _packetLayers],
        ["slotSpacing", (_laneSpacing * 1.15) max 10],
        ["shoulderWidth", 6],
        ["allowAT", _allowAT]
    ]);
    _packetIndex = _packetIndex + 1;
} forEach _frontageOffsets;

private _roadCandidates = [];
{
    private _roadPos = getPosATL _x;
    _roadPos set [2, 0];

    if ((_objectivePos distance2D _roadPos) <= (_objectiveRadius + _edgeBuffer)) then { continue };
    if (([_roadPos, [_objectiveId], _blockingObjectiveIds] call FLO_fnc_minefieldGetBlockingObjectiveId) != "") then { continue };

    private _dirToRoad = [_objectivePos, _roadPos] call BIS_fnc_dirTo;
    private _angleDelta = abs (((_dirToRoad - _facingDir + 540) % 360) - 180);
    if (_angleDelta > 80) then { continue };

    private _roadDir = _facingDir;
    private _connections = roadsConnectedTo _x;
    if (_connections isNotEqualTo []) then {
        _roadDir = _x getDir (_connections select 0);
    };

    private _distanceScore = abs ((_objectivePos distance2D _roadPos) - (_objectiveRadius + 40));
    _roadCandidates pushBack (createHashMapFromArray [
        ["pos", _roadPos],
        ["dir", _roadDir],
        ["score", (100 - _distanceScore) - _angleDelta]
    ]);
} forEach (_objectivePos nearRoads _packetSearchRadius);

private _sortedRoadCandidates = [_roadCandidates, [], { _x get "score" }, "DESCEND"] call BIS_fnc_sortBy;
private _roadPacketsPlaced = 0;
{
    if (_roadPacketsPlaced >= ([1, 2] select (_allowAT))) exitWith {};

    private _packetAnchorPos = _x get "pos";
    private _tooClose = false;
    {
        if ((_packetAnchorPos distance2D (_x get "anchorPos")) < 55) exitWith {
            _tooClose = true;
        };
    } forEach _packets;
    if (_tooClose) then { continue };

    _packets pushBack (createHashMapFromArray [
        ["id", format ["pkt_%1", _packetIndex]],
        ["role", "road"],
        ["anchorPos", _packetAnchorPos],
        ["dir", _x get "dir"],
        ["halfWidth", 18 + random 8],
        ["layers", 2 + floor random 2],
        ["slotSpacing", 8],
        ["shoulderWidth", 7],
        ["allowAT", _allowAT]
    ]);
    _packetIndex = _packetIndex + 1;
    _roadPacketsPlaced = _roadPacketsPlaced + 1;
} forEach _sortedRoadCandidates;

private _coverCandidates = [_context] call FLO_fnc_minefieldBuildCoverPacketAnchors;
private _sortedCoverCandidates = [_coverCandidates, [], { _x get "score" }, "DESCEND"] call BIS_fnc_sortBy;
private _coverPacketsPlaced = 0;
{
    if (_coverPacketsPlaced >= _coverPacketMaxCount) exitWith {};

    private _packetAnchorPos = _x get "pos";
    private _tooClose = false;
    {
        if ((_packetAnchorPos distance2D (_x get "anchorPos")) < ((_x get "halfWidth") + 20)) exitWith {
            _tooClose = true;
        };
    } forEach _packets;
    if (_tooClose) then { continue };

    private _packetHalfWidth = 16 + random 10;
    private _packetLayers = ((2 + floor random 2) + parseNumber (_subtype in ["capital", "city"])) min (_maxLayers max 2);
    _packets pushBack (createHashMapFromArray [
        ["id", format ["pkt_%1", _packetIndex]],
        ["role", "cover"],
        ["anchorPos", _packetAnchorPos],
        ["dir", _facingDir + ((random 20) - 10)],
        ["halfWidth", _packetHalfWidth],
        ["layers", _packetLayers],
        ["slotSpacing", (_laneSpacing * 0.85) max 8],
        ["shoulderWidth", 4],
        ["allowAT", false]
    ]);
    _packetIndex = _packetIndex + 1;
    _coverPacketsPlaced = _coverPacketsPlaced + 1;
} forEach _sortedCoverCandidates;

private _bypassSides = [];
if (_frontageHalfWidth >= 60) then {
    _bypassSides pushBack -1;
    _bypassSides pushBack 1;
} else {
    if ((random 1) > 0.5) then {
        _bypassSides pushBack -1;
    } else {
        _bypassSides pushBack 1;
    };
};

{
    private _offset = _frontageHalfWidth * (0.62 + random 0.16) * _x;
    private _packetAnchorPos = _anchorPos getPos [
        abs _offset,
        _facingDir + ([270, 90] select (_offset >= 0))
    ];
    _packetAnchorPos = _packetAnchorPos getPos [(_rowSpacing * 0.9) + random (_rowSpacing * 0.4), _facingDir];
    _packetAnchorPos set [2, 0];

    if ((_objectivePos distance2D _packetAnchorPos) <= (_objectiveRadius + _edgeBuffer)) then { continue };
    if (([_packetAnchorPos, [_objectiveId], _blockingObjectiveIds] call FLO_fnc_minefieldGetBlockingObjectiveId) != "") then { continue };

    _packets pushBack (createHashMapFromArray [
        ["id", format ["pkt_%1", _packetIndex]],
        ["role", "bypass"],
        ["anchorPos", _packetAnchorPos],
        ["dir", _facingDir + (_x * (18 + random 10))],
        ["halfWidth", 14 + random 10],
        ["layers", (2 + floor random 2) min (_maxLayers max 2)],
        ["slotSpacing", (_laneSpacing * 0.95) max 9],
        ["shoulderWidth", 5],
        ["allowAT", _allowAT && {_subtype in ["capital", "city", "local"]}]
    ]);
    _packetIndex = _packetIndex + 1;
} forEach _bypassSides;

_packets
