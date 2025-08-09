
#define true 1
#define false 0

#define GUI_GRID_H	(safezoneH * 1.2)
#define GUI_GRID_W	(GUI_GRID_H * 3/4)
#define GUI_GRID_X	(safezoneX + (safezoneW - GUI_GRID_W) / 2 + (GUI_GRID_W * 96.5 / 2048))
#define GUI_GRID_Y	(safezoneY + (safezoneH - GUI_GRID_H) / 2)
#define MENU_sizeEx pxToScreen_H(cTab_GUI_tablet_OSD_TEXT_STD_SIZE)

#define cTab_GUI_tablet_MAP_X (257)
#define cTab_GUI_tablet_MAP_Y (491)
#define cTab_GUI_tablet_MAP_W (1341)
#define cTab_GUI_tablet_MAP_H (993)

#define cTab_GUI_tablet_SCREEN_CONTENT_X (cTab_GUI_tablet_MAP_X)
#define cTab_GUI_tablet_SCREEN_CONTENT_Y (cTab_GUI_tablet_MAP_Y + cTab_GUI_tablet_OSD_HEADER_H)
#define cTab_GUI_tablet_SCREEN_CONTENT_W (cTab_GUI_tablet_MAP_W)
#define cTab_GUI_tablet_SCREEN_CONTENT_H (cTab_GUI_tablet_MAP_H - cTab_GUI_tablet_OSD_HEADER_H - cTab_GUI_tablet_OSD_FOOTER_H)


class C_LOCK
{
          idd=732801;

           movingEnable = false;
           enableSimulation = true;
		   fadein= 0;
           duration = le+011;
           fadeout=0;
           onload = "hint parseText ""<t color='#7CC2FF' font='PuristaBold' align = 'right' size='2'> (+) +1 Hour </t><br /><t color='#7CC2FF' font='PuristaBold' align = 'right' size='2'> (-) -1 Hour</t><br /><t color='#7CC2FF' font='PuristaBold' align = 'right' size='2'> (T) Skip Time</t>"" ; StatusInfo = false ; titleFadeOut 0.01 ; PHOUR = 0 ; [ format['<t color='#0188FE' size='4.8' font='PuristaBold' shadow='0'>%1:00</t>', PHOUR],-0.03,0.38,9999,0,0,7537] spawn BIS_fnc_dynamicText; ";
		   onUnload = "hint '' ; [ format['', PHOUR],0.2,0,9999,0,0,7537] spawn BIS_fnc_dynamicText; ";
		   controlsBackground[] = {};
           controls[] = {
			   btnF1,
			   btnF2,
			   btnF3
			   		   };		

 objects[] = {};
 

			class btnF1: cTab_RscButton
		{
			idc = 346353454325778952;
			tooltip = "+ 1 Hour (+)";
			action = "execVM 'Scripts\HUP.sqf';";
    colorText[] = {1,1,1,0};
	colorDisabled[] = {1,1,1,0};
	colorBackground[] = {0,0,0,0};
	colorBackgroundDisabled[] = {0,0,0,0};
	colorBackgroundActive[] = {0,0,0,0};
	colorFocused[] = {0,0,0,0};
	colorShadow[] = {0,0,0,0};
	colorBorder[] = {0,0,0,0};
	shortcuts[] = {"13"};
	x = 0.69;
	y = 0.48;
    w = 0.04;
	h = 0.05;
		};
		
    		class btnF2: cTab_RscButton
		{
			idc = 34632574566385352;
			tooltip = "- 1 Hour (-)";
			action = "execVM 'Scripts\HDN.sqf';";
    colorText[] = {1,1,1,0};
	colorDisabled[] = {1,1,1,0};
	colorBackground[] = {0,0,0,0};
	colorBackgroundDisabled[] = {0,0,0,0};
	colorBackgroundActive[] = {0,0,0,0};
	colorFocused[] = {0,0,0,0};
	colorShadow[] = {0,0,0,0};
	colorBorder[] = {0,0,0,0};
	shortcuts[] = {"12"};
	x = 0.69;
	y = 0.55;
    w = 0.04;
	h = 0.05;
		};	

