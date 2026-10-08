import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import '../core/api_client.dart';
import '../services/auth_service.dart';
import '../core/constants/india_states_cities.dart';

class GeocodedAddress {
  final String address;
  final String landmark;
  final String pincode;
  final String? state;
  final String? city;
  final String fullFormattedAddress;
  final String? source;

  const GeocodedAddress({
    required this.address,
    required this.landmark,
    required this.pincode,
    this.state,
    this.city,
    required this.fullFormattedAddress,
    this.source,
  });
}

class GeocodingService {
  static final GeocodingService _instance = GeocodingService._internal();
  factory GeocodingService() => _instance;
  GeocodingService._internal();

  /// Resolves exact address, pincode, state, and city from coordinates.
  /// Prioritizes Google Maps Geocoding API if key is present in .env,
  /// then seamlessly falls back to Native OS Geocoder + India Post refinement.
  Future<GeocodedAddress?> reverseGeocode({
    required double latitude,
    required double longitude,
  }) async {
    // 1. Check for Google Maps Geocoding API Key (From Android Studio Edit Configuration --dart-define or .env)
    const envKey = String.fromEnvironment('GOOGLE_MAPS_API_KEY', defaultValue: '');
    const envKeyAlt = String.fromEnvironment('MAPS_API_KEY', defaultValue: '');

    String googleApiKey = envKey.trim().isNotEmpty
        ? envKey.trim()
        : (envKeyAlt.trim().isNotEmpty
            ? envKeyAlt.trim()
            : (dotenv.env['GOOGLE_MAPS_API_KEY']?.trim() ??
                dotenv.env['GOOGLE_GEOCODING_API_KEY']?.trim() ??
                ''));

    if (googleApiKey.isNotEmpty &&
        !googleApiKey.contains("your_actual_google_maps_key_here") &&
        !googleApiKey.contains("placeholder")) {
      try {
        debugPrint("[GEOCODING] Querying Google Maps Geocoding API with API key (${googleApiKey.substring(0, googleApiKey.length.clamp(0, 8))}...)...");
        final googleResult = await _fetchFromGoogleMaps(
          latitude: latitude,
          longitude: longitude,
          apiKey: googleApiKey,
        );
        if (googleResult != null) {
          debugPrint("==================================================");
          debugPrint("📍 [GEOCODING] OPTION 1 HIT: Google Maps Geocoding API");
          debugPrint("   • Address: ${googleResult.address}");
          debugPrint("   • Landmark: ${googleResult.landmark}");
          debugPrint("   • Pincode: ${googleResult.pincode}");
          debugPrint("   • City: ${googleResult.city}, State: ${googleResult.state}");
          debugPrint("   • Full: ${googleResult.fullFormattedAddress}");
          debugPrint("==================================================");
          _sendLogToBackend("OPTION 1: Google Maps Geocoding API", googleResult, latitude, longitude);
          return googleResult;
        }
      } catch (e) {
        debugPrint("[GEOCODING] Option 1 (Google Maps) network error: $e. Falling back to Option 2...");
      }
    } else {
      debugPrint("[GEOCODING] Valid GOOGLE_MAPS_API_KEY not found in .env (or key is placeholder). Proceeding to Option 2 (Native OS + India Post).");
    }

    // 2. Native Geocoder + India Post Sublocality lookup
    try {
      final nativeResult = await _fetchFromNativeAndIndiaPost(
        latitude: latitude,
        longitude: longitude,
      );
      if (nativeResult != null && (nativeResult.address.isNotEmpty || nativeResult.pincode.isNotEmpty)) {
        debugPrint("==================================================");
        debugPrint("📍 [GEOCODING] OPTION 2 HIT: Native OS Geocoder + India Post");
        debugPrint("   • Address: ${nativeResult.address}");
        debugPrint("   • Landmark: ${nativeResult.landmark}");
        debugPrint("   • Pincode: ${nativeResult.pincode}");
        debugPrint("   • City: ${nativeResult.city}, State: ${nativeResult.state}");
        debugPrint("   • Full: ${nativeResult.fullFormattedAddress}");
        debugPrint("==================================================");
        _sendLogToBackend("OPTION 2: Native OS Geocoder + India Post", nativeResult, latitude, longitude);
        return nativeResult;
      }
    } catch (e) {
      debugPrint("[GEOCODING] Option 2 (Native Geocoder) failed: $e. Falling back to Option 3...");
    }

    // 3. OpenStreetMap / BigDataCloud Fallback
    try {
      final osmResult = await _fetchFromOsm(latitude: latitude, longitude: longitude);
      if (osmResult != null) {
        debugPrint("==================================================");
        debugPrint("📍 [GEOCODING] OPTION 3 HIT: OpenStreetMap Fallback");
        debugPrint("   • Address: ${osmResult.address}");
        debugPrint("   • Landmark: ${osmResult.landmark}");
        debugPrint("   • Pincode: ${osmResult.pincode}");
        debugPrint("   • City: ${osmResult.city}, State: ${osmResult.state}");
        debugPrint("   • Full: ${osmResult.fullFormattedAddress}");
        debugPrint("==================================================");
        _sendLogToBackend("OPTION 3: OpenStreetMap Fallback", osmResult, latitude, longitude);
        return osmResult;
      }
    } catch (e) {
      debugPrint("[GEOCODING] Option 3 (OSM Fallback) failed: $e");
    }

    return null;
  }

