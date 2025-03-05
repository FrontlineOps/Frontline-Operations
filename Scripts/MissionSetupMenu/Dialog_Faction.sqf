disableSerialization;

(findDisplay 46) createDisplay "factionselect_dialog2";
waituntil {!isNull findDisplay 999};

///////////////////////////////////////////////////////////////////////////////////////////////////

_playerbox = findDisplay 999 displayCtrl 1955;
_enemybox = findDisplay 999 displayCtrl 1956;
_civilianbox = findDisplay 999 displayCtrl 1957;

_randombutton = findDisplay 999 displayCtrl 1600;

//////////////////////////////////////////////////////////////////////////////////////////////////

populateFactionBoxF = {

	_ctrl = findDisplay 999 displayCtrl _this;
	
	_ctrl lbAdd "CUSTOM_PLAYER_FACTION"; 
	
	if (!isClass (configfile >> "CfgFactionClasses" >> "Atlas_BLU_G_F") == true ) then {_ctrl lbAdd "NATO Forces _ Desert"; };  
	if (isClass (configfile >> "CfgFactionClasses" >> "BLU_NATO_lxWS") == true ) then {_ctrl lbAdd "NATO Forces _ Desert _ Western Sahara"; };  
	if (!isClass (configfile >> "CfgFactionClasses" >> "Atlas_BLU_G_F") == true ) then {_ctrl lbAdd "NATO Forces _ Woodland"; }; 
	
	if (isClass (configfile >> "CfgFactionClasses" >> "Marine_BLU_USMC_F") == true ) then {_ctrl lbAdd "United States Armed Forces _ Desert _ AEW"; }; 
	if (isClass (configfile >> "CfgFactionClasses" >> "Marine_BLU_USMC_F") == true ) then {_ctrl lbAdd "United States Armed Forces _ Woodland _ AEW"; }; 
	if (isClass (configfile >> "CfgFactionClasses" >> "Atlas_BLU_G_F") == true ) then {_ctrl lbAdd "British Armed Forces _ Desert _ AEW"; }; 
	if (isClass (configfile >> "CfgFactionClasses" >> "Atlas_BLU_G_F") == true ) then {_ctrl lbAdd "British Armed Forces _ Woodland _ AEW"; }; 
	if (isClass (configfile >> "CfgFactionClasses" >> "Atlas_BLU_G_F") == true ) then {_ctrl lbAdd "German Armed Forces _ Woodland _ AEW"; }; 		
	if (isClass (configfile >> "CfgFactionClasses" >> "Atlas_BLU_G_F") == true ) then {_ctrl lbAdd "Isreal Armed Forces _ Woodland _ AEW"; }; 
	if (isClass (configfile >> "CfgFactionClasses" >> "Atlas_BLU_G_F") == true ) then {_ctrl lbAdd "Livonia Defence Forces _ Woodland _ AEW"; }; 		
	
	if (isClass (configfile >> "CfgFactionClasses" >> "rhs_faction_usmc_wd") == true ) then {_ctrl lbAdd "United States Armed Forces _ Desert _ RHS";};
	if (isClass (configfile >> "CfgFactionClasses" >> "rhs_faction_usmc_wd") == true ) then {_ctrl lbAdd "United States Armed Forces _ Woodland _ RHS";}; 	
	if (isClass (configfile >> "CfgFactionClasses" >> "B_MACV") == true ) then {_ctrl lbAdd "United States Armed Forces _ Woodland _ SOG Praire Fire";}; 	
	if (isClass (configfile >> "CfgFactionClasses" >> "CUP_B_US_Army") == true ) then {_ctrl lbAdd "British Armed Forces _ Desert _ CUP";};
	if (isClass (configfile >> "CfgFactionClasses" >> "CUP_B_US_Army") == true ) then {_ctrl lbAdd "British Armed Forces _ Woodland _ CUP"; };
	if ((isClass (configfile >> "CfgFactionClasses" >> "BWA3_Faction_Fleck") == true ) && (isClass (configfile >> "CfgFactionClasses" >> "CUP_B_GER") == true )) then {_ctrl lbAdd "German Armed Forces _ Desert _ BW"; }; 
	if ((isClass (configfile >> "CfgFactionClasses" >> "BWA3_Faction_Fleck") == true ) && (isClass (configfile >> "CfgFactionClasses" >> "CUP_B_GER") == true )) then {_ctrl lbAdd "German Armed Forces _ Woodland _ BW"; };
	if (isClass (configfile >> "CfgFactionClasses" >> "FFAA") == true ) then {_ctrl lbAdd "Spanish Armed Forces  _ Woodland _ FFAA"; }; 
	_ctrl lbSetCurSel 0;
};

