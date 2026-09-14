/* Logistics publishes the next replacement batch before other systems fund work. */
params ["_net", "_currentComposition"];
private _initialComposition = _net get "_initialComposition";
private _neededCounts = createHashMap;
private _neededTotal = 0;
{
    private _missing = _y - (_currentComposition getOrDefault [_x, 0]);
    if (_missing > 0) then {
        _neededCounts set [_x, _missing];
        _neededTotal = _neededTotal + _missing;
    };
} forEach _initialComposition;

private _costs = _net get "GROUP_COSTS";
private _slots = _net get "REPLACEMENT_DISPATCH_BATCH_SIZE";
private _fundingNeed = 0;
{
    private _count = (_neededCounts getOrDefault [_x, 0]) min _slots;
    _fundingNeed = _fundingNeed + _count * (_costs get _x);
    _slots = _slots - _count;
    if (_slots == 0) exitWith {};
} forEach (_net get "REPLACEMENT_PRIORITY_ORDER");
(FLO_SideResources get (_net get "_managedSideKey")) set ["_replacementFundingNeed", _fundingNeed];
[_neededCounts, _neededTotal]
