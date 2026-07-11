/*
 * Function: FLO_fnc_virtualizationResolveTransportPassengerCasualty
 * Description:
 *   Removes impossible or exhausted active passenger groups before attached
 *   processing can hide them from ordinary lifecycle cleanup.
 */

params [
    ["_passengerGroupId", "", [""]],
    ["_carrierGroupId", "", [""]]
];

if (_passengerGroupId == "" || {_carrierGroupId == ""}) then {
    throw "Transport passenger casualty resolution requires passenger and carrier IDs";
};

private _passengerData = [_passengerGroupId] call FLO_fnc_virtualizationFindGroup;
if (isNil "_passengerData") exitWith { false };

private _attachedTo = _passengerData get "attachedTo";
if (_attachedTo != _carrierGroupId) then {
    throw format [
        "Transport passenger %1 expected carrier %2 but is attached to %3",
        _passengerGroupId,
        _carrierGroupId,
        _attachedTo
    ];
};
if !(_passengerData get "isActive") exitWith { false };

private _realGroup = _passengerData get "realGroup";
if (isNull _realGroup) exitWith {
    ["TRANSPORT", 1, format [
        "Removing orphaned active passenger %1 from carrier %2",
        _passengerGroupId,
        _carrierGroupId
    ]] call FLO_fnc_log;
    [_passengerGroupId] call FLO_fnc_virtualizationRepairOrphanedActiveGroup
};

if (({alive _x} count units _realGroup) > 0) exitWith { false };

["TRANSPORT", 2, format [
    "Removing exhausted active passenger %1 from carrier %2",
    _passengerGroupId,
    _carrierGroupId
]] call FLO_fnc_log;

[_passengerGroupId, _carrierGroupId] call FLO_fnc_virtualizationDeactivateMountedPassengerGroup
