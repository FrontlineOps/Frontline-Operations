params [
    ["_objectiveId", "", [""]],
    ["_objective", createHashMap, [createHashMap]],
    ["_previousOwner", sideUnknown, [west]],
    ["_newOwner", sideUnknown, [west]]
];

private _project = _objective get "developmentProject";
private _projectCancelled = (keys _project) isNotEqualTo [];
if (_projectCancelled) then {
    [_objectiveId, _objective, true] call FLO_fnc_objectiveDevelopmentValidateProject;
    if ((_project get "state") == "FUNDING") then {
        private _sideKey = _project get "sideKey";
        private _treasury = FLO_SideResources get _sideKey;
        private _reservationId = _project get "reservationId";
        if !(_reservationId in (_treasury get "_reservations")) then {
            throw format ["Captured Development objective %1 is missing reservation %2", _objectiveId, _reservationId];
        };
        [_treasury, _reservationId, format ["Development at %1 cancelled by capture", _objectiveId]] call FLO_fnc_sideResourcesReleaseReservation;
    };
};

private _retention = FLO_ObjectiveDevelopmentConfig get "captureRetention";
private _previousRevenueLevel = _objective get "revenueLevel";
private _previousDevelopmentLevel = _objective get "developmentLevel";
private _nextRevenueLevel = floor (_previousRevenueLevel * _retention);
private _nextDevelopmentLevel = floor (_previousDevelopmentLevel * _retention);
_objective set ["revenueLevel", _nextRevenueLevel];
_objective set ["developmentLevel", _nextDevelopmentLevel];
_objective set ["developmentProject", createHashMap];

if (_projectCancelled && {_previousOwner in [west, east]}) then {
    [_previousOwner, format ["Development at %1 was lost during the capture.", [_objectiveId] call FLO_fnc_campaignObjectiveName], "warning"] call FLO_fnc_objectiveDevelopmentNotifySide;
};
if (
    _previousRevenueLevel != _nextRevenueLevel
    || {_previousDevelopmentLevel != _nextDevelopmentLevel}
    || {_projectCancelled}
) then {
    ["ECONOMY", 2, format [
        "Objective %1 capture %2->%3 cancelledProject=%4 revenue=%5->%6 development=%7->%8",
        _objectiveId,
        _previousOwner,
        _newOwner,
        _projectCancelled,
        _previousRevenueLevel,
        _nextRevenueLevel,
        _previousDevelopmentLevel,
        _nextDevelopmentLevel
    ]] call FLO_fnc_log;
};

_objective