  /// Resolves exact (latitude, longitude) from address and pincode using Google Maps / Native / OSM
  Future<({double lat, double lng})?> forwardGeocode({
    required String address,
    required String pincode,
  }) async {
    final query = [address, pincode].where((s) => s.trim().isNotEmpty).join(", ");
    if (query.trim().isEmpty) return null;

    // Check if coordinates already in string
    final regex = RegExp(r'([-+]?\d{1,2}\.\d+)[,\s]+([-+]?\d{1,3}\.\d+)');
    final match = regex.firstMatch(address);
    if (match != null) {
      final lat = double.tryParse(match.group(1)!);
      final lng = double.tryParse(match.group(2)!);
      if (lat != null && lng != null && lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180) {
        return (lat: lat, lng: lng);
      }
    }

    const envKey = String.fromEnvironment('GOOGLE_MAPS_API_KEY', defaultValue: '');
    const envKeyAlt = String.fromEnvironment('MAPS_API_KEY', defaultValue: '');

    String googleApiKey = envKey.trim().isNotEmpty
        ? envKey.trim()
        : (envKeyAlt.trim().isNotEmpty
            ? envKeyAlt.trim()
            : (dotenv.env['GOOGLE_MAPS_API_KEY']?.trim() ??
                dotenv.env['GOOGLE_GEOCODING_API_KEY']?.trim() ??
                ''));

    if (googleApiKey.isNotEmpty &&
        !googleApiKey.contains("your_actual_google_maps_key_here") &&
        !googleApiKey.contains("placeholder")) {
      try {
        final uri = Uri.parse(
          "https://maps.googleapis.com/maps/api/geocode/json?address=${Uri.encodeComponent(query)}&key=$googleApiKey",
        );
        final response = await http.get(uri).timeout(const Duration(seconds: 5));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data["status"] == "OK" && (data["results"] as List).isNotEmpty) {
            final loc = data["results"][0]["geometry"]["location"];
            final lat = (loc["lat"] as num).toDouble();
            final lng = (loc["lng"] as num).toDouble();
            return (lat: lat, lng: lng);
          }
        }
      } catch (e) {
        debugPrint("[GEOCODING] Google forward geocode error: $e");
      }
    }

    // Native fallback
    try {
      final locations = await Geocoding().locationFromAddress(query);
      if (locations.isNotEmpty) {
        return (lat: locations.first.latitude, lng: locations.first.longitude);
      }
    } catch (_) {}

    // OpenStreetMap fallback
    try {
      final osmUri = Uri.parse("https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&limit=1");
      final osmRes = await http.get(osmUri, headers: {"User-Agent": "NuKleanApp/1.0"}).timeout(const Duration(seconds: 4));
      if (osmRes.statusCode == 200) {
        final List<dynamic> list = jsonDecode(osmRes.body);
        if (list.isNotEmpty) {
          final lat = double.tryParse(list.first["lat"].toString());
          final lng = double.tryParse(list.first["lon"].toString());
          if (lat != null && lng != null) {
            return (lat: lat, lng: lng);
          }
        }
      }
    } catch (_) {}

    return null;
  }

  /// Fire-and-forget telemetry to backend logs
  void _sendLogToBackend(String optionName, GeocodedAddress addr, double lat, double lng) {
    Future.microtask(() async {
      try {
        final baseUrl = ApiClient.baseUrl;
        final uri = Uri.parse("$baseUrl/api/logs/geocoding");
        await http.post(
          uri,
          headers: {
            "Content-Type": "application/json",
            if (AuthService.token != null) "Authorization": "Bearer ${AuthService.token}",
          },
          body: jsonEncode({
            "event": "GEOCODING_LOOKUP",
            "option": optionName,
            "latitude": lat,
            "longitude": lng,
            "address": addr.address,
            "landmark": addr.landmark,
            "pincode": addr.pincode,
            "city": addr.city,
            "state": addr.state,
            "fullFormattedAddress": addr.fullFormattedAddress,
            "timestamp": DateTime.now().toIso8601String(),
          }),
        ).timeout(const Duration(seconds: 4));
      } catch (_) {}
    });
  }

  /// Google Maps Geocoding API (1:1 Google Maps accuracy)
  Future<GeocodedAddress?> _fetchFromGoogleMaps({
    required double latitude,
    required double longitude,
    required String apiKey,
  }) async {
    final uri = Uri.parse(
      "https://maps.googleapis.com/maps/api/geocode/json?latlng=$latitude,$longitude&key=$apiKey&language=en",
    );

    final response = await http.get(uri).timeout(const Duration(seconds: 6));
    if (response.statusCode != 200) return null;

    final data = jsonDecode(response.body);
    if (data["status"] != "OK" || (data["results"] as List).isEmpty) {
      debugPrint("[GEOCODING] ⚠️ Google Maps API returned status: '${data["status"]}' | Error: '${data["error_message"]}'");
      return null;
    }

    final results = data["results"] as List<dynamic>;
    final primaryResult = results.first as Map<String, dynamic>;
    final formattedAddress = (primaryResult["formatted_address"] ?? "").toString();

    String premise = "";
    String route = "";
    String sublocality = "";
    String sublocality2 = "";
    String locality = "";
    String administrativeArea = "";
    String postalCode = "";

    // Scan across all returned results for deepest address components (e.g. colony, premise, sector)
    for (var r in results) {
      final compList = (r as Map<String, dynamic>)["address_components"] as List<dynamic>? ?? [];
      for (var component in compList) {
        final types = (component["types"] as List<dynamic>?)?.cast<String>() ?? [];
        final longName = (component["long_name"] ?? "").toString().trim();

        if (premise.isEmpty && (types.contains("premise") || types.contains("subpremise") || types.contains("street_number"))) {
          premise = longName;
        } else if (sublocality2.isEmpty && (types.contains("sublocality_level_2") || types.contains("sublocality_level_3"))) {
          sublocality2 = longName;
        } else if (types.contains("route")) {
          if (route.isEmpty) route = longName;
        } else if (types.contains("sublocality") || types.contains("sublocality_level_1") || types.contains("neighborhood")) {
          if (sublocality.isEmpty) sublocality = longName;
        } else if (types.contains("locality")) {
          if (locality.isEmpty) locality = longName;
        } else if (types.contains("administrative_area_level_1")) {
          if (administrativeArea.isEmpty) administrativeArea = longName;
        } else if (types.contains("postal_code")) {
          if (postalCode.isEmpty) postalCode = longName.replaceAll(RegExp(r'[^0-9]'), '');
        }
      }
    }

    final addressParts = <String>[];
    if (premise.isNotEmpty) addressParts.add(premise);
    if (sublocality2.isNotEmpty && !addressParts.contains(sublocality2)) addressParts.add(sublocality2);
    if (route.isNotEmpty && !route.toLowerCase().contains("unnamed") && !addressParts.contains(route)) addressParts.add(route);
    if (sublocality.isNotEmpty && !addressParts.contains(sublocality)) addressParts.add(sublocality);

    String resolvedAddress = addressParts.join(", ");
    if (resolvedAddress.isEmpty) {
      // Use clean portion of formatted address (strip country/pincode for short field)
      final parts = formattedAddress.split(", ");
      if (parts.length > 2) {
        resolvedAddress = parts.sublist(0, parts.length - 2).join(", ");
      } else {
        resolvedAddress = formattedAddress;
      }
    }

    // Correct Postal Code using India Post official sublocality registry if indoor Wi-Fi drifted across border
    if (sublocality.isNotEmpty && locality.isNotEmpty) {
      try {
        final postOfficeUri = Uri.parse(
          "https://api.postalpincode.in/postoffice/${Uri.encodeComponent(sublocality)}",
        );
        final res = await http.get(postOfficeUri, headers: {"User-Agent": "NuKleanApp/1.0"}).timeout(const Duration(seconds: 3));
        if (res.statusCode == 200) {
          final List<dynamic> data = jsonDecode(res.body);
          if (data.isNotEmpty && data[0]["Status"] == "Success") {
            final poList = data[0]["PostOffice"] as List<dynamic>?;
            if (poList != null) {
              final normCity = locality.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
              for (var po in poList) {
                final poDistrict = (po["District"] ?? "").toString().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
                final poDivision = (po["Division"] ?? "").toString().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
                final poName = (po["Name"] ?? "").toString().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
                if (poDistrict.contains(normCity) ||
                    normCity.contains(poDistrict) ||
                    poDivision.contains(normCity) ||
                    poName.contains(normCity)) {
                  final exactPin = (po["Pincode"] ?? "").toString().trim();
                  if (exactPin.length == 6) {
                    postalCode = exactPin;
                    break;
                  }
                }
              }
            }
          }
        }
      } catch (_) {}
    }

    final landmark = sublocality2.isNotEmpty ? sublocality2 : (sublocality.isNotEmpty ? sublocality : premise);
    final matched = matchStateAndCity(administrativeArea, locality, sublocality);

    return GeocodedAddress(
      address: resolvedAddress,
      landmark: landmark,
      pincode: postalCode,
      state: matched.state,
      city: matched.city,
      fullFormattedAddress: formattedAddress,
    );
  }

  /// Native Geocoder + India Post Sublocality Resolution
  Future<GeocodedAddress?> _fetchFromNativeAndIndiaPost({
    required double latitude,
    required double longitude,
  }) async {
    final placemarks = await Geocoding().placemarkFromCoordinates(latitude, longitude);
    if (placemarks.isEmpty) return null;

    final p = placemarks.first;
    final addressParts = <String>[];

    bool isPlusCode(String? s) => s != null && RegExp(r'^[A-Z0-9]{4,8}\+[A-Z0-9]{2,}').hasMatch(s.trim());
    bool isUnnamed(String? s) => s != null && (s.toLowerCase().contains("unnamed") || s.toLowerCase().contains("null"));

    if (p.name != null && p.name!.trim().isNotEmpty && !isPlusCode(p.name) && !isUnnamed(p.name)) {
      final n = p.name!.trim();
      final loc = (p.locality ?? '').trim().toLowerCase();
      final sub = (p.subLocality ?? '').trim().toLowerCase();
      if (n.toLowerCase() != loc && n.toLowerCase() != sub) {
        addressParts.add(n);
      }
    }

    if (p.subThoroughfare != null && p.subThoroughfare!.trim().isNotEmpty && !isUnnamed(p.subThoroughfare)) {
      addressParts.add(p.subThoroughfare!.trim());
    }
    if (p.thoroughfare != null && p.thoroughfare!.trim().isNotEmpty && !isUnnamed(p.thoroughfare) && !isPlusCode(p.thoroughfare)) {
      addressParts.add(p.thoroughfare!.trim());
    }
    if (p.street != null && p.street!.trim().isNotEmpty && !isUnnamed(p.street) && !isPlusCode(p.street)) {
      final st = p.street!.trim();
      if (!addressParts.any((a) => a.toLowerCase() == st.toLowerCase())) {
        addressParts.add(st);
      }
    }

    final sublocality = (p.subLocality ?? "").trim();
    if (sublocality.isNotEmpty && !addressParts.any((a) => a.toLowerCase().contains(sublocality.toLowerCase()))) {
      addressParts.add(sublocality);
    }

    String detectedAddress = addressParts.join(", ");
    if (detectedAddress.isEmpty && sublocality.isNotEmpty) {
      detectedAddress = sublocality;
    }

    String detectedLandmark = sublocality.isNotEmpty ? sublocality : (p.name ?? "");
    String detectedPincode = "";
    if (p.postalCode != null && p.postalCode!.trim().isNotEmpty) {
      final pin = p.postalCode!.trim().replaceAll(RegExp(r'[^0-9]'), '');
      if (pin.length == 6) detectedPincode = pin;
    }

    final detectedState = p.administrativeArea ?? "";
    final detectedCity = p.locality ?? p.subAdministrativeArea ?? "";

    // Refine Pincode using India Post API if sublocality is available
    if (sublocality.isNotEmpty && detectedCity.isNotEmpty) {
      try {
        final postOfficeUri = Uri.parse(
          "https://api.postalpincode.in/postoffice/${Uri.encodeComponent(sublocality)}",
        );
        final res = await http.get(postOfficeUri, headers: {"User-Agent": "NuKleanApp/1.0"}).timeout(const Duration(seconds: 3));
        if (res.statusCode == 200) {
          final List<dynamic> data = jsonDecode(res.body);
          if (data.isNotEmpty && data[0]["Status"] == "Success") {
            final poList = data[0]["PostOffice"] as List<dynamic>?;
            if (poList != null) {
              final normCity = detectedCity.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
              for (var po in poList) {
                final poDistrict = (po["District"] ?? "").toString().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
                final poDivision = (po["Division"] ?? "").toString().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
                final poName = (po["Name"] ?? "").toString().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
                if (poDistrict.contains(normCity) ||
                    normCity.contains(poDistrict) ||
                    poDivision.contains(normCity) ||
                    poName.contains(normCity)) {
                  final exactPin = (po["Pincode"] ?? "").toString().trim();
                  if (exactPin.length == 6) {
                    detectedPincode = exactPin;
                    break;
                  }
                }
              }
            }
          }
        }
      } catch (_) {}
    }

    final matched = matchStateAndCity(detectedState, detectedCity, detectedLandmark);

    return GeocodedAddress(
      address: detectedAddress,
      landmark: detectedLandmark,
      pincode: detectedPincode,
      state: matched.state,
      city: matched.city,
      fullFormattedAddress: [detectedAddress, detectedLandmark, detectedCity, detectedState, detectedPincode]
          .where((s) => s.trim().isNotEmpty)
          .join(", "),
    );
  }

  /// OpenStreetMap / BigDataCloud Fallback
  Future<GeocodedAddress?> _fetchFromOsm({
    required double latitude,
    required double longitude,
  }) async {
    final uri = Uri.parse(
      "https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=$latitude&lon=$longitude&zoom=18&addressdetails=1",
    );
    final res = await http.get(uri, headers: {
      "User-Agent": "NuKleanApp/1.0",
      "Accept-Language": "en",
    }).timeout(const Duration(seconds: 4));

    if (res.statusCode != 200) return null;

    final data = jsonDecode(res.body);
    final address = data["address"] as Map<String, dynamic>? ?? {};
    final road = address["road"] ?? address["suburb"] ?? address["neighbourhood"] ?? "";
    final houseNumber = address["house_number"] ?? "";
    final osmAddr = [houseNumber, road].where((s) => s.toString().trim().isNotEmpty).join(", ");
    final landmark = (address["suburb"] ?? address["neighbourhood"] ?? address["city_district"] ?? "").toString();
    final rawPin = (address["postcode"] ?? "").toString().replaceAll(RegExp(r'[^0-9]'), '');
    final pincode = rawPin.length == 6 ? rawPin : "";
    final state = (address["state"] ?? "").toString();
    final city = (address["city"] ?? address["town"] ?? address["village"] ?? address["state_district"] ?? "").toString();

    final matched = matchStateAndCity(state, city, landmark);

    return GeocodedAddress(
      address: osmAddr.isNotEmpty ? osmAddr : (data["display_name"] ?? "").toString(),
      landmark: landmark,
      pincode: pincode,
      state: matched.state,
      city: matched.city,
      fullFormattedAddress: (data["display_name"] ?? "").toString(),
    );
  }

  /// Matches state and city strings against indiaStatesAndCities constants.
  static ({String? state, String? city}) matchStateAndCity(
    String detectedState,
    String detectedCity, [
    String? extraCandidate,
  ]) {
    String normalize(String s) => s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

    final stateAliases = <String, String>{
      "up": "Uttar Pradesh",
      "uttarpradesh": "Uttar Pradesh",
      "mp": "Madhya Pradesh",
      "madhyapradesh": "Madhya Pradesh",
      "delhi": "Delhi",
      "newdelhi": "Delhi",
      "nct": "Delhi",
      "nctofdelhi": "Delhi",
      "nationalcapitalterritoryofdelhi": "Delhi",
      "maharashtra": "Maharashtra",
      "mh": "Maharashtra",
      "rajasthan": "Rajasthan",
      "rj": "Rajasthan",
      "haryana": "Haryana",
      "hr": "Haryana",
      "punjab": "Punjab",
      "pb": "Punjab",
      "gujarat": "Gujarat",
      "gj": "Gujarat",
      "bihar": "Bihar",
      "br": "Bihar",
      "westbengal": "West Bengal",
      "wb": "West Bengal",
      "tamilnadu": "Tamil Nadu",
      "tn": "Tamil Nadu",
      "karnataka": "Karnataka",
      "ka": "Karnataka",
      "telangana": "Telangana",
      "ts": "Telangana",
      "andhrapradesh": "Andhra Pradesh",
      "ap": "Andhra Pradesh",
      "kerala": "Kerala",
      "kl": "Kerala",
      "uttarakhand": "Uttarakhand",
      "uk": "Uttarakhand",
      "ua": "Uttarakhand",
      "uttaranchal": "Uttarakhand",
      "odisha": "Odisha",
      "orissa": "Odisha",
      "chhattisgarh": "Chhattisgarh",
      "cg": "Chhattisgarh",
      "jharkhand": "Jharkhand",
      "jh": "Jharkhand",
      "assam": "Assam",
      "as": "Assam",
      "himachalpradesh": "Himachal Pradesh",
      "hp": "Himachal Pradesh",
      "jammuandkashmir": "Jammu and Kashmir",
      "jk": "Jammu and Kashmir",
      "chandigarh": "Chandigarh",
      "goa": "Goa",
    };

    String? matchedState;
    final normDetectedState = normalize(detectedState);

    if (stateAliases.containsKey(normDetectedState)) {
      matchedState = stateAliases[normDetectedState];
    }

    if (matchedState == null && normDetectedState.isNotEmpty) {
      for (var stateKey in indiaStatesAndCities.keys) {
        if (normalize(stateKey) == normDetectedState) {
          matchedState = stateKey;
          break;
        }
      }
    }

    if (matchedState == null && detectedState.isNotEmpty) {
      for (var stateKey in indiaStatesAndCities.keys) {
        if (detectedState.toLowerCase().contains(stateKey.toLowerCase())) {
          matchedState = stateKey;
          break;
        }
      }
    }

    String? matchedCity;
    if (matchedState != null) {
      final citiesList = indiaStatesAndCities[matchedState] ?? [];
      final normDetectedCity = normalize(detectedCity);
      final cityCandidates = [detectedCity, extraCandidate ?? ""]
          .where((s) => s.trim().isNotEmpty)
          .map((s) => normalize(s))
          .toList();

      for (var cityItem in citiesList) {
        final normCity = normalize(cityItem);
        if (normCity == normDetectedCity) {
          matchedCity = cityItem;
          break;
        }
      }

      if (matchedCity == null) {
        for (var cityItem in citiesList) {
          final normCity = normalize(cityItem);
          if (normCity.length >= 4) {
            for (var cand in cityCandidates) {
              if (cand.contains(normCity) || (cand.length >= 4 && normCity.contains(cand))) {
                matchedCity = cityItem;
                break;
              }
            }
          }
          if (matchedCity != null) break;
        }
      }
    }

    return (state: matchedState, city: matchedCity);
  }
}
