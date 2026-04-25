/*
 * Function: FLO_fnc_minefieldBuildPacketMineSpecsStep
 * Author: Frontline Operations Development Group
 * Description:
 *   Expands one obstacle packet into concrete mine specs in bounded batches so
 *   queued jobs do not let one heavy packet monopolize a worker slice.
 *
 * Arguments:
 * 0: Field context <HASHMAP>
 * 1: Packet data <HASHMAP>
 * 2: Spacing index <HASHMAP>
 * 3: Layout stats <HASHMAP>
 * 4: Packet state <HASHMAP>
 * 5: Max planned slots to process <SCALAR>
 *
 * Return Value:
 * HASHMAP with keys:
 * - state <HASHMAP>
 * - mineSpecs <ARRAY>
 * - done <BOOL>
 */

params [
    ["_context", createHashMap],
    ["_packet", createHashMap],
    ["_spacingIndex", createHashMap],
    ["_layoutStats", createHashMap],
    ["_packetState", createHashMap],
    ["_maxSlots", 1]
];

if !(_context isEqualType createHashMap) exitWith { createHashMapFromArray [["state", createHashMap], ["mineSpecs", []], ["done", true]] };
if !(_packet isEqualType createHashMap) exitWith { createHashMapFromArray [["state", createHashMap], ["mineSpecs", []], ["done", true]] };
if !(_packetState isEqualType createHashMap) then {
    _packetState = createHashMap;
};

if !("slotPlans" in _packetState) then {
    private _slotPlans = [_context, _packet] call FLO_fnc_minefieldBuildPacketSlotPlan;
    _packetState set ["slotPlans", _slotPlans];
    _packetState set ["nextIndex", 0];
    _layoutStats set ["attemptedSlots", (_layoutStats get "attemptedSlots") + (count _slotPlans)];
};

private _slotPlans = _packetState get "slotPlans";
private _nextIndex = _packetState get "nextIndex";
private _mineSpecs = [];

if (_nextIndex >= count _slotPlans) exitWith {
    createHashMapFromArray [
        ["state", _packetState],
        ["mineSpecs", _mineSpecs],
        ["done", true]
    ]
};

private _endIndex = ((_nextIndex + (_maxSlots max 1)) min (count _slotPlans)) - 1;
for "_slotIndex" from _nextIndex to _endIndex do {
    private _slotPlan = _slotPlans select _slotIndex;
    private _mineType = _slotPlan get "type";
    private _safePos = [
        _context,
        _mineType,
        _slotPlan get "depthOffset",
        _slotPlan get "lateralOffset",
        _spacingIndex,
        _layoutStats
    ] call FLO_fnc_minefieldResolveLayoutMinePos;

    if ((count _safePos) == 0) then { continue };

    [_safePos, _spacingIndex, (FLO_MinefieldConfig get "minSpacing")] call FLO_fnc_minefieldRegisterSpacingPos;
    _mineSpecs pushBack (createHashMapFromArray [
        ["type", _mineType],
        ["posATL", _safePos],
        ["priority", _slotPlan get "priority"]
    ]);
};

_nextIndex = _endIndex + 1;
_packetState set ["nextIndex", _nextIndex];

createHashMapFromArray [
    ["state", _packetState],
    ["mineSpecs", _mineSpecs],
    ["done", _nextIndex >= count _slotPlans]
]
