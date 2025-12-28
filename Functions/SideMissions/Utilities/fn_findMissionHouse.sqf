/*
 * Function: FLO_fnc_findMissionHouse
 * Author: Frontline Operations Development Group
 * Description:
 *   Selects a random building suitable for side missions near a center point.
 *   Optionally filters to only include houses in enemy-controlled territory.
 *
 * Arguments:
 *   0: Center object or position (default: player)
 *   1: Search radius (NUMBER, default: 7000)
 *   2: Minimum distance from center (NUMBER, default: 500)
 *   3: Require enemy territory (BOOL, default: true) - Only find houses in OPFOR zones
 *
 * Returns: OBJECT - selected building or objNull if none found
 *
 * Examples:
 *   [getPos player] call FLO_fnc_findMissionHouse;
 *   [getPos player, 5000, 500, true] call FLO_fnc_findMissionHouse;
 */

params [
    ["_center", player],
    ["_radius", 7000],
    ["_min", 500],
    ["_requireEnemyTerritory", true]
];

private _centerPos = if (_center isEqualType objNull) then { position _center } else { _center };

private _houses = nearestObjects [_centerPos, ["House"], _radius] select {
    count (_x buildingPos -1) > 2 && { _centerPos distance _x > _min }
};

if (count _houses == 0) exitWith { objNull };

// Filter by enemy territory if required
if (_requireEnemyTerritory && {!isNil "FLO_Objectives"}) then {
    _houses = _houses select {
        private _housePos = getPos _x;
        private _inEnemyTerritory = false;

        // Check if house is inside any OPFOR-controlled objective
        {
            private _objData = FLO_Objectives get _x;
            if (isNil "_objData") then { continue };

            private _owner = _objData getOrDefault ["owner", east];
            if (_owner isEqualTo east) then {
                if ([_housePos, _objData] call FLO_fnc_isPositionInObjective) then {
                    _inEnemyTerritory = true;
                };
            };

            if (_inEnemyTerritory) then { break };
        } forEach (keys FLO_Objectives);

        _inEnemyTerritory
    };
};

if (count _houses == 0) exitWith { objNull };

selectRandom _houses
