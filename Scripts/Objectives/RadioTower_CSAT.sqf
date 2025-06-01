private _thisRadioTrigger = _this select 0;
private _AGGRSCORE = FLO_DifficultyHandle get "value";

private _mineTypes = ["APERSMine", "APERSBoundingMine"];
private _minePos = getPos _thisRadioTrigger;

for "_i" from 1 to 6 do {
    private _mineType = selectRandom _mineTypes;
    createMine [_mineType, _minePos, [], random 40];
};

private _Position = nearestObjects [(getPos _thisRadioTrigger), ["Land_TTowerBig_2_F", "Land_TTowerBig_1_F", "Land_Communication_F"], 50] select 0;  
private _poss = getPos _Position;