/*
 * Function: FLO_fnc_factionGetGroupConfigs
 * Author: Frontline Operations Development Group
 * Description:
 *   Collects usable all-infantry CfgGroups entries for a faction.
 *
 * Arguments:
 *   0: Faction classname <STRING>
 *
 * Return Value:
 *   HASHMAP with keys infantryGroups, specOpsGroups, infantryUnits, hasGroups
 */

params [["_factionClass", "", [""]]];

private _result = createHashMapFromArray [
    ["infantryGroups", []],
    ["specOpsGroups", []],
    ["infantryUnits", []],
    ["hasGroups", false]
];

if (_factionClass == "") exitWith { _result };

private _facCfg = configFile >> "CfgFactionClasses" >> _factionClass;
if !(isClass _facCfg) exitWith { _result };

private _side = getNumber (_facCfg >> "side");
if !(_side in [0, 1, 2, 3]) exitWith { _result };

private _sideName = ["East", "West", "Indep", "Civilian"] select _side;
private _groupsRoot = configFile >> "CfgGroups" >> _sideName >> _factionClass;
if !(isClass _groupsRoot) exitWith { _result };

private _infantryGroups = [];
private _specOpsGroups = [];
private _infantryUnits = [];

for "_i" from 0 to (count _groupsRoot - 1) do {
    private _category = _groupsRoot select _i;
    if !(isClass _category) then { continue };

    private _catNameLower = toLower (configName _category);
    private _catDisplayLower = toLower (getText (_category >> "name"));
    private _catLooksSpecOps = (_catNameLower find "spec") >= 0 ||
        {(_catNameLower find "recon") >= 0} ||
        {(_catNameLower find "sniper") >= 0} ||
        {(_catNameLower find "diver") >= 0} ||
        {(_catDisplayLower find "spec") >= 0} ||
        {(_catDisplayLower find "recon") >= 0} ||
        {(_catDisplayLower find "sniper") >= 0} ||
        {(_catDisplayLower find "diver") >= 0};

    for "_j" from 0 to (count _category - 1) do {
        private _groupCfg = _category select _j;
        if !(isClass _groupCfg) then { continue };

        private _unitClasses = [];
        {
            private _unitClass = getText (_x >> "vehicle");
            if (_unitClass != "") then {
                _unitClasses pushBackUnique _unitClass;
            };
        } forEach ("true" configClasses _groupCfg);

        if (_unitClasses isEqualTo []) then { continue };

        private _allMen = true;
        {
            if !(_x isKindOf "Man") exitWith {
                _allMen = false;
            };
        } forEach _unitClasses;

        if (!_allMen) then { continue };

        _infantryUnits append _unitClasses;

        private _grpNameLower = toLower (configName _groupCfg);
        private _grpDisplayLower = toLower (getText (_groupCfg >> "name"));
        private _grpLooksSpecOps = _catLooksSpecOps ||
            {(_grpNameLower find "spec") >= 0} ||
            {(_grpNameLower find "recon") >= 0} ||
            {(_grpNameLower find "sniper") >= 0} ||
            {(_grpNameLower find "diver") >= 0} ||
            {(_grpDisplayLower find "spec") >= 0} ||
            {(_grpDisplayLower find "recon") >= 0} ||
            {(_grpDisplayLower find "sniper") >= 0} ||
            {(_grpDisplayLower find "diver") >= 0};

        if (_grpLooksSpecOps) then {
            _specOpsGroups pushBack _groupCfg;
        } else {
            _infantryGroups pushBack _groupCfg;
        };
    };
};

_result set ["infantryGroups", _infantryGroups];
_result set ["specOpsGroups", _specOpsGroups];
_result set ["infantryUnits", _infantryUnits arrayIntersect _infantryUnits];
_result set ["hasGroups", (count _infantryGroups + count _specOpsGroups) > 0];

_result
