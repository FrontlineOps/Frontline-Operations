/* Selects one side-neutral doctrine from maintained strategic state. */
params [
    "_state",
    ["_sideKey", "", [""]]
];

if !(_sideKey in ["WEST", "EAST"]) then { throw format ["Invalid doctrine side %1", _sideKey]; };
private _side = [_sideKey] call FLO_fnc_campaignSideFromKey;
private _enemySide = [east, west] select (_side isEqualTo east);
private _formationCount = 0;
private _readyReserveCount = 0;
private _mobileReadyCount = 0;
private _readinessTotal = 0;
{
    private _formation = _y;
    if ((_formation get "sideKey") != _sideKey || {(_formation get "memberIds") isEqualTo []}) then { continue };
    _formationCount = _formationCount + 1;
    _readinessTotal = _readinessTotal + (_formation get "readiness");
    if ((_formation get "readiness") >= 65 && {(_formation get "role") in ["RESERVE", "RECOVERY"]}) then {
        _readyReserveCount = _readyReserveCount + 1;
    };
    if ((_formation get "readiness") >= 70 && {(_formation get "branch") in ["motorized", "mechanized", "armor"]}) then {
        _mobileReadyCount = _mobileReadyCount + 1;
    };
} forEach (_state get "formations");
private _averageReadiness = if (_formationCount > 0) then { _readinessTotal / _formationCount } else { 0 };

private _exposedSalients = 0;
private _threatenedObjectives = 0;
private _credibleTargets = 0;
{
    private _objective = _y;
    private _owner = _objective get "owner";
    if (_owner isEqualTo _side) then {
        private _enemyLinks = 0;
        private _friendlyLinks = 0;
        {
            private _linkedOwner = (FLO_Objectives get _x) get "owner";
            if (_linkedOwner isEqualTo _enemySide) then { _enemyLinks = _enemyLinks + 1; };
            if (_linkedOwner isEqualTo _side) then { _friendlyLinks = _friendlyLinks + 1; };
        } forEach (_objective get "linkedObjectives");
        if (
            (_objective get "campaignIntegrationState") == "INTEGRATED"
            && {_enemyLinks >= 2}
            && {_friendlyLinks <= 1}
            && {(_objective get "priority") < 90}
            && {(_objective get "subtype") != "capital"}
        ) then { _exposedSalients = _exposedSalients + 1; };
        if (_objective get "underAttack" || {_objective get "contested"}) then {
            _threatenedObjectives = _threatenedObjectives + 1;
        };
    };
    if (_owner isEqualTo _enemySide) then {
        private _reachable = false;
        {
            private _linked = FLO_Objectives get _x;
            if ((_linked get "owner") isEqualTo _side && {(_linked get "campaignIntegrationState") == "INTEGRATED"}) exitWith {
                _reachable = true;
            };
        } forEach (_objective get "linkedObjectives");
        if (_reachable) then { _credibleTargets = _credibleTargets + 1; };
    };
} forEach FLO_Objectives;

private _treasury = FLO_SideResources get _sideKey;
private _available = _treasury call ["getAvailable", []];
private _doctrine = "ECONOMY_OF_FORCE";
if (_averageReadiness >= 45 && {_available >= 1000}) then {
    private _scores = [
        [-((_mobileReadyCount min 4) * 25 + _averageReadiness - ((_exposedSalients min 3) * 5)), "BREAKTHROUGH"],
        [-((_credibleTargets min 4) * 20 + ((_formationCount min 10) * 3) + (_averageReadiness * 0.30)), "DECEPTION"],
        [-((_exposedSalients min 4) * 35 + ((100 - _averageReadiness) * 0.50)), "ELASTIC_DEFENSE"],
        [-((_threatenedObjectives min 4) * 45 + ((_readyReserveCount min 4) * 10)), "COUNTERATTACK"],
        [-20, "ECONOMY_OF_FORCE"]
    ];
    _scores sort true;
    _doctrine = (_scores select 0) select 1;
};

private _doctrines = _state get "doctrineBySide";
if ((_doctrines get _sideKey) != _doctrine) then {
    _doctrines set [_sideKey, _doctrine];
    _state set ["revision", (_state get "revision") + 1];
};
_state set ["lastDoctrineUpdateAtDateNum", dateToNumber date];
["FORMATIONS", 3, format [
    "%1 doctrine %2 (formations=%3 readiness=%4 reserve=%5 mobile=%6 salients=%7 threats=%8 targets=%9 available=%10)",
    _sideKey, _doctrine, _formationCount, round _averageReadiness, _readyReserveCount, _mobileReadyCount,
    _exposedSalients, _threatenedObjectives, _credibleTargets, round _available
]] call FLO_fnc_log;
_doctrine
