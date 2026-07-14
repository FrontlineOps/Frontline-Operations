params [["_objectiveId", "", [""]]];

if !(_objectiveId in FLO_Objectives) then {
    throw format ["Cannot activate missing Development objective %1", _objectiveId];
};
private _objective = FLO_Objectives get _objectiveId;
[_objectiveId, _objective, true] call FLO_fnc_objectiveDevelopmentValidateProject;
private _project = _objective get "developmentProject";
if ((_project get "state") != "FUNDING") then {
    throw format ["Development project %1 cannot activate from state %2", _objectiveId, _project get "state"];
};

private _sideKey = _project get "sideKey";
private _treasury = FLO_SideResources get _sideKey;
private _reservationId = _project get "reservationId";
private _reservations = _treasury get "_reservations";
if !(_reservationId in _reservations) then {
    throw format ["Development project %1 is missing reservation %2", _objectiveId, _reservationId];
};
private _reserved = (_reservations get _reservationId) get "remaining";
private _cost = _project get "treasuryCost";
if (_reserved != _cost) then {
    throw format ["Development project %1 cannot activate with reservation %2/%3", _objectiveId, _reserved, _cost];
};
if !([_treasury, _reservationId, _cost, format ["Activated %1 level %2 at %3", _project get "branch", _project get "targetLevel", _objectiveId]] call FLO_fnc_sideResourcesCommitReservation) then {
    throw format ["Development project %1 failed to commit funded reservation %2", _objectiveId, _reservationId];
};

_project set ["state", "ACTIVE"];
_project set ["startedAtDateNum", call FLO_fnc_operationalDateNumber];
_project set ["reservationId", ""];
_objective set ["developmentProject", _project];
[_objectiveId, _objective, true] call FLO_fnc_objectiveDevelopmentValidateProject;
FLO_Objectives set [_objectiveId, _objective];

private _side = _objective get "owner";
private _objectiveName = [_objectiveId] call FLO_fnc_campaignObjectiveName;
[_side, format [
    "%1 level %2 funded at %3. Local construction has started.",
    _project get "branch",
    _project get "targetLevel",
    _objectiveName
], "success"] call FLO_fnc_objectiveDevelopmentNotifySide;
["ECONOMY", 2, format [
    "%1 activated %2 level %3 at %4 for %5",
    _sideKey,
    _project get "branch",
    _project get "targetLevel",
    _objectiveId,
    _cost
]] call FLO_fnc_log;
true
