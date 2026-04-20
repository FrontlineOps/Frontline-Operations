/*
 * Function: FLO_fnc_factionGetObjectiveGroupFieldSpecs
 * Author: Frontline Operations Development Group
 * Description:
 *   Returns mission setup objective group field specs for a side.
 *
 * Arguments:
 *   0: Side label <STRING> - "BLUFOR" or "OPFOR"
 *
 * Return Value:
 *   ARRAY of [idc, "objective", subtype, groupType]
 */

params [["_sideLabel", "", [""]]];

private _subtypes = ["capital", "city", "village", "local", "marine", "cluster"];
private _groupTypes = ["infantry", "motorized", "mechanized", "armor", "air", "artillery", "mobile_aa", "static_aa"];

private _fnc_buildSpecs = {
    params ["_startIdc"];

    private _specs = [];
    {
        private _subtype = _x;
        private _subtypeOffset = _forEachIndex * count _groupTypes;

        {
            _specs pushBack [_startIdc + _subtypeOffset + _forEachIndex, "objective", _subtype, _x];
        } forEach _groupTypes;
    } forEach _subtypes;

    _specs
};

switch (toUpper _sideLabel) do {
    case "BLUFOR": {
        [2200] call _fnc_buildSpecs
    };
    case "OPFOR": {
        [2248] call _fnc_buildSpecs
    };
    default {
        ["FACTIONS", 1, format ["Unknown objective group field side '%1'", _sideLabel]] call FLO_fnc_log;
        []
    };
};
