/*
 * Function: FLO_fnc_minefieldBuildPacketMineSpecs
 * Author: Frontline Operations Development Group
 * Description:
 *   Expands one obstacle packet into concrete mine specs. Different packet
 *   roles produce different shapes so the field reads like a set of tactical
 *   obstacle nodes instead of one uniform carpet.
 *
 * Arguments:
 * 0: Field context <HASHMAP>
 * 1: Packet data <HASHMAP>
 * 2: Spacing index <HASHMAP>
 * 3: Layout stats <HASHMAP>
 *
 * Return Value:
 * ARRAY of mine spec HASHMAPs
 */

params [
    ["_context", createHashMap],
    ["_packet", createHashMap],
    ["_spacingIndex", createHashMap],
    ["_layoutStats", createHashMap]
];

if !(_context isEqualType createHashMap) exitWith { [] };
if !(_packet isEqualType createHashMap) exitWith { [] };

private _mineSpecs = [];
private _packetState = createHashMap;
private _done = false;

while {!_done} do {
    private _stepResult = [_context, _packet, _spacingIndex, _layoutStats, _packetState, 99999] call FLO_fnc_minefieldBuildPacketMineSpecsStep;
    _packetState = _stepResult get "state";

    {
        _mineSpecs pushBack _x;
    } forEach (_stepResult get "mineSpecs");

    _done = _stepResult get "done";
};

_mineSpecs
