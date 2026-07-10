/*
 * Function: FLO_fnc_transportResetActiveCarrierMotion
 * Author: Frontline Operations Development Group
 * Description:
 *   Clears temporary active-carrier motion restrictions used during staged
 *   unload so reused carriers can move normally again.
 *
 * Arguments:
 *   0: Real Carrier Group <GROUP>
 *
 * Return Value:
 *   BOOL - True when the reset ran
 */

params [["_realGroup", grpNull, [grpNull]]];

if (isNull _realGroup) exitWith { false };

{
    _x forceSpeed -1;
} forEach (([_realGroup] call FLO_fnc_virtualizationCollectRealGroupVehicles) select {
    !isNull _x && {alive _x}
});

true
