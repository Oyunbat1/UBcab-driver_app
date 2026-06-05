class ApiConstants {
  /// Google Maps / Directions API key.
  ///
  /// ⚠️ Энэ key дээр Google Cloud Console-оос **Directions API**-г заавал
  /// идэвхжүүлсэн байх ёстой (зөвхөн Maps SDK хангалтгүй).
  /// Мөн key-н "Application restrictions" нь web-service дуудлагыг блоклохгүй
  /// байх ёстой (iOS/Android-only restriction-той бол Directions дуудлага амжилтгүй болно).
  static const String googleMapsApiKey =
      'AIzaSyDgfMVv_Qv9c6tdCwrSS_oQLVCN2L8gdnY';

  /// Directions API web service endpoint.
  static const String directionsBaseUrl =
      'https://maps.googleapis.com/maps/api/directions/json';
}
