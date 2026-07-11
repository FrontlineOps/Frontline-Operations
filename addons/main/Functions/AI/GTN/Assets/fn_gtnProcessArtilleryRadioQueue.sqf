/*
 * Function: FLO_fnc_gtnProcessArtilleryRadioQueue
 * Author: Frontline Operations Development Group
 * Description:
 *   Processes the local queued artillery radio missions for one side so the
 *   full mission chatter plays in order without overlapping broadcasts.
 *
 * Arguments:
 *   0: Side <SIDE>
 *
 * Return Value:
 *   BOOL
 */

if (!hasInterface) exitWith { false };

params [
    ["_side", sideUnknown]
];

if !(_side in [east, west]) exitWith { false };
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

private _sideKey = ["WEST", "EAST"] select (_side isEqualTo east);
if (FLO_GTN_ArtilleryRadioActive get _sideKey) exitWith { false };

FLO_GTN_ArtilleryRadioActive set [_sideKey, true];

[_side, _sideKey] spawn {
    params ["_side", "_sideKey"];

    while {true} do {
        private _queue = FLO_GTN_ArtilleryRadioQueues get _sideKey;
        if (_queue isEqualTo []) exitWith {};

        private _mission = _queue deleteAt 0;
        private _sequence = _mission select 1;
        private _lastOffset = 0;

        {
            _x params [
                ["_sender", "HQ", [""]],
                ["_text", "", [""]],
                ["_offset", 0, [0]]
            ];

            private _sleepFor = (_offset - _lastOffset) max 0;
            if (_sleepFor > 0) then {
                sleep _sleepFor;
            };

            [_side, _sender, _text] call FLO_fnc_gtnCommanderRadioMessage;
            _lastOffset = _offset;
        } forEach _sequence;

        sleep 0.75;
    };

    FLO_GTN_ArtilleryRadioActive set [_sideKey, false];
};

true