    		class btnF3: cTab_RscButton
		{
			idc = 34632574566385352;
			tooltip = "Skip Time (T)";
			action = "execVM 'Scripts\HGO.sqf';";
    colorText[] = {1,1,1,0};
	colorDisabled[] = {1,1,1,0};
	colorBackground[] = {0,0,0,0};
	colorBackgroundDisabled[] = {0,0,0,0};
	colorBackgroundActive[] = {0,0,0,0};
	colorFocused[] = {0,0,0,0};
	colorShadow[] = {0,0,0,0};
	colorBorder[] = {0,0,0,0};
	shortcuts[] = {"20"};
	x = 0.69;
	y = 0.62;
    w = 0.04;
	h = 0.05;
		};	

}; 

class Satellite_Control_Tablet
{
          idd=7801;

           movingEnable = false;
           enableSimulation = true;
		   fadein= 0;
           duration = le+011;
           fadeout=0;
           onload = "titleFadeOut 0.01;";
           onUnload = "titleRsc ['intro','PLAIN'];";
		   controlsBackground[] = {};
           controls[] = {
			   RscBack,
			   RscDesktop,
			   RscTablet,
			   btnF1,
			   btnF2,
			   btnF3,
			   btnF4,
			   btnF5,
			   btnF6,
			   btnFEED,
			   btnSAT,
			   btnF,
			   btn0,
			   btnNVG,
			   btnTHR,
			   btnP
			   		   };		  

 objects[] = {};
 

   class RscTablet: cTab_RscPicture
   {
          idc = 727826312975957;
		  colorBackground[] = {0,0,0,1};
          colorText[] = {1,1,1,1};
          text = "Screens\FOBA\SAT_DLG.paa";
         x = GUI_GRID_X;
         y = GUI_GRID_Y;
         w = GUI_GRID_W;
         h = GUI_GRID_H;
   };
   	class RscBack: cTab_RscPicture
		{
          idc = 482452837272;
		  colorBackground[] = {0,0,0,1};
          colorText[] = {1,1,1,1};
           text="Screens\FOBA\BACK.paa";
         x = GUI_GRID_X;
         y = GUI_GRID_Y;
         w = GUI_GRID_W;
         h = GUI_GRID_H;
		};   
 	class RscDesktop: cTab_RscPicture
		{
          idc = 4827272;
		  colorBackground[] = {0,0,0,1};
          colorText[] = {1,1,1,1};
           text="#(argb,512,512,1)r2t(HCAM_S,1)";
         x = safeZoneX + 0.25 * safeZoneW;
         y = safeZoneY + 0.21 * safeZoneH;
         w = safeZoneW * 0.5;
         h = safeZoneH * 0.53;
		};   

    		
			class btnF1: cTab_RscButton
		{
			idc = 34635325778952;
			tooltip = "Zoom 0x _ Hotkey (F1)";
			action = "HCAM_0 camSetFov 0.9;";
    colorText[] = {1,1,1,0};
	colorDisabled[] = {1,1,1,0};
	colorBackground[] = {0,0,0,0};
	colorBackgroundDisabled[] = {0,0,0,0};
	colorBackgroundActive[] = {0,0,0,0};
	colorFocused[] = {0,0,0,0};
	colorShadow[] = {0,0,0,0};
	colorBorder[] = {0,0,0,0};
	shortcuts[] = {"59"};
	x = 0.07;
	y = 1.057;
    w = 0.04;
	h = 0.05;
		};
		
