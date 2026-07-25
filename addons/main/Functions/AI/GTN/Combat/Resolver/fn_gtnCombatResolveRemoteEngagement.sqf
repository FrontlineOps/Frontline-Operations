/* Resolves one deterministic-trend remote combat round with bounded friction. */
params ["_groups", "_eastRefs", "_westRefs", "_supportAvailability", ["_zoneId", "", [""]]];

private _eastStats = [_eastRefs] call FLO_fnc_gtnCombatSidePower;
private _westStats = [_westRefs] call FLO_fnc_gtnCombatSidePower;
private _eastBefore = _eastStats get "units";
private _westBefore = _westStats get "units";
private _eastPower = _eastStats get "power";
private _westPower = _westStats get "power";
if (_eastPower <= 0 || {_westPower <= 0}) then {
    throw format ["Cannot resolve powerless engagement %1: EAST %2 WEST %3", _zoneId, _eastPower, _westPower];
};

private _supportEast = [east, _supportAvailability] call FLO_fnc_gtnCombatSupportBonus;
private _supportWest = [west, _supportAvailability] call FLO_fnc_gtnCombatSupportBonus;
private _eastComposition = 1;
private _westComposition = 1;
if ((_eastStats get "armor") > 0 && {(_westStats get "infantry") > 0}) then { _eastComposition = _eastComposition + 0.08; };
if ((_westStats get "armor") > 0 && {(_eastStats get "infantry") > 0}) then { _westComposition = _westComposition + 0.08; };
if ((_eastStats get "infantry") >= ((_westStats get "armor") * 4) && {(_westStats get "armor") > 0}) then {
    _eastComposition = _eastComposition + 0.04;
};
if ((_westStats get "infantry") >= ((_eastStats get "armor") * 4) && {(_eastStats get "armor") > 0}) then {
    _westComposition = _westComposition + 0.04;
};

private _eastEffectivePower = _eastPower * _eastComposition * (1 + ((_supportEast get "total") * 0.08));
private _westEffectivePower = _westPower * _westComposition * (1 + ((_supportWest get "total") * 0.08));
private _powerTotal = (_eastEffectivePower + _westEffectivePower) max 1;
private _powerBalance = (_eastEffectivePower - _westEffectivePower) / _powerTotal;
private _friction = (random 0.1) - 0.05;
private _roundSignal = ((_powerBalance + _friction) max -1) min 1;

private _state = call FLO_fnc_gtnCombatGetState;
private _engagements = _state get "engagements";
private _engagement = if (_zoneId in _engagements) then {
    _engagements get _zoneId
} else {
    createHashMapFromArray [
        ["momentum", 0],
        ["roundCount", 0],
        ["lastSeenAt", diag_tickTime],
        ["artilleryReadyAt", 0],
        ["artilleryMissionCount", 0],
        ["lastArtillerySide", ""]
    ]
};
private _roundCount = (_engagement get "roundCount") + 1;
private _momentum = (((_engagement get "momentum") * 0.7) + (_roundSignal * 30)) max -100 min 100;
_engagement set ["momentum", _momentum];
_engagement set ["roundCount", _roundCount];
_engagement set ["lastSeenAt", diag_tickTime];
_engagements set [_zoneId, _engagement];

private _effectiveRatio = (_eastEffectivePower max _westEffectivePower) / ((_eastEffectivePower min _westEffectivePower) max 1);
private _winner = if (_roundSignal >= 0) then { east } else { west };
private _decisive = false;
if (_effectiveRatio >= 2.5 && {_roundCount >= 2}) then {
    _decisive = true;
    _winner = if (_eastEffectivePower >= _westEffectivePower) then { east } else { west };
};
if (!_decisive && {_roundCount >= 3} && {abs _momentum >= 30}) then {
    _decisive = true;
    _winner = if (_momentum >= 0) then { east } else { west };
};
if (!_decisive && {_roundCount >= 12}) then {
    _decisive = true;
    _winner = if (_eastEffectivePower == _westEffectivePower) then {
        [west, east] select (_roundSignal >= 0)
    } else {
        [west, east] select (_eastEffectivePower > _westEffectivePower)
    };
};

private _eastPressure = _westEffectivePower / _powerTotal;
private _westPressure = _eastEffectivePower / _powerTotal;
private _eastLossPct = (0.02 + (_eastPressure * 0.06)) max 0.02 min 0.08;
private _westLossPct = (0.02 + (_westPressure * 0.06)) max 0.02 min 0.08;
private _decisiveLossPct = 0;
if (_decisive) then {
    private _decisiveLossScale = ((_effectiveRatio - 1) / 1.5) max 0 min 1;
    _decisiveLossPct = 0.15 + (_decisiveLossScale * 0.05);
    if (_winner isEqualTo east) then {
        _westLossPct = _decisiveLossPct;
    } else {
        _eastLossPct = _decisiveLossPct;
    };
};

private _eastLosses = [_groups, _eastRefs, _eastLossPct] call FLO_fnc_gtnCombatApplyAttrition;
private _westLosses = [_groups, _westRefs, _westLossPct] call FLO_fnc_gtnCombatApplyAttrition;
if (_decisive) then { _engagements deleteAt _zoneId; };

createHashMapFromArray [
    ["winner", _winner],
    ["decisive", _decisive],
    ["decisiveLossPct", _decisiveLossPct],
    ["margin", abs _powerBalance],
    ["friction", _friction],
    ["momentum", _momentum],
    ["roundCount", _roundCount],
    ["effectiveRatio", _effectiveRatio],
    ["eastPower", _eastPower],
    ["westPower", _westPower],
    ["eastEffectivePower", _eastEffectivePower],
    ["westEffectivePower", _westEffectivePower],
    ["eastSupport", _supportEast get "total"],
    ["westSupport", _supportWest get "total"],
    ["artilleryRequestedBy", ""],
    ["eastBefore", _eastBefore],
    ["eastAfter", (_eastBefore - _eastLosses) max 0],
    ["westBefore", _westBefore],
    ["westAfter", (_westBefore - _westLosses) max 0]
]
