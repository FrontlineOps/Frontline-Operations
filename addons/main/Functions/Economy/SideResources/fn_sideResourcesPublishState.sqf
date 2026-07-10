if (!isServer) exitWith { false };

private _snapshot = createHashMap;
{
    _snapshot set [_x, [_y] call FLO_fnc_sideResourcesGetSnapshot];
} forEach FLO_SideResources;

FLO_SideResourceState = _snapshot;
publicVariable "FLO_SideResourceState";
true
