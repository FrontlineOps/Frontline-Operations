/* Returns the recursively attached passenger IDs after validating reciprocity. */
params [
    ["_carrierGroupId", "", [""]],
    ["_ancestors", [], [[]]]
];

if (_carrierGroupId == "") then {
    throw "Transport manifest collection requires a carrier group ID";
};
if (_carrierGroupId in _ancestors) then {
    private _message = format ["Transport manifest cycle detected at carrier %1", _carrierGroupId];
    ["VIRTUALIZATION", 1, _message] call FLO_fnc_log;
    throw _message;
};

private _groups = call FLO_fnc_virtualizationGetGroupMap;
private _carrierData = _groups get _carrierGroupId;
if (isNil "_carrierData") then {
    private _message = format ["Transport manifest carrier %1 is missing", _carrierGroupId];
    ["VIRTUALIZATION", 1, _message] call FLO_fnc_log;
    throw _message;
};

private _passengerIds = +(_carrierData get "attachedGroups");
if ((count (_passengerIds arrayIntersect _passengerIds)) != count _passengerIds) then {
    private _message = format ["Transport manifest carrier %1 contains duplicate passenger IDs", _carrierGroupId];
    ["VIRTUALIZATION", 1, _message] call FLO_fnc_log;
    throw _message;
};

{
    private _candidateId = _x;
    private _candidateData = _y;
    if ((_candidateData get "attachedTo") == _carrierGroupId && {!(_candidateId in _passengerIds)}) then {
        private _message = format [
            "Transport manifest carrier %1 omits reciprocal passenger %2",
            _carrierGroupId,
            _candidateId
        ];
        ["VIRTUALIZATION", 1, _message] call FLO_fnc_log;
        throw _message;
    };
} forEach _groups;

private _manifest = [];
private _nextAncestors = _ancestors + [_carrierGroupId];
{
    private _passengerData = _groups get _x;
    if (isNil "_passengerData") then {
        private _message = format [
            "Transport manifest carrier %1 references missing passenger %2",
            _carrierGroupId,
            _x
        ];
        ["VIRTUALIZATION", 1, _message] call FLO_fnc_log;
        throw _message;
    };
    if ((_passengerData get "attachedTo") != _carrierGroupId) then {
        private _message = format [
            "Transport manifest carrier %1 passenger %2 points to %3",
            _carrierGroupId,
            _x,
            _passengerData get "attachedTo"
        ];
        ["VIRTUALIZATION", 1, _message] call FLO_fnc_log;
        throw _message;
    };

    _manifest pushBack _x;
    _manifest append ([_x, _nextAncestors] call FLO_fnc_virtualizationCollectTransportManifest);
} forEach _passengerIds;

_manifest
