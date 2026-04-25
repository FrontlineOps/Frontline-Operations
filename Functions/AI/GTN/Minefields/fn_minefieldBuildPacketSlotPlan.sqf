/*
 * Function: FLO_fnc_minefieldBuildPacketSlotPlan
 * Author: Frontline Operations Development Group
 * Description:
 *   Builds the cheap logical slot plan for one obstacle packet. Expensive slot
 *   position resolve is deferred so queued jobs can expand packets in smaller
 *   batches without changing the packet's overall shape.
 *
 * Arguments:
 * 0: Field context <HASHMAP>
 * 1: Packet data <HASHMAP>
 *
 * Return Value:
 * ARRAY of planned slot HASHMAPs
 */

params [
    ["_context", createHashMap],
    ["_packet", createHashMap]
];

if !(_context isEqualType createHashMap) exitWith { [] };
if !(_packet isEqualType createHashMap) exitWith { [] };

private _slotPlans = [];
private _role = _packet get "role";
private _packetHalfWidth = _packet get "halfWidth";
private _packetLayers = _packet get "layers";
private _slotSpacing = _packet get "slotSpacing";
private _shoulderWidth = _packet get "shoulderWidth";
private _allowAT = _packet get "allowAT";
private _rowSpacing = _context get "rowSpacing";

switch _role do {
    case "road": {
        private _depthOffsets = [];
        private _roadSlotCount = ((floor (((_packetHalfWidth * 2) / (_slotSpacing max 1)))) + 1) max 3;
        if (_roadSlotCount <= 1) then {
            _depthOffsets pushBack 0;
        } else {
            for "_i" from 0 to (_roadSlotCount - 1) do {
                _depthOffsets pushBack (linearConversion [0, _roadSlotCount - 1, _i, -_packetHalfWidth, _packetHalfWidth, true]);
            };
        };

        {
            private _depthOffset = _x;

            if (_allowAT && {((_forEachIndex mod 2) == 0 || {(random 1) > 0.4})}) then {
                _slotPlans pushBack (createHashMapFromArray [
                    ["type", "ATMine"],
                    ["depthOffset", _depthOffset],
                    ["lateralOffset", 0],
                    ["priority", 160 - (abs _depthOffset * 0.4)]
                ]);
            };

            {
                private _mineType = if ((random 1) > 0.6) then { "APERSBoundingMine" } else { "APERSMine" };
                _slotPlans pushBack (createHashMapFromArray [
                    ["type", _mineType],
                    ["depthOffset", _depthOffset],
                    ["lateralOffset", _x],
                    ["priority", 115 - (abs _depthOffset * 0.3)]
                ]);
            } forEach [-_shoulderWidth, _shoulderWidth];
        } forEach _depthOffsets;
    };

    case "bypass": {
        private _laneOffsets = [];
        private _laneCount = ((floor (((_packetHalfWidth * 2) / (_slotSpacing max 1)))) + 1) max 2;
        if (_laneCount <= 1) then {
            _laneOffsets pushBack 0;
        } else {
            for "_i" from 0 to (_laneCount - 1) do {
                _laneOffsets pushBack (linearConversion [0, _laneCount - 1, _i, -_packetHalfWidth, _packetHalfWidth, true]);
            };
        };

        for "_layerIndex" from 0 to (_packetLayers - 1) do {
            private _depthOffset = _layerIndex * (_rowSpacing * 0.9);
            private _mineType = if ((_layerIndex mod 2) == 0) then { "APERSMine" } else { "APERSBoundingMine" };

            {
                if ((random 1) > 0.82) then { continue };

                _slotPlans pushBack (createHashMapFromArray [
                    ["type", _mineType],
                    ["depthOffset", _depthOffset],
                    ["lateralOffset", _x],
                    ["priority", 105 - (_layerIndex * 7)]
                ]);
            } forEach _laneOffsets;
        };

        if (_allowAT) then {
            _slotPlans pushBack (createHashMapFromArray [
                ["type", "ATMine"],
                ["depthOffset", (_rowSpacing * 0.8)],
                ["lateralOffset", 0],
                ["priority", 130]
            ]);
        };
    };

    case "cover": {
        private _laneOffsets = [];
        private _laneCount = ((floor (((_packetHalfWidth * 2) / (_slotSpacing max 1)))) + 1) max 2;
        if (_laneCount <= 1) then {
            _laneOffsets pushBack 0;
        } else {
            for "_i" from 0 to (_laneCount - 1) do {
                _laneOffsets pushBack (linearConversion [0, _laneCount - 1, _i, -_packetHalfWidth, _packetHalfWidth, true]);
            };
        };

        for "_layerIndex" from 0 to (_packetLayers - 1) do {
            private _depthOffset = _layerIndex * (_rowSpacing * 0.8);
            private _mineType = if ((_layerIndex mod 2) == 0) then { "APERSMine" } else { "APERSBoundingMine" };
            private _fillChance = (0.92 - (_layerIndex * 0.07)) max 0.68;

            {
                if ((random 1) > _fillChance) then { continue };

                _slotPlans pushBack (createHashMapFromArray [
                    ["type", _mineType],
                    ["depthOffset", _depthOffset],
                    ["lateralOffset", _x],
                    ["priority", 125 - (_layerIndex * 6)]
                ]);
            } forEach _laneOffsets;
        };
    };

    default {
        private _laneOffsets = [];
        private _laneCount = ((floor (((_packetHalfWidth * 2) / (_slotSpacing max 1)))) + 1) max 2;
        if (_laneCount <= 1) then {
            _laneOffsets pushBack 0;
        } else {
            for "_i" from 0 to (_laneCount - 1) do {
                _laneOffsets pushBack (linearConversion [0, _laneCount - 1, _i, -_packetHalfWidth, _packetHalfWidth, true]);
            };
        };

        for "_layerIndex" from 0 to (_packetLayers - 1) do {
            private _depthOffset = _layerIndex * _rowSpacing;
            private _mineType = if ((_layerIndex mod 3) == 1) then { "APERSBoundingMine" } else { "APERSMine" };
            private _fillChance = (0.85 - (_layerIndex * 0.08)) max 0.58;

            {
                if ((random 1) > _fillChance) then { continue };

                _slotPlans pushBack (createHashMapFromArray [
                    ["type", _mineType],
                    ["depthOffset", _depthOffset],
                    ["lateralOffset", _x],
                    ["priority", 120 - (_layerIndex * 8)]
                ]);
            } forEach _laneOffsets;
        };

        if (_allowAT) then {
            {
                if ((abs _x) > (_packetHalfWidth * 0.32)) then { continue };

                _slotPlans pushBack (createHashMapFromArray [
                    ["type", "ATMine"],
                    ["depthOffset", (_rowSpacing * 0.6)],
                    ["lateralOffset", _x],
                    ["priority", 135]
                ]);
            } forEach [-(_slotSpacing * 0.5), 0, (_slotSpacing * 0.5)];
        };
    };
};

_slotPlans
