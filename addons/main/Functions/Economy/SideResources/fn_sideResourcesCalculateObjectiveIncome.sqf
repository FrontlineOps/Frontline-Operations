params ["_treasury", "_objective"];

private _side = _treasury get "_side";
private _friendlyCount = [_objective get "opforCount", _objective get "bluforCount"] select (_side isEqualTo west);
private _enemyCount = [_objective get "bluforCount", _objective get "opforCount"] select (_side isEqualTo west);
private _status = "SECURE";

if (_enemyCount > 0) then {
    _status = if (_friendlyCount <= 0) then {
        "OVERRUN"
    } else {
        ["CONTESTED", "DEFENDED"] select (_friendlyCount > _enemyCount)
    };
};

private _multiplier = (_treasury get "CONTEST_MODIFIERS") get _status;
private _captureProgress = _objective get "captureProgress";
private _underPressure = [_captureProgress > 0, _captureProgress < 0] select (_side isEqualTo west);
if (_underPressure) then { _multiplier = _multiplier * 0.85; };

[((_treasury get "RESOURCE_VALUES") get (_objective get "subtype")) * _multiplier, _status]