    		class btnF2: cTab_RscButton
		{
			idc = 346325785352;
			tooltip = "Zoom 1x _ Hotkey (F2)";
			action = "HCAM_0 camSetFov 0.7;";
    colorText[] = {1,1,1,0};
	colorDisabled[] = {1,1,1,0};
	colorBackground[] = {0,0,0,0};
	colorBackgroundDisabled[] = {0,0,0,0};
	colorBackgroundActive[] = {0,0,0,0};
	colorFocused[] = {0,0,0,0};
	colorShadow[] = {0,0,0,0};
	colorBorder[] = {0,0,0,0};
	shortcuts[] = {"60"};
	x = 0.12;
	y = 1.057;
    w = 0.04;
	h = 0.05;
		};	

    		class btnF3: cTab_RscButton
		{
			idc = 346351478293352;
			tooltip = "Zoom 2x _ Hotkey (F3)";
			action = "HCAM_0 camSetFov 0.5;";
    colorText[] = {1,1,1,0};
	colorDisabled[] = {1,1,1,0};
	colorBackground[] = {0,0,0,0};
	colorBackgroundDisabled[] = {0,0,0,0};
	colorBackgroundActive[] = {0,0,0,0};
	colorFocused[] = {0,0,0,0};
	colorShadow[] = {0,0,0,0};
	colorBorder[] = {0,0,0,0};
	shortcuts[] = {"61"};
	x = 0.17;
	y = 1.057;
    w = 0.04;
	h = 0.05;
		};	  
		
    		class btnF4: cTab_RscButton
		{
			idc = 346385695352;
			tooltip = "Zoom 3x _ Hotkey (F4)";
			action = "HCAM_0 camSetFov 0.3;";
    colorText[] = {1,1,1,0};
	colorDisabled[] = {1,1,1,0};
	colorBackground[] = {0,0,0,0};
	colorBackgroundDisabled[] = {0,0,0,0};
	colorBackgroundActive[] = {0,0,0,0};
	colorFocused[] = {0,0,0,0};
	colorShadow[] = {0,0,0,0};
	colorBorder[] = {0,0,0,0};
	shortcuts[] = {"62"};
	x = 0.23;
	y = 1.057;
    w = 0.04;
	h = 0.05;
		};	  
		
    		class btnF5: cTab_RscButton
		{
			idc = 34774635352;
			tooltip = "Zoom 4x _ Hotkey (F5)";
			action = "HCAM_0 camSetFov 0.2;";
    colorText[] = {1,1,1,0};
	colorDisabled[] = {1,1,1,0};
	colorBackground[] = {0,0,0,0};
	colorBackgroundDisabled[] = {0,0,0,0};
	colorBackgroundActive[] = {0,0,0,0};
	colorFocused[] = {0,0,0,0};
	colorShadow[] = {0,0,0,0};
	colorBorder[] = {0,0,0,0};
	shortcuts[] = {"63"};
	x = 0.28;
	y = 1.057;
    w = 0.04;
	h = 0.05;
		};	

    		class btnF6: cTab_RscButton
		{
			idc = 34774635352;
			tooltip = "Zoom 5x _ Hotkey (F6)";
			action = "HCAM_0 camSetFov 0.1;";
    colorText[] = {1,1,1,0};
	colorDisabled[] = {1,1,1,0};
	colorBackground[] = {0,0,0,0};
	colorBackgroundDisabled[] = {0,0,0,0};
	colorBackgroundActive[] = {0,0,0,0};
	colorFocused[] = {0,0,0,0};
	colorShadow[] = {0,0,0,0};
	colorBorder[] = {0,0,0,0};
	shortcuts[] = {"64"};
	x = 0.33;
	y = 1.057;
    w = 0.04;
	h = 0.05;
		};	  		

