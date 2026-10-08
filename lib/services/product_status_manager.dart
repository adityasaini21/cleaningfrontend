import 'package:shared_preferences/shared_preferences.dart';

class ProductStatusManager {
  static Set<int> _forcedLiveIds = {};
  static Set<int> _forcedComingSoonIds = {};

  static Set<int> get forcedLiveIds => _forcedLiveIds;
  static Set<int> get forcedComingSoonIds => _forcedComingSoonIds;

  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final liveList = prefs.getStringList('forced_live_product_ids') ?? [];
      final csList = prefs.getStringList('forced_coming_soon_product_ids') ?? [];

      _forcedLiveIds = liveList.map((e) => int.tryParse(e)).whereType<int>().toSet();
      _forcedComingSoonIds = csList.map((e) => int.tryParse(e)).whereType<int>().toSet();
    } catch (_) {}
  }

  static bool isProductLive(int id, String name) {
    if (_forcedLiveIds.contains(id)) return true;
    if (_forcedComingSoonIds.contains(id)) return false;

    final n = name.trim().toLowerCase();

    // Explicit exclusions for compound / liquid / non-live variants
    if (n.contains('compound')) return false;
    if (n.contains('detergent powder') || n.contains('detergent')) return false;
    if (n.contains('safe wash')) return false;
    if (n.contains('dish wash liquid') || n.contains('dish wash soap')) return false;
    if (n.contains('anti stain') || n.contains('antistain')) return false;
    if (n.contains('room freshener')) return false;
    if (n.contains('pet shampoo')) return false;

    // 1. Tiles Cleaner
    if (n.contains('tiles cleaner') || n.contains('tile cleaner') || n.contains('tiles+toiletcleaner')) return true;
    // 2. Toilet Cleaner
    if (n.contains('toilet cleaner') || n.contains('toiletcleaner')) return true;
    // 3. Glass Cleaner
    if (n.contains('glass cleaner') || n.contains('glasscleaner')) return true;
    // 4. Germtral / Germdral
    if (n.contains('germtral') || n.contains('germdral')) return true;
    // 5. White Phenyl
    if (n.contains('white phenyl') || n.contains('whitephenyl')) return true;
    // 6. Hand Wash Gel / Hand Wash
    if (n.contains('hand wash') || n.contains('handwash')) return true;
    // 7. Pink Phenyl
    if (n.contains('pink phenyl') || n.contains('pinkphenyl')) return true;
    // 8. Black Phenyl
    if (n.contains('black phenyl') || n.contains('blackphenyl')) return true;
    // 9. Dish Wash Gel
    if (n.contains('dish wash gel') || n.contains('dishwash gel')) return true;
    // 10. VehiClean / Car Shampoo
    if (n.contains('vehiclean') || n.contains('car shampoo') || n.contains('carshampoo')) return true;

    return false;
  }

  static Future<bool> toggleProductStatus(int productId, String name) async {
    final bool currentIsLive = isProductLive(productId, name);
    final bool newIsLive = !currentIsLive;

    if (newIsLive) {
      _forcedLiveIds.add(productId);
      _forcedComingSoonIds.remove(productId);
    } else {
      _forcedComingSoonIds.add(productId);
      _forcedLiveIds.remove(productId);
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('forced_live_product_ids', _forcedLiveIds.map((id) => id.toString()).toList());
      await prefs.setStringList('forced_coming_soon_product_ids', _forcedComingSoonIds.map((id) => id.toString()).toList());
    } catch (_) {}

    return newIsLive;
  }
}
