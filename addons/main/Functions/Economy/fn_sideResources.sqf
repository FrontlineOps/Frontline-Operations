/*
 * Initializes the authoritative WEST and EAST treasuries. Economy state is
 * side-owned and consumed by both players and AI commanders.
 */
if (!isServer) exitWith { createHashMap };

if ((keys FLO_SideResources) isNotEqualTo []) exitWith { FLO_SideResources };

private _savedResources = createHashMap;
if (!isNil "FLO_SavedGameData" && {"sideResources" in FLO_SavedGameData}) then {
    _savedResources = FLO_SavedGameData get "sideResources";
    if !(_savedResources isEqualType createHashMap) then {
        throw format ["Invalid saved sideResources payload: %1", typeName _savedResources];
    };
};

private _treasuryClass = [
    ["#type", "SideTreasury"],

    ["RESOURCE_VALUES", createHashMapFromArray [
        ["capital", 20],
        ["city", 12],
        ["marine", 10],
        ["local", 8],
        ["village", 4],
        ["cluster", 1]
    ]],
    ["CONTEST_MODIFIERS", createHashMapFromArray [
        ["SECURE", 1.0],
        ["DEFENDED", 0.85],
        ["CONTESTED", 0.65],
        ["OVERRUN", 0.35]
    ]],
    ["UPDATE_INTERVAL", 180],
    ["OBJECTIVE_CAPTURE_REWARD", 200],
    ["LEDGER_LIMIT", 64],
    ["PUBLIC_LEDGER_LIMIT", 12],

    ["_side", east],
    ["_sideKey", "EAST"],
    ["_enemySide", west],
    ["_balance", 0],
    ["_reservations", createHashMap],
    ["_ledger", []],
    ["_transactionSequence", 0],
    ["_lastIncome", 0],
    ["_lastUpdate", 0],

    ["#create", {
        ([_self] + _this) call FLO_fnc_sideResourcesCreate;
    }],
    ["getResources", { _self get "_balance" }],
    ["getBalance", { _self get "_balance" }],
    ["getCommitted", { [_self] call FLO_fnc_sideResourcesGetCommitted }],
    ["getAvailable", { [_self] call FLO_fnc_sideResourcesGetAvailable }],
    ["getReservationRemaining", { ([_self] + _this) call FLO_fnc_sideResourcesGetReservationRemaining }],
    ["getSnapshot", { [_self] call FLO_fnc_sideResourcesGetSnapshot }],
    ["addResources", { ([_self] + _this) call FLO_fnc_sideResourcesAddResources }],
    ["canAfford", { ([_self] + _this) call FLO_fnc_sideResourcesCanAfford }],
    ["spendResources", { ([_self] + _this) call FLO_fnc_sideResourcesSpendResources }],
    ["reserve", { ([_self] + _this) call FLO_fnc_sideResourcesReserve }],
    ["commitReservation", { ([_self] + _this) call FLO_fnc_sideResourcesCommitReservation }],
    ["releaseReservation", { ([_self] + _this) call FLO_fnc_sideResourcesReleaseReservation }],
    ["serialize", { [_self] call FLO_fnc_sideResourcesSerialize }]
];

FLO_SideResources = createHashMap;

{
    private _side = _x;
    private _sideKey = [_side] call FLO_fnc_sideKey;
    private _savedPayload = objNull;
    if (_sideKey in _savedResources) then {
        _savedPayload = _savedResources get _sideKey;
    };

    private _treasury = createHashMapObject [_treasuryClass, [_side, _savedPayload]];
    FLO_SideResources set [_sideKey, _treasury];
} forEach [east, west];

[] call FLO_fnc_sideResourcesPublishState;
["ECONOMY", 2, "Initialized unified WEST/EAST side treasuries"] call FLO_fnc_log;

FLO_SideResources
