/*
 * Function: FLO_fnc_campaignRegisterBase
 * Description:
 *   Registers a living FOB/COP in the maintained campaign base list.
 */

params [["_base", objNull, [objNull]]];

if (!isServer || {isNull _base}) exitWith { false };
FLO_CampaignBases pushBackUnique _base;

private _side = _base getVariable ["FLO_BaseSide", sideUnknown];
if (_side in [west, east] && {!isNil "FLO_Logistics_Networks"}) then {
    private _sideKey = ([_side] call FLO_fnc_gtnSideContext) get "sideKey";
    if (_sideKey in FLO_Logistics_Networks) then {
        [FLO_Logistics_Networks get _sideKey, _base] call FLO_fnc_logisticsNetworkRegisterBaseNode;
        [FLO_Logistics_Networks get _sideKey, true] call FLO_fnc_logisticsNetworkEnsureSupplyChainFresh;
    };
};
true
