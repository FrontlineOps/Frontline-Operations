#define FLO_DEPLOY_CT_WEBBROWSER 106

class FLO_DeployDialog {
	idd = 9900;
	movingEnable = 0;
	enableSimulation = 1;
	onUnload = "uiNamespace setVariable ['FLO_DeployControl', controlNull]; FLO_BaseDeployBrowserReady = false; FLO_BaseDeployRenderKey = ''";

	class Controls {
		class Browser: RscText {
			idc = 9901;
			type = FLO_DEPLOY_CT_WEBBROWSER;
			style = 0;
			x = "safeZoneX";
			y = "safeZoneY";
			w = "safeZoneW";
			h = "safeZoneH";
			colorBackground[] = {0, 0, 0, 0};
		};
	};
};
