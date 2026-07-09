/*
 * Function: FLO_fnc_virtualizationDeactivateMountedPassengers
 * Author: Frontline Operations Development Group
 * Description:
 *   Virtualizes all mounted passenger groups currently spawned inside a carrier.
 *   This is called before the carrier deletes its real vehicle assets.
 *
 * Arguments:
 * 0: Carrier Group ID <STRING>
 * 1: Carrier Group Data <HASHMAP>
 *
 * Return Value:
 * NUMBER - Count of passenger groups virtualized
 */

params [
    ["_carrierGroupId", "", [""]],
    ["_carrierData", createHashMap, [createHashMap]]
];

if (_carrierGroupId == "") exitWith { 0 };

private _attachedIds = [_carrierData] call FLO_fnc_virtualizationGetTransportPassengers;
if (_attachedIds isEqualTo []) exitWith { 0 };

private _groups = FLO_virtualGroups get "_groups";
private _deactivatedCount = 0;

{
    private _attachedId = _x;
    private _attachedData = _groups get _attachedId;
    if (isNil "_attachedData") then { continue };
    if (([_attachedData] call FLO_fnc_virtualizationGetMountedTransport) != _carrierGroupId) then { continue };
    if !((_attachedData get "isActive") || {!isNull (_attachedData get "realGroup")}) then {
        [_attachedData] call FLO_fnc_virtualizationClearMountedIn;
        continue;
    };

    if ([_attachedId, _attachedData, _carrierGroupId] call FLO_fnc_virtualizationDeactivateMountedPassengerGroup) then {
        _deactivatedCount = _deactivatedCount + 1;
    };
} forEach _attachedIds;

if (_deactivatedCount > 0) then {
    ["VIRTUALIZATION", 3, format [
        "Carrier %1 virtualized %2 mounted passenger groups",
        _carrierGroupId,
        _deactivatedCount
    ]] call FLO_fnc_log;
};

_deactivatedCount
