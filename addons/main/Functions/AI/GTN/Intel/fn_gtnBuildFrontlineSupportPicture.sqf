/* Aggregates maintained past and present enemy contacts by canonical probe front. */
params [
    "_cmdr",
    ["_fronts", createHashMap, [createHashMap]]
];

private _sideKey = _cmdr get "_sideKey";
private _ws = _cmdr get "_worldState";
private _objectives = _ws call ["_getObjectives", []];
private _enemyIntel = _ws call ["_getEnemyIntel", []];
private _contacts = _enemyIntel get "contactReports";
private _knownPicture = _enemyIntel get "knownGroupPicture";
private _knownGroups = _knownPicture get "groups";
private _virtualGroups = call FLO_fnc_virtualizationGetGroupMap;
private _config = _cmdr get "_config";
private _maxAge = _config get "frontlineSupportContactMaxAgeSeconds";
private _freshAge = _config get "frontlineSupportContactFreshSeconds";
private _associationRadius = _config get "frontlineSupportAssociationRadius";
private _now = diag_tickTime;
private _rows = [];
private _picture = createHashMap;

{
    private _front = _y;
    if ((_front get "sideKey") != _sideKey) then { continue };
    private _objectiveId = _front get "objectiveId";
    if !(_objectiveId in _objectives) then {
        throw format ["Frontline support picture references missing objective %1", _objectiveId];
    };
    private _objective = _objectives get _objectiveId;
    private _objectivePos = +(_objective get "position");
    _rows pushBack [_x, _objectivePos, (_objective get "radius") + _associationRadius];
    _picture set [_x, createHashMapFromArray [
        ["probeId", _x],
        ["objectiveId", _objectiveId],
        ["targetPos", _objectivePos],
        ["reportCount", 0],
        ["freshReportCount", 0],
        ["totalStrength", 0],
        ["confidence", 0],
        ["newestContactTime", -1],
        ["ageSeconds", 1e12],
        ["uncertaintyRadius", 700],
        ["targetGroupIds", []],
        ["score", 0],
        ["sumX", 0],
        ["sumY", 0],
        ["sumWeight", 0]
    ]];
} forEach _fronts;

if (_rows isEqualTo []) exitWith { _picture };

{
    _x params ["_contactPos", "_contactTime", "_strength", "_contactType", "_confidence"];
    private _age = _now - _contactTime;
    if (_age < 0 || {_age > _maxAge}) then { continue };
    if ((toLower _contactType) in ["air", "helicopter", "plane"]) then { continue };

    private _bestProbeId = "";
    private _bestDistance = 1e12;
    {
        _x params ["_probeId", "_objectivePos", "_maximumDistance"];
        private _distance = _contactPos distance2D _objectivePos;
        if (_distance <= _maximumDistance && {_distance < _bestDistance}) then {
            _bestProbeId = _probeId;
            _bestDistance = _distance;
        };
    } forEach _rows;
    if (_bestProbeId == "") then { continue };

    private _entry = _picture get _bestProbeId;
    private _weight = ((_confidence max 0.1) * ((_strength max 1) min 20));
    _entry set ["reportCount", (_entry get "reportCount") + 1];
    if (_age <= _freshAge) then {
        _entry set ["freshReportCount", (_entry get "freshReportCount") + 1];
    };
    _entry set ["totalStrength", (_entry get "totalStrength") + (_strength max 0)];
    _entry set ["confidence", (_entry get "confidence") max _confidence];
    _entry set ["newestContactTime", (_entry get "newestContactTime") max _contactTime];
    _entry set ["sumX", (_entry get "sumX") + ((_contactPos select 0) * _weight)];
    _entry set ["sumY", (_entry get "sumY") + ((_contactPos select 1) * _weight)];
    _entry set ["sumWeight", (_entry get "sumWeight") + _weight];
} forEach _contacts;

{
    private _groupId = _x;
    if !(_groupId in _virtualGroups) then { continue };
    private _known = _y;
    private _age = _now - (_known get "lastSeen");
    if (_age < 0 || {_age > _freshAge}) then { continue };
    private _knownPos = _known get "position";
    private _bestProbeId = "";
    private _bestDistance = 1e12;
    {
        _x params ["_probeId", "_objectivePos", "_maximumDistance"];
        private _distance = _knownPos distance2D _objectivePos;
        if (_distance <= _maximumDistance && {_distance < _bestDistance}) then {
            _bestProbeId = _probeId;
            _bestDistance = _distance;
        };
    } forEach _rows;
    if (_bestProbeId == "") then { continue };
    private _entry = _picture get _bestProbeId;
    private _targetIds = _entry get "targetGroupIds";
    _targetIds pushBackUnique _groupId;
    _entry set ["targetGroupIds", _targetIds];
} forEach _knownGroups;

{
    private _entry = _y;
    private _weight = _entry get "sumWeight";
    if (_weight > 0) then {
        _entry set ["targetPos", [(_entry get "sumX") / _weight, (_entry get "sumY") / _weight, 0]];
        private _age = _now - (_entry get "newestContactTime");
        _entry set ["ageSeconds", _age];
        _entry set ["uncertaintyRadius", linearConversion [0, _maxAge, _age, 120, 700, true]];
        _entry set ["score",
            ((_entry get "confidence") * 100)
            + ((_entry get "freshReportCount") * 30)
            + ((_entry get "reportCount") * 8)
            + ((_entry get "totalStrength") * 2)
            - (_age / 15)
        ];
    };
    _entry deleteAt "sumX";
    _entry deleteAt "sumY";
    _entry deleteAt "sumWeight";
} forEach _picture;

_picture
