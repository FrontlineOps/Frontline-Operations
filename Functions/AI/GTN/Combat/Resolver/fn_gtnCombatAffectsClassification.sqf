/*
 * Function: FLO_fnc_gtnCombatAffectsClassification
 * Author: Frontline Operations Development Group
 * Description:
 *   Returns whether a virtual group currently affects combat classification,
 *   either as a direct combat participant or as an available support provider.
 *
 * Arguments:
 *   0: Group data <HASHMAP>
 *
 * Return Value:
 *   Classification relevance <BOOL>
 */

params ["_groupData"];

private _side = _groupData get "side";
if !(_side in [east, west]) exitWith { false };
if (([_groupData] call FLO_fnc_virtualizationGetTransportAttachment) != "") exitWith { false };

private _groupType = _groupData get "groupType";
if ([_groupType] call FLO_fnc_gtnCombatIsDirectCombatGroup) exitWith {
    (_groupData get "unitCount") > 0
};

if ([_groupType] call FLO_fnc_gtnCombatIsSupportProvider) exitWith {
    (_groupData get "unitCount") > 0
};

false
