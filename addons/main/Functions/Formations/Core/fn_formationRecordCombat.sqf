/* Applies one resolved virtual combat round to participating formations. */
params [
    "_event",
    ["_eastGroupIds", [], [[]]],
    ["_westGroupIds", [], [[]]]
];

if (isNil "FLO_FormationState") then { throw "Formation combat result received before initialization"; };
private _state = FLO_FormationState;
private _index = _state get "groupToFormation";
private _formations = _state get "formations";
private _groups = call FLO_fnc_virtualizationGetGroupMap;
private _affected = createHashMap;
{
    private _sideKey = _x select 0;
    {
        if (_x in _index) then { _affected set [_index get _x, _sideKey]; };
    } forEach (_x select 1);
} forEach [["EAST", _eastGroupIds], ["WEST", _westGroupIds]];

private _winner = _event get "winner";
private _winnerSideKey = ([_winner] call FLO_fnc_gtnSideContext) get "sideKey";
private _decisive = _event get "decisive";
private _zoneId = _event get "objectiveId";
private _round = _event get "roundCount";
{
    private _formation = _formations get _x;
    private _sideKey = _y;
    private _before = [_event get "westBefore", _event get "eastBefore"] select (_sideKey == "EAST");
    private _after = [_event get "westAfter", _event get "eastAfter"] select (_sideKey == "EAST");
    private _lossFraction = ((_before - _after) max 0) / (_before max 1);
    private _surviving = {
        _x in _groups && {((_groups get _x) get "unitCount") > 0}
    } count (_formation get "memberIds");

    if ((_formation get "lastCombatZoneId") != _zoneId || {_round == 1}) then {
        _formation set ["battleCount", (_formation get "battleCount") + 1];
    };
    _formation set ["lastCombatZoneId", _zoneId];
    _formation set ["lastCombatRound", _round];
    _formation set ["lastCombatAtDateNum", call FLO_fnc_operationalDateNumber];
    _formation set ["readiness", (((_formation get "readiness") - 3 - (_lossFraction * 12)) max 0) min 100];
    if (_surviving > 0) then {
        private _experienceGain = 1;
        if (_decisive && {_sideKey == _winnerSideKey}) then { _experienceGain = 5; };
        _formation set ["experience", (((_formation get "experience") + _experienceGain) max 0) min 100];
    };
    if (_decisive) then {
        if (_sideKey == _winnerSideKey) then {
            _formation set ["victories", (_formation get "victories") + 1];
        } else {
            _formation set ["defeats", (_formation get "defeats") + 1];
        };
    };
    private _currentStrength = 0;
    {
        if (_x in _groups) then { _currentStrength = _currentStrength + ((_groups get _x) get "unitCount"); };
    } forEach (_formation get "memberIds");
    _formation set ["lastStrength", _currentStrength];
} forEach _affected;

if ((keys _affected) isNotEqualTo []) then {
    _state set ["revision", (_state get "revision") + 1];
    {
        private _formation = _formations get _x;
        {
            if (_x in _groups) then {
                private _groupData = _groups get _x;
                if (_groupData get "isActive") then {
                    [_x, _groupData get "realGroup"] call FLO_fnc_formationApplyRealGroupSkills;
                };
            };
        } forEach (_formation get "memberIds");
    } forEach (keys _affected);
};
true
