import 'package:shared/presentation/localization/translations/app_localizations.dart';

class EgyptRegions {
  static List<String> getGovernorates(AppLocalizations l10n) {
    return [l10n.address_gov_cairo, l10n.address_gov_giza];
  }

  static Map<String, List<String>> getCitiesMap(AppLocalizations l10n) {
    return {
      l10n.address_gov_cairo: [
        l10n.address_city_zamalek,
        l10n.address_city_garden_city,
        l10n.address_city_maadi,
        l10n.address_city_heliopolis,
        l10n.address_city_fifth_settlement,
        l10n.address_city_new_cairo,
        l10n.address_city_rehab,
        l10n.address_city_madinaty,
        l10n.address_city_nasr_city,
        l10n.address_city_mokattam,
        l10n.address_city_shorouk,
        l10n.address_city_other
      ],
      l10n.address_gov_giza: [
        l10n.address_city_zayed,
        l10n.address_city_october,
        l10n.address_city_mohandessin,
        l10n.address_city_dokki,
        l10n.address_city_agouza,
        l10n.address_city_hadayek_ahram,
        l10n.address_city_haram,
        l10n.address_city_faisal,
        l10n.address_city_imbaba,
        l10n.address_city_other
      ],
    };
  }
}
