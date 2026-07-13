private _seenReservations = createHashMap;

{
    private _objectiveId = _x;
    private _objective = _y;
    private _project = _objective get "developmentProject";
    if ((keys _project) isEqualTo []) then { continue };
    [_objectiveId, _objective, true] call FLO_fnc_objectiveDevelopmentValidateProject;
    if ((_project get "state") != "FUNDING") then { continue };

    private _sideKey = _project get "sideKey";
    private _treasury = FLO_SideResources get _sideKey;
    private _reservationId = _project get "reservationId";
    if (_reservationId in _seenReservations) then {
        throw format ["Development reservation %1 is referenced by multiple objectives", _reservationId];
    };
    private _reservations = _treasury get "_reservations";
    if !(_reservationId in _reservations) then {
        throw format ["Development objective %1 is missing reservation %2", _objectiveId, _reservationId];
    };
    private _reservation = _reservations get _reservationId;
    if (
        (_reservation get "category") != "DEVELOPMENT"
        || {(_reservation get "actor") != "COMMANDER"}
        || {(_reservation get "referenceId") != _objectiveId}
    ) then {
        throw format ["Development reservation %1 metadata does not match objective %2", _reservationId, _objectiveId];
    };
    private _reserved = _reservation get "remaining";
    if (_reserved <= 0 || {_reserved > (_project get "treasuryCost")} || {_reserved != (_reservation get "initial")}) then {
        throw format ["Development reservation %1 has invalid amount %2", _reservationId, _reserved];
    };
    _seenReservations set [_reservationId, _objectiveId];
} forEach FLO_Objectives;

{
    private _sideKey = _x;
    private _network = FLO_Logistics_Networks get _sideKey;
    if ((_network get "SHIPMENT_THROUGHPUT") != (FLO_ObjectiveDevelopmentConfig get "shipmentAmount")) then {
        throw format ["Development shipment amount does not match %1 logistics network", _sideKey];
    };
    [_sideKey] call FLO_fnc_objectiveDevelopmentGetFundingObjectiveId;
    private _reservations = (FLO_SideResources get _sideKey) get "_reservations";
    {
        if ((_x find "DEVELOPMENT:") != 0) then { continue };
        if !(_x in _seenReservations) then {
            throw format ["Treasury %1 contains orphaned Development reservation %2", _sideKey, _x];
        };
    } forEach _reservations;
} forEach ["WEST", "EAST"];

true