	    	class btnFEED: cTab_RscButton
		{
			idc = 34776584635352;
			tooltip = "Squad Live Feed _ Hotkey (L)";
			action = "execVM 'Scripts\SATHC.sqf';";
    colorText[] = {1,1,1,0};
	colorDisabled[] = {1,1,1,0};
	colorBackground[] = {0,0,0,0};
	colorBackgroundDisabled[] = {0,0,0,0};
	colorBackgroundActive[] = {0,0,0,0};
	colorFocused[] = {0,0,0,0};
	colorShadow[] = {0,0,0,0};
	colorBorder[] = {0,0,0,0};
	shortcuts[] = {"38"};
	x = 0.39;
	y = 1.057;
    w = 0.05;
	h = 0.06;
		};	 	
		
		
			    		class btnSAT: cTab_RscButton
		{
			idc = 3477463453255352;
			tooltip = "SATCOM Link _ Hotkey (S)";
			action = "execVM 'Scripts\SATSS.sqf';";
    colorText[] = {1,1,1,0};
	colorDisabled[] = {1,1,1,0};
	colorBackground[] = {0,0,0,0};
	colorBackgroundDisabled[] = {0,0,0,0};
	colorBackgroundActive[] = {0,0,0,0};
	colorFocused[] = {0,0,0,0};
	colorShadow[] = {0,0,0,0};
	colorBorder[] = {0,0,0,0};
	shortcuts[] = {"31"};
	x = 0.465;
	y = 1.057;
    w = 0.05;
	h = 0.06;
		};	 	
		
	    		class btnF: cTab_RscButton
		{
			idc = 34774635352;
			tooltip = "Satellite Position _ Hotkey (F)";
			action = "execVM 'Scripts\SATMT.sqf';";
    colorText[] = {1,1,1,0};
	colorDisabled[] = {1,1,1,0};
	colorBackground[] = {0,0,0,0};
	colorBackgroundDisabled[] = {0,0,0,0};
	colorBackgroundActive[] = {0,0,0,0};
	colorFocused[] = {0,0,0,0};
	colorShadow[] = {0,0,0,0};
	colorBorder[] = {0,0,0,0};
	shortcuts[] = {"33"};
	x = 0.535;
	y = 1.057;
    w = 0.04;
	h = 0.05;
		};	 	
    		class btn0: cTab_RscButton
		{
			idc = 34774635352;
			tooltip = "Normal Optics _ Hotkey (+)";
			action = "'HCAM_S' setPiPEffect [0];";
    colorText[] = {1,1,1,0};
	colorDisabled[] = {1,1,1,0};
	colorBackground[] = {0,0,0,0};
	colorBackgroundDisabled[] = {0,0,0,0};
	colorBackgroundActive[] = {0,0,0,0};
	colorFocused[] = {0,0,0,0};
	colorShadow[] = {0,0,0,0};
	colorBorder[] = {0,0,0,0};
	shortcuts[] = {"13"};
	x = 0.583;
	y = 1.057;
    w = 0.04;
	h = 0.05;
		};	 	
    		class btnNVG: cTab_RscButton
		{
			idc = 34774635352;
			tooltip = "Night Vision Optics _ Hotkey (-)";
			action = "'HCAM_S' setPiPEffect [1];";
    colorText[] = {1,1,1,0};
	colorDisabled[] = {1,1,1,0};
	colorBackground[] = {0,0,0,0};
	colorBackgroundDisabled[] = {0,0,0,0};
	colorBackgroundActive[] = {0,0,0,0};
	colorFocused[] = {0,0,0,0};
	colorShadow[] = {0,0,0,0};
	colorBorder[] = {0,0,0,0};
	shortcuts[] = {"12"};
	x = 0.639;
	y = 1.057;
    w = 0.04;
	h = 0.05;
		};	 	
    		class btnTHR: cTab_RscButton
		{
			idc = 34774635352;
			tooltip = "Thermal Optics 2 _ Hotkey (T)";
			action = "'HCAM_S' setPiPEffect [2];";
    colorText[] = {1,1,1,0};
	colorDisabled[] = {1,1,1,0};
	colorBackground[] = {0,0,0,0};
	colorBackgroundDisabled[] = {0,0,0,0};
	colorBackgroundActive[] = {0,0,0,0};
	colorFocused[] = {0,0,0,0};
	colorShadow[] = {0,0,0,0};
	colorBorder[] = {0,0,0,0};
	shortcuts[] = {"20"};
	x = 0.685;
	y = 1.057;
    w = 0.04;
	h = 0.05;
		};	 	
	   		class btnP: cTab_RscButton
		{
			idc = 34774635352;
			tooltip = "Satellite Tracking _ Hotkey (P)";
			action = "execVM 'Scripts\SATLP.sqf';";
    colorText[] = {1,1,1,0};
	colorDisabled[] = {1,1,1,0};
	colorBackground[] = {0,0,0,0};
	colorBackgroundDisabled[] = {0,0,0,0};
	colorBackgroundActive[] = {0,0,0,0};
	colorFocused[] = {0,0,0,0};
	colorShadow[] = {0,0,0,0};
	colorBorder[] = {0,0,0,0};
	shortcuts[] = {"25"};
	x = 0.76;
	y = 1.057;
    w = 0.05;
	h = 0.05;
		};	 		
	/*   		class btnF8: cTab_RscButton
		{
			idc = 347746355436786990909352;
			tooltip = "Satellite Screen Share _ F8";
			action = "execVM 'SATSS.sqf';";
    colorText[] = {1,1,1,0};
	colorDisabled[] = {1,1,1,0.5};
	colorBackground[] = {0,0,0,0.5};
	colorBackgroundDisabled[] = {0,0,0,0.5};
	colorBackgroundActive[] = {0,0,0,0};
	colorFocused[] = {0,0,0,0.5};
	colorShadow[] = {0,0,0,0};
	colorBorder[] = {0,0,0,0};
	shortcuts[] = {"66"};
	x = 0.885;
	y = 1.057;
    w = 0.06;
	h = 0.05;
		};	 	

   */		
}; 


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// class RscTitles
// {

