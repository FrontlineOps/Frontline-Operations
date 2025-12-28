/*
 * Function: FLO_fnc_aiCommanderConfig
 * Author: Frontline Operations Development Group
 * Description:
 * Returns the AI Commander configuration HashMap with all tunable parameters.
 * Centralizes magic numbers for easy adjustment and difficulty scaling.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Configuration HashMap <HASHMAP>
 *
 * Example:
 * private _config = call FLO_fnc_aiCommanderConfig;
 */

if (!isNil "FLO_AICommanderConfig") exitWith { FLO_AICommanderConfig };

FLO_AICommanderConfig = createHashMapFromArray [
    // ===========================================
    // TIMING CONFIGURATION
    // ===========================================
    ["updateInterval", 60],              // Main loop interval (seconds)
    ["strategyInterval", 300],           // Strategic reassessment interval (5 min)
    ["attackStageTime", 280],            // Time to wait at staging before attack
    ["defenseStageTime", 120],           // Time to wait at staging before defense
    ["attackTimeout", 1800],             // Max time for attack operation (30 min)
    ["defenseTimeout", 1200],            // Max time for defense operation (20 min)
    ["artilleryMissionExpiry", 600],     // Artillery mission tracking expiry (10 min)
    ["airMissionExpiry", 900],           // Air mission tracking expiry (15 min)
    ["prepFiresExpiry", 300],            // Preparatory fires expiry (5 min)
    ["groupCacheExpiry", 30],            // Military groups cache refresh (seconds)
    
    // ===========================================
    // FORCE LIMITS
    // ===========================================
    ["maxDefendingGroups", 6],           // Max groups defending simultaneously
    ["minGarrisonGroups", 2],            // Minimum groups that must stay in garrison
    ["minStagingForce", 2],              // Minimum groups before launching operation
    ["maxStagingForce", 4],              // Maximum groups per operation
    ["maxStagingForceMulti", 6],         // Max groups for multi-staging operations
    ["reserveRatio", 0.25],              // Fraction of forces kept in reserve
    ["maxAttackGroups", 16],             // Absolute cap on attacking groups
    
    // ===========================================
    // PLAYER SCALING
    // ===========================================
    ["minPlayersForAttack", 2],          // Minimum players before AI attacks
    ["playersPerAttackGroup", 2],        // Players needed per attack group
    ["aggressionGroupBonus", 4],         // Aggression score divisor for bonus groups
    
    // ===========================================
    // DISTANCE THRESHOLDS
    // ===========================================
    ["stagingArrivalRadius", 75],        // Distance to be considered "at staging"
    ["defenseStagingArrivalRadius", 50], // Tighter radius for defense staging
    ["attackReturnDistance", 800],       // Distance from enemy to return from attack
    ["defenseReturnDistance", 1000],     // Distance from enemy to return from defense
    ["stagingDistanceAttack", [500, 300]], // [base, variance] for attack staging
    ["stagingDistanceDefense", [300, 200]], // [base, variance] for defense staging
    ["concealmentSearchRadius", 150],    // Radius to search for concealment
    ["concealmentOffset", [20, 30]],     // [min, variance] distance from cover object
    ["garrisonWaypointRadius", 10],      // Waypoint completion radius for garrison
    ["threatDetectionRadius", 500],      // Radius to detect BLUFOR near objectives
    ["roamingGroupMinSize", 2],          // Min BLUFOR group size to track as threat
    
    // ===========================================
    // OPERATION PARAMETERS
    // ===========================================
    ["multiStagingThreshold", 2],        // Priority level to use multi-staging
    ["preparatoryFireRounds", 12],       // Rounds for preparatory artillery
    ["suppressiveFireRounds", 6],        // Rounds for suppressive fire
    ["counterBatteryRounds", 10],        // Rounds for counter-battery
    ["preparatoryFireTime", 180],        // Duration of prep fires (3 min)
    ["airPrepAltitude", 400],            // Altitude for preparatory air strikes
    ["casAltitude", 150],                // Altitude for CAS
    ["bombingAltitude", 300],            // Altitude for bombing runs
    ["capPatrolRadius", 2000],           // Radius for CAP patrol pattern
    
    // ===========================================
    // PRIORITY SCORING
    // ===========================================
    ["priorityScoreArmor", 100],         // Strategic reserve priority for armor
    ["priorityScoreMechanized", 80],     // Priority for mechanized
    ["priorityScoreMotorized", 60],      // Priority for motorized
    ["priorityScoreHelicopter", 90],     // Priority for helicopters
    ["priorityScoreJet", 95],            // Priority for jets
    ["priorityScoreInfantry", 40],       // Priority for infantry
    
    // Attack capability scoring
    ["attackCapabilityArmor", 1000],
    ["attackCapabilityMechanized", 800],
    ["attackCapabilityMotorized", 600],
    ["attackCapabilityInfantry", 400],
    
    // Defense capability scoring (fast response preferred)
    ["defenseCapabilityMotorized", 1000],
    ["defenseCapabilityMechanized", 900],
    ["defenseCapabilityArmor", 800],
    ["defenseCapabilityInfantry", 600],
    
    // Distance penalty divisors
    ["attackDistancePenaltyDivisor", 10], // 1 point per 10m for attacks
    ["defenseDistancePenaltyDivisor", 5], // 1 point per 5m for defense (need speed)
    
    // ===========================================
    // FORCE ACTIVATION
    // ===========================================
    ["forceActivateForOperations", true], // Force-spawn groups for staged operations
    ["forceActivateRadius", 50],          // Max spread when force-activating
    
    // ===========================================
    // DEBUG
    // ===========================================
    ["debugEnabled", false],             // Enable debug markers and logging
    ["debugMarkerUpdateInterval", 30],   // Debug marker refresh rate

    // ===========================================
    // GTN (Goal Task Network) CONFIGURATION
    // ===========================================
    ["gtnEnabled", true],                // Enable GTN goal-driven planning (vs reactive)
    ["gtnUpdateInterval", 5],            // GTN update cycle interval (seconds)
    ["gtnReplanInterval", 60],           // Minimum time between replans (seconds)
    ["gtnCasualtyThreshold", 0.2],       // Force loss ratio to trigger replan (0-1)
    ["gtnAggressiveness", 0.5],          // Offensive vs defensive posture (0-1)
    ["gtnRiskTolerance", 0.5],           // Willingness to attack with lower ratios (0-1)
    ["gtnDebugMode", false]              // Enable verbose GTN logging
];

["AI Commander", 3, "Configuration loaded"] call FLO_fnc_log;

FLO_AICommanderConfig

