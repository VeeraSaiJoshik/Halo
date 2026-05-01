import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/pages/OnboardingPage.dart';
import 'package:frontend/themes/halo_theme.dart';
import 'package:frontend/themes/theme_provider.dart';
import 'package:frontend/widgets/OnboardingWidgets/OnboardingProtocols.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsHandler {
  late SharedPreferences globalSettings;
  
  Platform? buyingPlatform;
  Platform? chartingPlatform;
  HaloThemeType? theme;
  
  Future<bool> initialize() async {
    globalSettings = await SharedPreferences.getInstance();

    String? buying_id = globalSettings.getString("buyingPlatform");
    String? charting_id = globalSettings.getString("chartingPlatform");
    String? theme_id = globalSettings.getString("themeId");

    if( buying_id != null ) {
      buyingPlatform = buyingPlatforms.firstWhere(
        (element) => element.id == buying_id
      );
    }
    if( charting_id != null ) {
      chartingPlatform = chartingPlatforms.firstWhere(
        (element) => element.id == charting_id
      );
    }

    if ( theme_id != null ) {
      theme = parseString(theme_id);
    }

    return true;
  }

  bool onboardingFlag() {
    print("${buyingPlatform} ${chartingPlatform} ${theme}");
    return buyingPlatform == null && chartingPlatform == null && theme == null;
  }

  Future<bool> saveFormControllerData (FormController form) async {
    if(
      form.selectedBuyingPlatform == null ||
      form.selectedChartingPlatform == null
    ) return false;

    bool buyingPlatformFlag = await globalSettings.setString(
      "buyingPlatform", 
      form.selectedBuyingPlatform!.id
    );
    bool chartingPlatformFlag = await globalSettings.setString(
      "chartingPlatform", 
      form.selectedChartingPlatform!.id
    );

    bool themeData = await globalSettings.setString(
      "themeId", 
      form.selectedChartingPlatform!.id
    );

    return chartingPlatformFlag && buyingPlatformFlag && themeData;
  }
}