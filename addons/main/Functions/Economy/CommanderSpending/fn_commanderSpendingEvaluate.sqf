/* Evaluates one autonomous commander commitment or expenditure. */
params [
    "_treasury",
    ["_amount", 0, [0]],
    ["_category", "", [""]],
    ["_urgency", "", [""]],
    ["_context", createHashMap, [createHashMap]]
];

if (_amount <= 0) then {
    throw format ["Commander spending amount must be positive, got %1", _amount];
};
_category = toUpper _category;
_urgency = toUpper _urgency;
if !(_category in ["OPERATION", "REINFORCEMENT", "TRANSPORT", "ARTILLERY", "AIR_SUPPORT", "FORTIFICATION", "LOGISTICS", "DEVELOPMENT"]) then {
    throw format ["Invalid commander spending category %1", _category];
};
if !(_urgency in ["ROUTINE", "OPERATIONAL", "PRESSURED", "CRITICAL"]) then {
    throw format ["Invalid commander spending urgency %1", _urgency];
};
{
    if !(_x in _context) then {
        throw format ["Commander spending context is missing %1", _x];
    };
} forEach ["strategic", "commitment", "reserved", "referenceId"];

private _strategic = _context get "strategic";
private _commitment = _context get "commitment";
private _reserved = _context get "reserved";
if !(_strategic isEqualType false && {_commitment isEqualType false} && {_reserved isEqualType false}) then {
    throw "Commander spending context flags must be booleans";
};

private _state = [_treasury] call FLO_fnc_commanderSpendingGetState;
private _policy = _treasury get "COMMANDER_SPENDING_POLICY";
private _reserveMultiplier = (_policy get "urgencyReserveMultipliers") get _urgency;
private _requiredReserve = if (_urgency == "CRITICAL") then {
    _state get "emergencyReserve"
} else {
    round ((_state get "reserveFloor") * _reserveMultiplier)
};
private _postSpendAvailable = _state get "available";
if (!_reserved) then {
    _postSpendAvailable = _postSpendAvailable - _amount;
};

private _maximumAmount = [
    ((_state get "available") - _requiredReserve) max 0,
    _amount
] select _reserved;

private _allowed = true;
private _reason = "APPROVED";
if (!_reserved && {_postSpendAvailable < (_state get "emergencyReserve")}) then {
    _allowed = false;
    _reason = "EMERGENCY_RESERVE";
} else {
    if (!_reserved && {_postSpendAvailable < _requiredReserve}) then {
        _allowed = false;
        _reason = "DOCTRINE_RESERVE";
    };
};

private _decision = createHashMapFromArray [
    ["allowed", _allowed],
    ["reason", _reason],
    ["category", _category],
    ["urgency", _urgency],
    ["amount", _amount],
    ["posture", _state get "posture"],
    ["reserveFloor", _state get "reserveFloor"],
    ["requiredReserve", _requiredReserve],
    ["emergencyReserve", _state get "emergencyReserve"],
    ["postSpendAvailable", _postSpendAvailable],
    ["maximumAmount", _maximumAmount],
    ["strategic", _strategic],
    ["commitment", _commitment],
    ["reserved", _reserved]
];

if (!_allowed) then {
    private _denialKey = format ["%1:%2:%3", _category, _urgency, _reason];
    private _denials = _treasury get "_commanderSpendingDenials";
    private _lastLoggedAt = if (_denialKey in _denials) then { _denials get _denialKey } else { -1e12 };
    if ((diag_tickTime - _lastLoggedAt) >= (_policy get "denialLogCooldownSeconds")) then {
        _denials set [_denialKey, diag_tickTime];
        ["ECONOMY", 4, format [
            "%1 commander spend denied category=%2 urgency=%3 amount=%4 posture=%5 reason=%6 available=%7 reserve=%8 ref=%9",
            _state get "sideKey",
            _category,
            _urgency,
            _amount,
            _state get "posture",
            _reason,
            _state get "available",
            _requiredReserve,
            _context get "referenceId"
        ]] call FLO_fnc_log;
    };
};

_decision