// titles[]={};

// class intro
// {
//   	idd=-1;
//   	movingEnable=0;
//   	duration=999999;
//   	fadein=0;
//   	fadeout=0;
//   	name="intro";
//   	controls[]={
// 	"title1",
// 		"title2",
// 		"title3"	
		
// 		};

// 	  	class title1
// 	{
// 		type=0;
// 		idc=1;
// 		size=5;
// 		colorBackground[]={0,0,0,0};
// 		colorText[]={1,1,1,1};
// 		font="PuristaMedium";
//   	  	text="Screens\FOBA\BACK.paa";
//         style=48;
//   	  	sizeEx=0.15;
//          x = safeZoneX + 0.725 * safeZoneW;
//          y = safeZoneY + 0.11 * safeZoneH;
//          w = safeZoneW * 0.325;
//          h = safeZoneH * 0.54;
// 	};

// 	  	class title2
// 	{
// 		type=0;
// 		idc=1;
// 		size=5;
// 		colorBackground[]={0,0,0,0};
// 		colorText[]={1,1,1,1};
// 		font="PuristaMedium";
//   	  	text="#(argb,512,512,1)r2t(HCAM_S,1)";
//         style=48;
//   	  	sizeEx=0.15;
//          x = safeZoneX + 0.75 * safeZoneW;
//          y = safeZoneY + 0.24 * safeZoneH;
//          w = safeZoneW * 0.244;
//          h = safeZoneH * 0.25;
// 	};

//   	class title3
// 	{
// 		type=0;
// 		idc=2;
// 		size=2;
// 		colorBackground[]={0,0,0,0};
// 		colorText[]={1,1,1,1};
// 		font="PuristaMedium";
//   	  	text = "Screens\FOBA\SAT_DLG.paa";
//         style=48;
//   	  	sizeEx=0.15;
//          x = safeZoneX + 0.725 * safeZoneW;
//          y = safeZoneY + 0.11 * safeZoneH;
//          w = safeZoneW * 0.325;
//          h = safeZoneH * 0.54;
// 	};

// };

// };
