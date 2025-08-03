private _bluFaction = FLO_FriendlyHandle get "name";

F_Init = false;
publicVariable "F_Init";

switch (_bluFaction) do {
	case "CUSTOM_PLAYER_FACTION": {call compileScript ["CUSTOM_PLAYER_FACTION.sqf"];};
	// case "NATO Forces _ Desert": {call compileScript ["Scripts\factions\blu_NATODesert.sqf"];};
	// case "NATO Forces _ Woodland": {call compileScript ["Scripts\factions\blu_NATOWood.sqf"];};
	// case "NATO Forces _ Desert _ Western Sahara": {call compileScript ["Scripts\factions\blu_WesternSahara.sqf"];};
	// case "United States Armed Forces _ Desert _ CUP + RHS";
	// case "United States Armed Forces _ Desert _ RHS": {call compileScript ["Scripts\factions\blu_US_Desert_CUP_RHS.sqf"];};
	// case "United States Armed Forces _ Woodland _ CUP + RHS";
	// case "United States Armed Forces _ Woodland _ RHS": {call compileScript ["Scripts\factions\blu_US_Wood_CUP_RHS.sqf"];};
	// case "German Armed Forces _ Desert _ BW": {call compileScript ["Scripts\factions\blu_GAF_Desert_BW.sqf"];};
	// case "German Armed Forces _ Woodland _ BW": {call compileScript ["Scripts\factions\blu_GAF_Wood_BW.sqf"];};
	// case "Spanish Armed Forces  _ Woodland _ FFAA": {call compileScript ["Scripts\factions\blu_SAF_Wood_FFAA.sqf"];};
	// case "British Armed Forces _ Desert _ AEW": {call compileScript ["Scripts\factions\blu_BAF_Desert_AEW.sqf"];};
	// case "British Armed Forces _ Woodland _ AEW": {call compileScript ["Scripts\factions\blu_BAF_Wood_AEW.sqf"];};
	// case "German Armed Forces _ Desert _ AEW": {call compileScript ["Scripts\factions\blu_GAF_Desert_AEW.sqf"];};
	// case "German Armed Forces _ Woodland _ AEW": {call compileScript ["Scripts\factions\blu_GAF_Wood_AEW.sqf"];};
	// case "Isreal Armed Forces _ Woodland _ AEW": {call compileScript ["Scripts\factions\blu_IAF_Desert_AEW.sqf"];};
	// case "Livonia Defence Forces _ Woodland _ AEW": {call compileScript ["Scripts\factions\blu_LDF_Wood_AEW.sqf"];};
	// case "United States Armed Forces _ Desert _ AEW": {call compileScript ["Scripts\factions\blu_US_Desert_AEW.sqf"];};
	// case "United States Armed Forces _ Woodland _ AEW": {call compileScript ["Scripts\factions\blu_US_Wood_AEW.sqf"];};
	// case "United States Armed Forces _ Woodland _ SOG Praire Fire": {call compileScript ["Scripts\factions\blu_US_PFSOG.sqf"];};
};
 
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
private _opfFaction = FLO_EnemyHandle get "name";

