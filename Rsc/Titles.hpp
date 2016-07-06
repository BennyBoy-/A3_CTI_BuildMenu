class RscTitles {
	class CTI_ConstructionInterface {
		idd = 112200;
		movingEnable = 0;
		duration = 1e+011;
		name = "Construction Interface";
		onLoad = "uiNamespace setVariable ['cti_title_coin', _this select 0]";
		onUnload = "uiNamespace setVariable ['cti_title_coin', displayNull]";
		
		class controlsBackground {
			class CTI_Background : RscText {
				x = "SafeZoneX";
				y = "SafeZoneY + (SafezoneH * 0.91)";
				w = "SafeZoneW";
				h = "SafeZoneH * 0.1";
				colorBackground[] = {0, 0, 0, 0.5};
				moving = 1;
			};
		};
		
		class controls {
			class Cursor : RscPictureKeepAspect {
				idc = 112201;
				x = 0.4;
				y = 0.4;
				w = 0.2;
				h = 0.2;
				colorText[] = {1, 1, 1, 0.1};
				colorBackground[] = {0, 0, 0, 0};
				text = "Rsc\cursor_w_laserlock_gs.paa";
			};
			
			class IconWall: RscPictureKeepAspect {
				idc = 112216;
				x = "SafeZoneX + (SafeZoneW * 0.75)";
				y = "SafeZoneY + (SafezoneH * 0.953)";
				w = "SafeZoneW * 0.04";
				h = "SafeZoneH * 0.04";
				
				colorText[] = {1, 1, 1, 0.3};
				colorBackground[] = {0, 0, 0, 0};
				text = "Rsc\icon_walls.paa";
			};
			
			class IconStaticMan: IconWall {
				idc = 112217;
				x = "SafeZoneX + (SafeZoneW * 0.72)";
				
				text = "Rsc\icon_staticman.paa";
			};
			
			class DescriptionText : RscStructuredText {
				idc = 112214;
				x = "SafeZoneX + (SafeZoneW * 0.21)";
				y = "SafeZoneY + (SafezoneH * 0.913)";
				w = "SafeZoneW * 0.58";
				h = "SafeZoneH * 0.1";
				sizeEx = "(			(			(			((safezoneW / safezoneH) min 1.2) / 1.2) / 25) * 1)";
				
				// colorBackground[] = {0, 0, 0, 0.6}; //debug
				
				class Attributes {
					font = "PuristaMedium";
					color = "#42b6ff";
					align = "left";
					shadow = true;
				};
			};
			
			class ControlsText : DescriptionText {
				idc = 112215;
				
				x = "SafeZoneX + (SafeZoneW * 0.8)";
				w = "SafeZoneW * 0.2";
			};
			
			class CashText : DescriptionText {
				idc = 112224;
				
				x = "SafeZoneX";
				w = "SafeZoneW * 0.15";
			};
		};
	};
};