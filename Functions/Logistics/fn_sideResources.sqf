/*
 * Function: FLO_fnc_sideResources
 * Author: Frontline Operations Development Group
 * Description:
 *   Initializes side-scoped resource objects for EAST and WEST.
 *
 * Arguments:
 *   None
 *
 * Return Value:
 *   HashMap of side resource objects <HASHMAP>
 */

if (!isServer) exitWith { createHashMap };

if (!isNil "FLO_SideResources" && {FLO_SideResources isEqualType createHashMap} && {(count (keys FLO_SideResources)) > 0}) exitWith {
    FLO_SideResources
};

private _savedResources = createHashMap;
if (!isNil "FLO_SavedGameData" && {FLO_SavedGameData isEqualType createHashMap}) then {
    private _savedRaw = FLO_SavedGameData get "sideResources";
    if (_savedRaw isEqualType createHashMap) then {
        _savedResources = _savedRaw;
    };
};

private _fnc_sideKey = {
    params ["_side"];
    if (_side isEqualTo east) exitWith { "EAST" };
    if (_side isEqualTo west) exitWith { "WEST" };
    "EAST"
};

private _fnc_createResourceObject = {
    params [["_side", east], ["_savedPayload", objNull]];

    if (!(_savedPayload isEqualTo objNull) && {!(_savedPayload isEqualType createHashMap)}) then {
        ["SIDE_RES", 1, format ["Invalid saved state for %1 side resource object", _side]] call FLO_fnc_log;
        _savedPayload = objNull;
    };

    private _sideKey = [_side] call _fnc_sideKey;
    private _enemySide = if (_side isEqualTo east) then { west } else { east };

    private _resourceClass = [
        ["#type", "SideResources"],

        ["_side", _side],
        ["_sideKey", _sideKey],
        ["_enemySide", _enemySide],
        ["_savedState", _savedPayload],

        ["RESOURCE_VALUES", createHashMapFromArray [
            ["capital", 10],
            ["city", 6],
            ["marine", 5],
            ["local", 4],
            ["village", 2],
            ["cluster", 1]
        ]],

        ["STARTING_VALUES", createHashMapFromArray [
            ["capital", 50],
            ["city", 30],
            ["marine", 25],
            ["local", 20],
            ["village", 10],
            ["cluster", 5]
        ]],

        ["SPENDING_TYPES", createHashMapFromArray [
            ["garrison", [1.0, 10, 0.05]],
            ["reinforcement", [1.0, 20, 0.03]],
            ["qrf", [1.5, 100, 0.08]],
            ["offensiveops", [4.0, 500, 0.15]],
            ["air_support", [2.0, 250, 0.12]],
            ["artillery", [3.0, 150, 0.07]],
            ["transport", [0.5, 15, 0.02]]
        ]],

        ["_resources", 0],
        ["_lastUpdate", 0],
        ["_efficiencies", createHashMap],
        ["_generationLoopStarted", false],

        ["#create", {
            private _saved = _self get "_savedState";

            if (_saved isEqualType createHashMap) then {
                _self set ["_resources", _saved get "resources"];
                _self set ["_lastUpdate", time];
                _self set ["_efficiencies", _saved get "efficiencies"];
            } else {
                private _start = _self call ["_calculateStartingResources", []];
                _self set ["_resources", _start];
                _self set ["_lastUpdate", time];
            };

            _self call ["_startGenerationLoop", []];
        }],

        ["_calculateStartingResources", {
            if (isNil "FLO_Objectives" || {count FLO_Objectives == 0}) exitWith { 200 };

            private _startingValues = _self get "STARTING_VALUES";
            private _ownerSide = _self get "_side";
            private _total = 0;

            {
                private _objId = _x;
                private _objData = FLO_Objectives get _objId;
                if ((_objData get "owner") isEqualTo _ownerSide) then {
                    private _subtype = _objData get "subtype";
                    _total = _total + (_startingValues get _subtype);
                };
            } forEach (keys FLO_Objectives);

            _total max 100
        }],

        ["_getEfficiency", {
            params ["_type"];
            private _eff = _self get "_efficiencies";
            _eff getOrDefault [_type, 1.0]
        }],

        ["_setEfficiency", {
            params ["_type", "_value"];
            private _eff = _self get "_efficiencies";
            _eff set [_type, (_value max 0.2) min 1.0];
        }],

        ["_startGenerationLoop", {
            if (_self get "_generationLoopStarted") exitWith {};
            _self set ["_generationLoopStarted", true];

            [_self] spawn {
                params ["_resObj"];

                waitUntil { sleep 1; !isNil "FLO_Objectives" && {count FLO_Objectives > 0} };

                private _eventCooldown = 0;

                while {true} do {
                    if (isNil "FLO_SideResources") exitWith {};

                    private _ownerSide = _resObj get "_side";
                    private _enemySide = _resObj get "_enemySide";
                    private _resourceValues = _resObj get "RESOURCE_VALUES";
                    private _totalGen = 0;
                    private _activeCount = 0;
                    private _contestedCount = 0;
                    private _globalMod = 1.0;

                    if (time > _eventCooldown && {random 100 < 5}) then {
                        _globalMod = if (random 1 > 0.3) then { 1.5 } else { 0.7 };
                        _eventCooldown = time + 1800 + random 1800;
                    };

                    {
                        private _objId = _x;
                        private _data = FLO_Objectives get _objId;
                        if !((_data get "owner") isEqualTo _ownerSide) then { continue };

                        private _subtype = _data get "subtype";
                        private _pos = _data get "position";
                        private _baseVal = _resourceValues get _subtype;

                        private _nearUnits = _pos nearEntities [["Man", "Car", "Tank", "LandVehicle"], 1000];
                        private _nearEnemy = 0;

                        {
                            if (!alive _x) then { continue };

                            private _uSide = side _x;
                            if (isPlayer _x) then {
                                _uSide = side group _x;
                            };

                            if (_uSide isEqualTo _enemySide) then {
                                _nearEnemy = _nearEnemy + 1;
                            };
                        } forEach _nearUnits;

                        {
                            if (!alive _x) then { continue };
                            if ((_x distance2D _pos) > 1000) then { continue };
                            if (_x in _nearUnits) then { continue };

                            if ((side group _x) isEqualTo _enemySide) then {
                                _nearEnemy = _nearEnemy + 1;
                            };
                        } forEach allPlayers;

                        private _contested = _nearEnemy > 0;
                        private _contestMod = if (_contested) then { 0.5 } else { 1.0 };

                        if (_contested) then { _contestedCount = _contestedCount + 1 };

                        _totalGen = _totalGen + (_baseVal * _globalMod * _contestMod);
                        _activeCount = _activeCount + 1;
                    } forEach (keys FLO_Objectives);

                    _totalGen = round _totalGen;
                    if (_totalGen > 0) then {
                        _resObj call ["addResources", [_totalGen]];
                    };

                    ["SIDE_RES", 3, format["%1 gen +%2 from %3 objectives (%4 contested) | Total %5",
                        _resObj get "_sideKey", _totalGen, _activeCount, _contestedCount, _resObj call ["getResources", []]
                    ]] call FLO_fnc_log;

                    sleep 600;
                };
            };
        }],

        ["getResources", {
            _self get "_resources"
        }],

        ["addResources", {
            params ["_amount"];
            private _current = _self get "_resources";
            private _new = _current + _amount;
            _self set ["_resources", _new];
            _self set ["_lastUpdate", time];
            _new
        }],

        ["canAfford", {
            params ["_amount", "_type"];

            private _spendingTypes = _self get "SPENDING_TYPES";
            private _typeData = _spendingTypes get _type;
            _typeData params ["_multiplier", "_threshold", "_effLoss"];

            private _current = _self get "_resources";
            if (_current < _threshold) exitWith { false };

            private _efficiency = _self call ["_getEfficiency", [_type]];
            private _cost = _amount * _multiplier * (1 / _efficiency);

            _current >= _cost
        }],

        ["spendResources", {
            params ["_amount", "_type"];

            private _spendingTypes = _self get "SPENDING_TYPES";
            private _typeData = _spendingTypes get _type;
            _typeData params ["_multiplier", "_threshold", "_effLoss"];

            private _current = _self get "_resources";
            if (_current < _threshold) exitWith { false };

            private _efficiency = _self call ["_getEfficiency", [_type]];
            private _cost = _amount * _multiplier * (1 / _efficiency);

            if (_current < _cost) exitWith { false };

            private _new = _current - _cost;
            _self set ["_resources", _new];
            _self set ["_lastUpdate", time];

            private _newEff = _efficiency - _effLoss;
            _self call ["_setEfficiency", [_type, _newEff]];

            if (_new > _threshold * 2) then {
                {
                    private _currEff = _self call ["_getEfficiency", [_x]];
                    _self call ["_setEfficiency", [_x, _currEff + 0.02]];
                } forEach (keys _spendingTypes);
            };

            true
        }],

        ["serialize", {
            createHashMapFromArray [
                ["resources", _self get "_resources"],
                ["lastUpdate", _self get "_lastUpdate"],
                ["efficiencies", _self get "_efficiencies"],
                ["sideKey", _self get "_sideKey"]
            ]
        }]
    ];

    createHashMapObject [_resourceClass]
};