populateFactionBoxE = {

	_ctrl = findDisplay 999 displayCtrl _this;
	
	_ctrl lbAdd "CUSTOM_ENEMY_FACTION"; 
	
	if (!isClass (configfile >> "CfgFactionClasses" >> "Atlas_BLU_G_F") == true ) then {_ctrl lbAdd "CSAT Forces _ Desert"; }else{_ctrl lbAdd "Iran Armed Forces _ Desert _ AEW"; }; 
	if (!isClass (configfile >> "CfgFactionClasses" >> "Atlas_BLU_G_F") == true ) then {_ctrl lbAdd "CSAT Forces _ Woodland"; }else{_ctrl lbAdd "Chinese Armed Forces _ Woodland _ AEW"; }; 
   
    _ctrl lbAdd "Altis Armed Forces _ Woodland"; 
    _ctrl lbAdd "Livonia Defence Forces _ Woodland";  
	
	if (isClass (configfile >> "CfgFactionClasses" >> "OPF_SFIA_lxWS") == true ) then {_ctrl lbAdd "Sefrawi Freedom Forces _ Desert _ Western Sahara"; }; 	
	if (isClass (configfile >> "CfgFactionClasses" >> "OPF_TURA_lxWS") == true ) then {_ctrl lbAdd "Tura tribe insurgents _ Desert _ Western Sahara"; };
	if (isClass (configfile >> "CfgFactionClasses" >> "O_PAVN") == true ) then {_ctrl lbAdd "North Vietnam _ Woodland _ SOG Praire Fire"; };
    _ctrl lbAdd "Syndikat Insurgents _ Woodland";  

	if (isClass (configfile >> "CfgFactionClasses" >> "CUP_B_US_Army") == true ) then {_ctrl lbAdd "Afghan Insurgents _ CUP";};
	if (isClass (configfile >> "CfgFactionClasses" >> "CUP_B_US_Army") == true ) then {_ctrl lbAdd "Afghan Armed Forces _ CUP"; };

	if (isClass (configfile >> "CfgFactionClasses" >> "LOP_IRAN") == true ) then {_ctrl lbAdd "African Insurgents _ POF";};
	if (isClass (configfile >> "CfgFactionClasses" >> "LOP_IRAN") == true ) then {_ctrl lbAdd "Syrian Armed Forces _ POF"; };
	if (isClass (configfile >> "CfgFactionClasses" >> "LOP_IRAN") == true ) then {_ctrl lbAdd "ISIS Insurgents _ POF";};
	if (isClass (configfile >> "CfgFactionClasses" >> "LOP_IRAN") == true ) then {_ctrl lbAdd "Iran Armed Forces _ POF"; };

	if (isClass (configfile >> "CfgFactionClasses" >> "Opf_OPF_S_F") == true ) then {_ctrl lbAdd "East Europe Insurgents _ Desert _ AEW"; }; 
	if (isClass (configfile >> "CfgFactionClasses" >> "Opf_OPF_S_F") == true ) then {_ctrl lbAdd "East Europe Insurgents _ Woodland _ AEW"; }; 
	
	if (isClass (configfile >> "CfgFactionClasses" >> "rhs_faction_msv") == true ) then {_ctrl lbAdd "Russian Armed Forces _ Desert _ RHS";};
	if (isClass (configfile >> "CfgFactionClasses" >> "rhs_faction_msv") == true ) then {	_ctrl lbAdd "Russian Armed Forces _ Woodland _ RHS";};
	_ctrl lbSetCurSel 0;

};

populateFactionBoxC = {

	_ctrl = findDisplay 999 displayCtrl _this;

	_ctrl lbAdd "CUSTOM_CIVILIAN_FACTION"; 
	
    _ctrl lbAdd "Greek_Civilians_Insurgents"; 
    _ctrl lbAdd "EastEurope_Civilians_Insurgents";  
		if (isClass (configfile >> "CfgFactionClasses" >> "OPF_TURA_lxWS") == true ) then {_ctrl lbAdd "SefrouRamal_Civilians_Insurgents_Western Sahara";};
		if (isClass (configfile >> "CfgFactionClasses" >> "I_LAO") == true ) then {_ctrl lbAdd "Vietnam_Civilians_Insurgents";};
		if (isClass (configfile >> "CfgFactionClasses" >> "CUP_C_CHERNARUS") == true ) then {_ctrl lbAdd "EastEurope_Civilians_Insurgents_CUP";};
    _ctrl lbAdd "Tanoan_Civilians_Insurgents";  
		if (isClass (configfile >> "CfgFactionClasses" >> "CUP_C_TK") == true ) then {_ctrl lbAdd "MiddleEast_Civilians_Insurgents_CUP";};
    _ctrl lbAdd "Asian_Civilians_Insurgents";  
	_ctrl lbSetCurSel 0;

};

populateFactionBoxEP = {
	_ctrl = findDisplay 999 displayCtrl _this;

    _ctrl lbAdd "10% _ Small Operation";  
    _ctrl lbAdd "30% _ Short Campaign";
    _ctrl lbAdd "50% _ Medium Campaign";  
    _ctrl lbAdd "75% _ Long Campaign";  
    _ctrl lbAdd "100% _ Dedi Servers with HCs";  
	_ctrl lbSetCurSel 4;
};

populateFactionBoxSR = {
	_ctrl = findDisplay 999 displayCtrl _this;

    _ctrl lbAdd "50"; 
    _ctrl lbAdd "250";  
    _ctrl lbAdd "500";
	_ctrl lbAdd "1000";
	_ctrl lbSetCurSel 1;
};

populateFactionBoxSRep = {
	_ctrl = findDisplay 999 displayCtrl _this;

    _ctrl lbAdd "LOW_Enemy to Guerillas"; 
    _ctrl lbAdd "MEDIUM_Neutral to Guerillas";  
    _ctrl lbAdd "HIGH_Friendly to Guerillas";
	_ctrl lbSetCurSel 1;
};

populateFactionBoxSD = {
	_ctrl = findDisplay 999 displayCtrl _this;

    _ctrl lbAdd "EASY _ Low Enemy Presence _ progressive"; 
    _ctrl lbAdd "NORMAL _ Half Enemy Presence _ progressive";  
    _ctrl lbAdd "HARD _ Full Enemy Presence _ progressive";
	_ctrl lbSetCurSel 1;
};


{ _x call populateFactionBoxF } forEach [1955]; 

{ _x call populateFactionBoxE } forEach [1956]; 

{ _x call populateFactionBoxC } forEach [1957]; 

{ _x call populateFactionBoxEP } forEach [1958]; 

{ _x call populateFactionBoxSR } forEach [1959]; 

{ _x call populateFactionBoxSRep } forEach [1960]; 

{ _x call populateFactionBoxSD } forEach [1961]; 
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////






