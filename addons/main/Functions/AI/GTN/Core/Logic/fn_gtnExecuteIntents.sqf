/* Every admitted intent is monitored each cycle; order work shares one budget. */
params ["_commander"];
private _intents = _commander get "_intents";
private _ids = keys _intents;
_ids sort true;
private _processed = 0;
private _completed = 0;
private _failed = 0;
private _planMs = 0;
private _executeMs = 0;
private _count = count _ids;
private _cursor = if (_count > 0) then { (_commander get "_nextTrackExecutionIndex") mod _count } else { 0 };
for "_offset" from 0 to (_count - 1) do {
    private _id = _ids select ((_cursor + _offset) mod _count);
    private _result = [_commander, FLO_fnc_gtnExecuteIntent, [_commander, _id]] call FLO_fnc_gtnRunCycleStep;
    _processed = _processed + (_result select 0);
    _completed = _completed + (_result select 1);
    _failed = _failed + (_result select 2);
    _planMs = _planMs + (_result select 3);
    _executeMs = _executeMs + (_result select 4);
};
_commander set ["_nextTrackExecutionIndex", _cursor + 1];
createHashMapFromArray [["processed", _processed], ["completed", _completed], ["failed", _failed], ["planMs", _planMs], ["executeMs", _executeMs]]