switch (_opfFaction) do {
	case "CUSTOM_ENEMY_FACTION": {call compileScript ["CUSTOM_ENEMY_FACTION.sqf"];};
	// case "CSAT Forces _ Desert";
	// case "Iran Armed Forces _ Desert _ AEW" : {call compileScript ["Scripts\factions\opf_CSATDesert.sqf"];};
	// case "CSAT Forces _ Woodland";
	// case "Chinese Armed Forces _ Woodland _ AEW" : {call compileScript ["Scripts\factions\opf_CSATWood.sqf"];};
	// case "Altis Armed Forces _ Woodland" : {call compileScript ["Scripts\factions\opf_AAF_Wood.sqf"];};
	// case "Livonia Defence Forces _ Woodland" : {call compileScript ["Scripts\factions\opf_LDF_Wood.sqf"];};
	// case "Sefrawi Freedom Forces _ Desert _ Western Sahara" : {call compileScript ["Scripts\factions\opf_SFF_Desert_WesternSahara.sqf"];};
	// case "Tura tribe insurgents _ Desert _ Western Sahara" : {call compileScript ["Scripts\factions\opf_TTI_Desert_WesternSahara.sqf.sqf"];};
	// case "Syndikat Insurgents _ Woodland" : {call compileScript ["Scripts\factions\opf_Syndikat_Wood.sqf"];};
	// case "North Vietnam _ Woodland _ SOG Praire Fire" : {call compileScript ["Scripts\factions\opf_NVA_PFSOG.sqf"];};
	// case "Afghan Insurgents _ CUP" : {call compileScript ["Scripts\factions\opf_AfghanIns_CUP.sqf"];};
	// case "Afghan Armed Forces _ CUP" : {call compileScript ["Scripts\factions\opf_AfghanAF_CUP.sqf"];};
	// case "African Insurgents _ POF" : {call compileScript ["Scripts\factions\opf_AfghanIns_POF.sqf"];};
	// case "Syrian Armed Forces _ POF" : {call compileScript ["Scripts\factions\opf_SyrianAF_POF.sqf"];};
	// case "ISIS Insurgents _ POF" : {call compileScript ["Scripts\factions\opf_ISIS_POF.sqf"];};
	// case "Iran Armed Forces _ POF" : {call compileScript ["Scripts\factions\opf_IranAF_POF.sqf"];};
	// case "East Europe Insurgents _ Desert _ AEW" : {call compileScript ["Scripts\factions\opf_EastEuropeIns_Desert_AEW.sqf"];};
	// case "East Europe Insurgents _ Woodland _ AEW" : {call compileScript ["Scripts\factions\opf_EastEuropeIns_Wood_AEW.sqf"];};
	// case "Russian Armed Forces _ Desert _ RHS" : {call compileScript ["Scripts\factions\opf_RussiaAF_Desert_RHS.sqf"];};
	// case "Russian Armed Forces _ Woodland _ RHS" : {call compileScript ["Scripts\factions\opf_RussiaAF_Wood_RHS.sqf"];};
};
 
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
private _civFaction = FLO_CivilianHandle get "name";

CivVehArray = [
"C_Truck_02_covered_F",
"C_Truck_02_transport_F",
"C_Truck_02_fuel_F",
"C_Van_02_vehicle_F",
"C_Van_02_service_F",
"C_Truck_02_box_F",
"C_Van_02_medevac_F",
"C_Van_01_fuel_F",
"C_Hatchback_01_sport_F",
"C_Hatchback_01_F",
"C_Offroad_01_F",
"C_Offroad_02_unarmed_F",
"C_Offroad_01_comms_F",
"C_Offroad_01_covered_F",
"C_Offroad_01_repair_F",
"C_Van_01_box_F",
"C_Van_01_transport_F",
"C_Tractor_01_F",
"C_SUV_01_F",
"C_Quadbike_01_F"
];

switch (_civFaction) do {
	case "CUSTOM_CIVILIAN_FACTION": {call compileScript ["CUSTOM_CIVILIAN_FACTION.sqf"];};
	// case "Vietnam_Civilians_Insurgents": {call compileScript ["Scripts\factions\civ_Vietnam.sqf"];};
	// case "Greek_Civilians_Insurgents": {call compileScript ["Scripts\factions\civ_Greek.sqf"];};
	// case "EastEurope_Civilians_Insurgents": {call compileScript ["Scripts\factions\civ_EastEurope.sqf"];};
	// case "EastEurope_Civilians_Insurgents_CUP": {call compileScript ["Scripts\factions\civ_EastEuropeCUP.sqf"];};
	// case "SefrouRamal_Civilians_Insurgents_Western Sahara": {call compileScript ["Scripts\factions\civ_WesternSahara.sqf"];};
	// case "Tanoan_Civilians_Insurgents": {call compileScript ["Scripts\factions\civ_Tanoa.sqf"];};
	// case "MiddleEast_Civilians_Insurgents_CUP": {call compileScript ["Scripts\factions\civ_MiddleEastCUP.sqf"];};
	// case "Asian_Civilians_Insurgents": {call compileScript ["Scripts\factions\civ_Asia.sqf"];};
};

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

F_Init = true;
publicVariable "F_Init";
