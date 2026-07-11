/*
 * Function: FLO_fnc_gtnQueueArtilleryRadioMission
 * Author: Frontline Operations Development Group
 * Description:
 *   Enqueues a side-filtered artillery radio mission sequence on the local
 *   client so request / acknowledge / shot traffic stays ordered.
 *
 * Arguments:
 *   0: Side <SIDE>
 *   1: Mission ID <STRING>
 *   2: Sequence entries <ARRAY>
 *
 * Return Value:
 *   BOOL
 */

if (!hasInterface) exitWith { false };

params [
    ["_side", sideUnknown],
    ["_missionId", "", [""]],
    ["_sequence", [], [[]]]
];

if !(_side in [east, west]) exitWith { false };
if (_missionId == "") exitWith { false };
if (_sequence isEqualTo []) exitWith { false };
if (isNull player) exitWith { false };
if ((side group player) != _side) exitWith { false };

if (isNil "FLO_GTN_ArtilleryRadioQueues") then {
    FLO_GTN_ArtilleryRadioQueues = createHashMapFromArray [
        ["EAST", []],
        ["WEST", []]
    ];
};
if (isNil "FLO_GTN_ArtilleryRadioActive") then {
    FLO_GTN_ArtilleryRadioActive = createHashMapFromArray [
        ["EAST", false],
        ["WEST", false]
    ];
};
if (isNil "FLO_GTN_ArtilleryRadioSeen") then {
    FLO_GTN_ArtilleryRadioSeen = createHashMapFromArray [
        ["EAST", createHashMap],
        ["WEST", createHashMap]
    ];
};

private _sideKey = ["WEST", "EAST"] select (_side isEqualTo east);
private _seen = FLO_GTN_ArtilleryRadioSeen get _sideKey;
if (_missionId in (keys _seen)) exitWith { false };

_seen set [_missionId, true];
(FLO_GTN_ArtilleryRadioQueues get _sideKey) pushBack [_missionId, _sequence];

if !(FLO_GTN_ArtilleryRadioActive get _sideKey) then {
    [_side] call FLO_fnc_gtnProcessArtilleryRadioQueue;
};

true
