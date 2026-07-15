/*
 * Initializes the authoritative WEST and EAST treasuries. Economy state is
 * side-owned and consumed by both players and AI commanders.
 */
if (!isServer) exitWith { createHashMap };

if ((keys FLO_SideResources) isNotEqualTo []) exitWith { FLO_SideResources };

private _commanderSpendingPolicy = createHashMapFromArray [
    ["windowSeconds", 180],
    ["reserveMinimum", 1200],
    ["reserveBalanceFraction", 0.30],
    ["reserveIncomeSeconds", 540],
    ["balancedRunwaySeconds", 360],
    ["emergencyReserve", 300],
    ["bootstrapWindowBudget", 300],
    ["balancedRunwayMinimum", 1200],
    ["denialLogCooldownSeconds", 30],
    ["developmentFundingFractions", createHashMapFromArray [
        ["CONSERVE", 0.25],
        ["BALANCED", 0.50]
    ]],
    ["developmentFundingMinimums", createHashMapFromArray [
        ["CONSERVE", 25],
        ["BALANCED", 50]
    ]],
    ["urgencyBudgetMultipliers", createHashMapFromArray [
        ["ROUTINE", 1],
        ["OPERATIONAL", 2],
        ["PRESSURED", 3],
        ["CRITICAL", 6]
    ]],
    ["urgencyReserveMultipliers", createHashMapFromArray [
        ["ROUTINE", 1],
        ["OPERATIONAL", 0.90],
        ["PRESSURED", 0.70],
        ["CRITICAL", 0]
    ]]
];

private _incomeInterval = 30;
private _resourceValues = createHashMapFromArray [
    ["capital", 45],
    ["city", 27],
    ["marine", 23],
    ["local", 18],
    ["village", 9],
    ["cluster", 2]
];
{
    if !(_y isEqualType 0 && {_y > 0}) then {
        throw format ["Invalid %1 objective income rate: %2", _x, _y];
    };
} forEach _resourceValues;
if !(_incomeInterval isEqualType 0 && {_incomeInterval > 0}) then {
    throw format ["Invalid side income interval: %1", _incomeInterval];
};

private _restoring = FLO_IsLoadedSave;

private _treasuryClass = [
    ["#type", "SideTreasury"],

    ["RESOURCE_VALUES", _resourceValues],
    ["CONTEST_MODIFIERS", createHashMapFromArray [
        ["SECURE", 1.0],
        ["DEFENDED", 0.85],
        ["CONTESTED", 0.65],
        ["OVERRUN", 0.35]
    ]],
    ["UPDATE_INTERVAL", _incomeInterval],
    ["OBJECTIVE_CAPTURE_REWARD", 200],
    ["LEDGER_LIMIT", 64],
    ["PUBLIC_LEDGER_LIMIT", 12],
    ["COMMANDER_SPENDING_POLICY", _commanderSpendingPolicy],

    ["_side", east],
    ["_sideKey", "EAST"],
    ["_enemySide", west],
    ["_balance", 0],
    ["_reservations", createHashMap],
    ["_ledger", []],
    ["_transactionSequence", 0],
    ["_lastIncome", 0],
    ["_lastUpdate", 0],
    ["_commanderSpendingDenials", createHashMap],

    ["#create", {
        ([_self] + _this) call FLO_fnc_sideResourcesCreate;
    }],
    ["getResources", { _self get "_balance" }],
    ["getBalance", { _self get "_balance" }],
    ["getCommitted", { [_self] call FLO_fnc_sideResourcesGetCommitted }],
    ["getAvailable", { [_self] call FLO_fnc_sideResourcesGetAvailable }],
    ["getReservationRemaining", { ([_self] + _this) call FLO_fnc_sideResourcesGetReservationRemaining }],
    ["getSnapshot", { [_self] call FLO_fnc_sideResourcesGetSnapshot }],
    ["increaseReservation", { ([_self] + _this) call FLO_fnc_sideResourcesIncreaseReservation }],
    ["addResources", { ([_self] + _this) call FLO_fnc_sideResourcesAddResources }],
    ["canAfford", { ([_self] + _this) call FLO_fnc_sideResourcesCanAfford }],
    ["spendResources", { ([_self] + _this) call FLO_fnc_sideResourcesSpendResources }],
    ["reserve", { ([_self] + _this) call FLO_fnc_sideResourcesReserve }],
    ["commitReservation", { ([_self] + _this) call FLO_fnc_sideResourcesCommitReservation }],
    ["releaseReservation", { ([_self] + _this) call FLO_fnc_sideResourcesReleaseReservation }],
    ["serialize", { [_self] call FLO_fnc_sideResourcesSerialize }]
];

private _savedResources = createHashMap;
private _initializedResources = createHashMap;
private _initializationError = "";

try {
    if (_restoring) then {
        _savedResources = FLO_SavedGameData get "sideResources";
        if !(_savedResources isEqualType createHashMap) then {
            throw format ["Invalid saved sideResources payload: %1", typeName _savedResources];
        };
        private _missingSides = ["WEST", "EAST"] select { !(_x in _savedResources) };
        if (_missingSides isNotEqualTo []) then {
            throw format ["Saved sideResources is missing sides %1", _missingSides];
        };
        private _unexpectedSides = (keys _savedResources) select { !(_x in ["WEST", "EAST"]) };
        if (_unexpectedSides isNotEqualTo []) then {
            throw format ["Saved sideResources has unsupported sides %1", _unexpectedSides];
        };
    };

    {
        private _side = _x;
        private _sideKey = [_side] call FLO_fnc_sideKey;
        private _savedPayload = objNull;
        if (_restoring) then {
            _savedPayload = _savedResources get _sideKey;
        };

        private _treasury = createHashMapObject [_treasuryClass, [_side, _savedPayload]];
        private _committed = [_treasury] call FLO_fnc_sideResourcesGetCommitted;
        if (_committed > (_treasury get "_balance")) then {
            throw format ["Saved %1 treasury commitments %2 exceed balance %3", _sideKey, _committed, _treasury get "_balance"];
        };
        _initializedResources set [_sideKey, _treasury];
    } forEach [east, west];
} catch {
    _initializationError = _exception;
};

if (_initializationError != "") then {
    private _severity = [1, 2] select _restoring;
    private _context = ["initialization failed", "saved state was refused"] select _restoring;
    ["ECONOMY", _severity, format ["Side Resources %1: %2", _context, _initializationError]] call FLO_fnc_log;
    throw _initializationError;
};

FLO_SideResources = _initializedResources;

[] call FLO_fnc_sideResourcesPublishState;
["ECONOMY", 3, "Initialized unified WEST/EAST side treasuries"] call FLO_fnc_log;

FLO_SideResources
