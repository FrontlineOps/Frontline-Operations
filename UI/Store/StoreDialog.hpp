#define FLO_STORE_CT_WEBBROWSER 106

class FLO_StoreDialog {
	idd = 9800;
	movingEnable = 0;
	enableSimulation = 1;
	onUnload = "uiNamespace setVariable ['FLO_StoreControl', controlNull]; FLO_StoreActiveBaseNetId = ''";

	class Controls {
		class Browser: RscText {
			idc = 9801;
			type = FLO_STORE_CT_WEBBROWSER;
			style = 0;
			x = "safeZoneX";
			y = "safeZoneY";
			w = "safeZoneW";
			h = "safeZoneH";
			colorBackground[] = {0, 0, 0, 0};
		};
	};
};
