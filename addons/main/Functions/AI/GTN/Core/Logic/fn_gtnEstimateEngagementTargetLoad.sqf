/*
 * Function: FLO_fnc_gtnEstimateEngagementTargetLoad
 * Author: Frontline Operations Development Group
 * Description:
 *   Estimates the effective combat load of an engagement-picture target for
 *   assignment saturation. This avoids piling multiple friendly groups onto
 *   one small known contact when other valid contacts exist.
 *
 * Arguments:
 * 0: Target data <HASHMAP>
 *
 * Return Value:
 * NUMBER - Estimated target load
 */

params ["_targetData"];

private _groupType = _targetData get "groupType";
private _unitCount = (_targetData get "unitCount") max 1;

switch (_groupType) do {
    case "motorized";
    case "mechanized";
    case "armor";
    case "artillery";
    case "mobile_aa";
    case "static_aa": {
        3 * _unitCount
    };

    case "helicopter";
    case "jet";
    case "air": {
        2 * _unitCount
    };

    default {
        _unitCount
    };
}
