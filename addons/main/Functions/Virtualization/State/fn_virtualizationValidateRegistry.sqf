/*
 * Function: FLO_fnc_virtualizationValidateRegistry
 * Description:
 *   Validates cross-record ownership and transport relationships.
 */

private _groups = call FLO_fnc_virtualizationGetGroupMap;
private _realGroups = createHashMap;
private _spatial = call FLO_fnc_virtualizationGetSpatialState;
private _spatialGrid = _spatial get "grid";
private _spatialGridBySide = _spatial get "gridBySide";
private _spatialMeta = _spatial get "groupMeta";

if ((count _spatialMeta) != (count _groups)) then {
    throw format [
        "Virtual registry/spatial count mismatch: groups=%1 metadata=%2",
        count _groups,
        count _spatialMeta
    ];
};

{
    private _groupId = _x;
    private _groupData = _y;
    [_groupData, _groupId] call FLO_fnc_virtualizationValidateGroup;

    if (_groupData get "isActive") then {
        private _realGroupKey = str (_groupData get "realGroup");
        if (_realGroupKey in _realGroups) then {
            throw format [
                "Virtual groups %1 and %2 share real group %3",
                _realGroups get _realGroupKey,
                _groupId,
                _realGroupKey
            ];
        };
        _realGroups set [_realGroupKey, _groupId];
    };

    private _attachedTo = _groupData get "attachedTo";
    if (_attachedTo != "") then {
        private _carrier = _groups get _attachedTo;
        if (isNil "_carrier") then {
            throw format ["Virtual group %1 references missing carrier %2", _groupId, _attachedTo];
        };
        if ((_carrier get "side") != (_groupData get "side")) then {
            throw format ["Virtual group %1 and carrier %2 have different sides", _groupId, _attachedTo];
        };
        if !(_groupId in (_carrier get "attachedGroups")) then {
            throw format ["Carrier %1 does not reciprocate passenger %2", _attachedTo, _groupId];
        };
        if ([_attachedTo, _groupId] call FLO_fnc_virtualizationTransportChainContains) then {
            throw format ["Transport relationship for %1 through %2 is cyclic", _groupId, _attachedTo];
        };
    };

    {
        private _passenger = _groups get _x;
        if (isNil "_passenger") then {
            throw format ["Carrier %1 references missing passenger %2", _groupId, _x];
        };
        if ((_passenger get "attachedTo") != _groupId) then {
            throw format ["Passenger %1 does not reciprocate carrier %2", _x, _groupId];
        };
    } forEach (_groupData get "attachedGroups");

    private _mountedIn = _groupData get "mountedIn";
    if (_mountedIn != "" && {_mountedIn != _attachedTo}) then {
        throw format [
            "Virtual group %1 mountedIn=%2 differs from attachedTo=%3",
            _groupId,
            _mountedIn,
            _attachedTo
        ];
    };

    private _organicParent = _groupData get "organicPackageParentGroupId";
    if (_organicParent != "" && {!(_organicParent in _groups)}) then {
        throw format ["Virtual group %1 references missing organic parent %2", _groupId, _organicParent];
    };

    private _engagementTarget = _groupData get "engagementTargetGroupId";
    if (_engagementTarget == _groupId) then {
        throw format ["Virtual group %1 targets itself for engagement", _groupId];
    };
    if (_engagementTarget != "" && {!(_engagementTarget in _groups)}) then {
        throw format ["Virtual group %1 references missing engagement target %2", _groupId, _engagementTarget];
    };

    private _meta = _spatialMeta get _groupId;
    if (isNil "_meta") then {
        throw format ["Virtual group %1 is missing spatial metadata", _groupId];
    };
    private _expectedCellKey = [_groupData get "position"] call FLO_fnc_virtualizationSpatialGetCellKey;
    private _expectedSideKey = [_groupData get "side"] call FLO_fnc_virtualizationSpatialGetSideKey;
    if (_meta isNotEqualTo [_expectedCellKey, _expectedSideKey]) then {
        throw format [
            "Virtual group %1 spatial metadata mismatch: actual=%2 expected=%3",
            _groupId,
            _meta,
            [_expectedCellKey, _expectedSideKey]
        ];
    };

    private _cell = _spatialGrid get _expectedCellKey;
    if (isNil "_cell" || {!(_groupId in _cell)}) then {
        throw format ["Virtual group %1 is absent from spatial cell %2", _groupId, _expectedCellKey];
    };
    private _sideGrid = _spatialGridBySide get _expectedSideKey;
    private _sideCell = _sideGrid get _expectedCellKey;
    if (isNil "_sideCell" || {!(_groupId in _sideCell)}) then {
        throw format [
            "Virtual group %1 is absent from %2 spatial cell %3",
            _groupId,
            _expectedSideKey,
            _expectedCellKey
        ];
    };
} forEach _groups;

true
