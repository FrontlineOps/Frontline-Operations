

hint "Select Mission Type" ; 

CS_Action = [ player,
"<img size=2 color='#7CC2FF' image='\a3\Ui_f\data\Map\Markers\Military\warning_CA.paa'/><t color='#7CC2FF'>Mission : Rescue Crashed Pilot</t>",
'\a3\Ui_f\data\Map\Markers\Military\warning_CA.paa',
'\a3\Ui_f\data\Map\Markers\Military\warning_CA.paa',
'true',       
'true',  
{},
{},
{ [0] execVM "Scripts\Mission_Select.sqf" ; 

player removeAction CS_Action;
player removeAction MS_Action;
player removeAction SC_Action;
player removeAction BS_Action;


},
{},
[],
3,
9999999999,
false,
false
] call BIS_fnc_holdActionAdd; 

MS_Action = [ player,
"<img size=2 color='#7CC2FF' image='\a3\Ui_f\data\Map\Markers\Military\warning_CA.paa'/><t color='#7CC2FF'>Mission : Rescue Missing Squad</t>",
'\a3\Ui_f\data\Map\Markers\Military\warning_CA.paa',
'\a3\Ui_f\data\Map\Markers\Military\warning_CA.paa',
'true',       
'true',  
{},
{},
{ [1] execVM "Scripts\Mission_Select.sqf" ; 

player removeAction CS_Action;
player removeAction MS_Action;
player removeAction SC_Action;
player removeAction BS_Action;
},
{},
[],
3,
9999999999,
false,
false
] call BIS_fnc_holdActionAdd; 

SC_Action = [ player,
"<img size=2 color='#7CC2FF' image='\a3\Ui_f\data\Map\Markers\Military\warning_CA.paa'/><t color='#7CC2FF'>Mission : Intercept Support Convoy</t>",
'\a3\Ui_f\data\Map\Markers\Military\warning_CA.paa',
'\a3\Ui_f\data\Map\Markers\Military\warning_CA.paa',
'true',       
'true',  
{},
{},
{ [2] execVM "Scripts\Mission_Select.sqf" ; 

player removeAction CS_Action;
player removeAction MS_Action;
player removeAction SC_Action;
player removeAction BS_Action;
},
{},
[],
3,
9999999999,
false,
false
] call BIS_fnc_holdActionAdd; 

BS_Action = [ player,
"<img size=2 color='#7CC2FF' image='\a3\Ui_f\data\Map\Markers\Military\warning_CA.paa'/><t color='#7CC2FF'>Mission : Infiltrate Battle Ship</t>",
'\a3\Ui_f\data\Map\Markers\Military\warning_CA.paa',
'\a3\Ui_f\data\Map\Markers\Military\warning_CA.paa',
'true',       
'true',  
{},
{},
{ [3] execVM "Scripts\Mission_Select.sqf" ; 

player removeAction CS_Action;
player removeAction MS_Action;
player removeAction SC_Action;
player removeAction BS_Action;
},
{},
[],
3,
9999999999,
false,
false
] call BIS_fnc_holdActionAdd; 

