FLO_SideResources = createHashMap;

{
    private _side = _x;
    private _sideKey = [_side] call _fnc_sideKey;
    private _savedPayload = objNull;
    if (_sideKey in _savedResources) then {
        _savedPayload = _savedResources get _sideKey;
    };

    if (_savedPayload isEqualType createHashMap) then {
        if (
            isNil {_savedPayload get "resources"} ||
            isNil {_savedPayload get "efficiencies"}
        ) then {
            ["SIDE_RES", 1, format ["Discarding invalid saved payload for %1 resources", _sideKey]] call FLO_fnc_log;
            _savedPayload = objNull;
        };
    } else {
        if !(_savedPayload isEqualTo objNull) then {
            ["SIDE_RES", 1, format ["Discarding invalid saved payload type for %1 resources", _sideKey]] call FLO_fnc_log;
            _savedPayload = objNull;
        };
    };

    private _obj = [_side, _savedPayload] call _fnc_createResourceObject;
    FLO_SideResources set [_sideKey, _obj];
} forEach [east, west];

// Publish lightweight serialized snapshot only (resource objects are not network-safe).
private _pubState = createHashMap;
{
    private _resObj = FLO_SideResources get _x;
    _pubState set [_x, _resObj call ["serialize", []]];
} forEach (keys FLO_SideResources);
FLO_SideResourceState = _pubState;
publicVariable "FLO_SideResourceState";

["SIDE_RES", 2, "Initialized side resource system (EAST/WEST)"] call FLO_fnc_log;

FLO_SideResources
