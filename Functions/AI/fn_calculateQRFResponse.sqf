/*
    Function: FLO_fnc_calculateQRFResponse
    
    Description:
    Calculates the appropriate QRF response tier and type based on threat level and aggression score.
    
    Parameters:
    _threatLevel - Threat level from 0 to 1 [Number]
    _aggrScore - Aggression score [Number]
    
    Returns:
    Array - [tier, type]
    - tier: "Tier1", "Tier2", "Tier3", or "Tier4"
    - type: "militia", "motorized", "mechanized", or "combined"
*/

params [
    ["_threatLevel", 0, [0]],
    ["_aggrScore", 0, [0]]
];

// Ensure threat level is between 0 and 1
_threatLevel = 0 max _threatLevel min 1;

private _timeMultiplier = if (sunOrMoon < 0.5) then { 0.7 } else { 1 }; // Reduced threat at night
private _adjustedThreat = _threatLevel * _timeMultiplier;

// Increase threat based on aggression score
_adjustedThreat = _adjustedThreat + (_aggrScore * 0.05); // Each aggression point adds 5% to threat

private _result = switch (true) do {
    case (_adjustedThreat > 0.9 || _aggrScore > 10): {
        ["Tier4", "combined"]
    };
    case (_adjustedThreat > 0.7 || _aggrScore > 7): {
        ["Tier3", "mechanized"]
    };
    case (_adjustedThreat > 0.4 || _aggrScore > 4): {
        ["Tier2", "motorized"]
    };
    default {
        ["Tier1", "militia"]
    };
};

_result 