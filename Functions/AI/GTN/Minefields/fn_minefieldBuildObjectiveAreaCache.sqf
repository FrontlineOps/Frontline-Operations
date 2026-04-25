/*
 * Function: FLO_fnc_minefieldBuildObjectiveAreaCache
 * Author: Frontline Operations Development Group
 * Description:
 *   Builds a static objective area cache for minefield placement so repeated
 *   overlap checks can reject obvious misses without paying full polygon tests.
 *
 * Arguments: None
 *
 * Return Value:
 * HASHMAP
 */

if (isNil "FLO_Objectives") exitWith { createHashMap };

private _cache = createHashMap;

{
    private _objectiveId = _x;
    private _objective = FLO_Objectives get _objectiveId;
    private _center = _objective get "position";
    private _radius = ((_objective get "radius") max 35);
    private _polygon = [];
    private _usePolygon = false;
    if (("usePolygon" in _objective) && {"polygon" in _objective}) then {
        _polygon = _objective get "polygon";
        _usePolygon = (_objective get "usePolygon") && {count _polygon >= 3};
    };

    private _entry = createHashMapFromArray [
        ["center", _center],
        ["radius", _radius],
        ["usePolygon", _usePolygon]
    ];

    if (_usePolygon) then {
        private _minX = 1e10;
        private _maxX = -1e10;
        private _minY = 1e10;
        private _maxY = -1e10;

        {
            _minX = _minX min (_x select 0);
            _maxX = _maxX max (_x select 0);
            _minY = _minY min (_x select 1);
            _maxY = _maxY max (_x select 1);
            _radius = _radius max (_center distance2D _x);
        } forEach _polygon;

        _entry set ["radius", _radius];
        _entry set ["polygon", _polygon];
        _entry set ["minX", _minX];
        _entry set ["maxX", _maxX];
        _entry set ["minY", _minY];
        _entry set ["maxY", _maxY];
    };

    _cache set [_objectiveId, _entry];
} forEach (keys FLO_Objectives);

_cache
