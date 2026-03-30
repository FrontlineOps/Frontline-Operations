/*
 * Function: FLO_fnc_transportIssueActiveDismount
 * Author: Frontline Operations Development Group
 * Description:
 *   Issues a live get-out order to every surviving mounted passenger in an
 *   active carrier and marks the carrier as being in staged unload.
 *
 * Arguments:
 *   0: Carrier Group ID <STRING>
 *   1: Carrier Group Data <HASHMAP>
 *   2: Carrier Vehicles <ARRAY>
 *
 * Return Value:
 *   BOOL - True when a live unload command was issued
 */

params [
    ["_carrierGroupId", "", [""]],
    ["_carrierData", createHashMap, [createHashMap]],
    ["_transportVehicles", [], [[]]]
];

if (_carrierGroupId == "") exitWith { false };
if (count _transportVehicles == 0) exitWith { false };

private _groups = FLO_virtualGroups get "_groups";
private _issuedCount = 0;

{
    private _passengerData = _groups get _x;
    if (isNil "_passengerData") then { continue; };
    if !(_passengerData get "isActive") then { continue; };

    private _realGroup = _passengerData get "realGroup";
    if (isNull _realGroup) then { continue; };

    {
        if (!alive _x) then { continue; };

        private _veh = vehicle _x;
        if (_veh == _x || {!(_veh in _transportVehicles)}) then { continue; };

        unassignVehicle _x;
        _x action ["GetOut", _veh];
        _issuedCount = _issuedCount + 1;
    } forEach units _realGroup;
} forEach ([_carrierData] call FLO_fnc_virtualizationGetTransportPassengers);

if (_issuedCount == 0) exitWith { false };

_carrierData set ["transportUnloadCommandIssued", true];
_carrierData set ["transportUnloadIssuedAt", diag_tickTime];

["TRANSPORT", 3, format [
    "Active carrier %1 issued live dismount to %2 mounted passengers",
    _carrierGroupId,
    _issuedCount
]] call FLO_fnc_log;

true
