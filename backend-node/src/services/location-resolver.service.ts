/**
 * Location Resolver Service for Egypt.
 * Computes the closest Egyptian governorate, city, or district based on latitude & longitude.
 */

export interface KnownLocation {
  name: string;
  nameEn: string;
  governorate: string;
  governorateEn: string;
  lat: number;
  lng: number;
}

export interface NearestPlaceResult {
  name: string;
  name_en: string;
  governorate: string;
  governorate_en: string;
  distance_km: number;
  formatted: string;
}

// Curated reference dataset of Egyptian governorates, major cities, and key districts
const EGYPT_LOCATIONS: KnownLocation[] = [
  // Cairo (القاهرة)
  { name: 'مدينة نصر', nameEn: 'Nasr City', governorate: 'القاهرة', governorateEn: 'Cairo', lat: 30.0588, lng: 31.3309 },
  { name: 'مصر الجديدة', nameEn: 'Heliopolis', governorate: 'القاهرة', governorateEn: 'Cairo', lat: 30.0893, lng: 31.3269 },
  { name: 'المعادي', nameEn: 'Maadi', governorate: 'القاهرة', governorateEn: 'Cairo', lat: 29.9602, lng: 31.2569 },
  { name: 'التجمع الخامس / القاهرة الجديدة', nameEn: 'New Cairo', governorate: 'القاهرة', governorateEn: 'Cairo', lat: 30.0298, lng: 31.4087 },
  { name: 'حلوان', nameEn: 'Helwan', governorate: 'القاهرة', governorateEn: 'Cairo', lat: 29.8458, lng: 31.3009 },
  { name: 'شبرا', nameEn: 'Shubra', governorate: 'القاهرة', governorateEn: 'Cairo', lat: 30.0911, lng: 31.2464 },
  { name: 'عين شمس', nameEn: 'Ain Shams', governorate: 'القاهرة', governorateEn: 'Cairo', lat: 30.1308, lng: 31.3142 },
  { name: 'وسط البلد', nameEn: 'Downtown Cairo', governorate: 'القاهرة', governorateEn: 'Cairo', lat: 30.0444, lng: 31.2357 },
  { name: 'الزمالك', nameEn: 'Zamalek', governorate: 'القاهرة', governorateEn: 'Cairo', lat: 30.0617, lng: 31.2215 },
  { name: 'المقطم', nameEn: 'Mokattam', governorate: 'القاهرة', governorateEn: 'Cairo', lat: 30.0156, lng: 31.3039 },
  { name: 'الشروق', nameEn: 'El Shorouk', governorate: 'القاهرة', governorateEn: 'Cairo', lat: 30.1444, lng: 31.6319 },
  { name: 'بدر', nameEn: 'Badr City', governorate: 'القاهرة', governorateEn: 'Cairo', lat: 30.1394, lng: 31.7378 },

  // Giza (الجيزة)
  { name: 'الدقي', nameEn: 'Dokki', governorate: 'الجيزة', governorateEn: 'Giza', lat: 30.0379, lng: 31.2070 },
  { name: 'المهندسين', nameEn: 'Mohandessin', governorate: 'الجيزة', governorateEn: 'Giza', lat: 30.0560, lng: 31.2000 },
  { name: 'الهرم', nameEn: 'Haram', governorate: 'الجيزة', governorateEn: 'Giza', lat: 29.9980, lng: 31.1850 },
  { name: 'فيصل', nameEn: 'Faisal', governorate: 'الجيزة', governorateEn: 'Giza', lat: 30.0050, lng: 31.1780 },
  { name: 'مدينة 6 أكتوبر', nameEn: '6th of October', governorate: 'الجيزة', governorateEn: 'Giza', lat: 29.9722, lng: 30.9422 },
  { name: 'الشيخ زايد', nameEn: 'Sheikh Zayed', governorate: 'الجيزة', governorateEn: 'Giza', lat: 30.0475, lng: 31.0022 },
  { name: 'إمبابة', nameEn: 'Imbaba', governorate: 'الجيزة', governorateEn: 'Giza', lat: 30.0750, lng: 31.2080 },
  { name: 'العجوزة', nameEn: 'Agouza', governorate: 'الجيزة', governorateEn: 'Giza', lat: 30.0558, lng: 31.2131 },

  // Alexandria (الإسكندرية)
  { name: 'سيدي جابر', nameEn: 'Sidi Gaber', governorate: 'الإسكندرية', governorateEn: 'Alexandria', lat: 31.2180, lng: 29.9400 },
  { name: 'المنتزه', nameEn: 'Montaza', governorate: 'الإسكندرية', governorateEn: 'Alexandria', lat: 31.2850, lng: 30.0160 },
  { name: 'محرم بك', nameEn: 'Moharam Bek', governorate: 'الإسكندرية', governorateEn: 'Alexandria', lat: 31.1920, lng: 29.9100 },
  { name: 'العجمي', nameEn: 'Agami', governorate: 'الإسكندرية', governorateEn: 'Alexandria', lat: 31.1000, lng: 29.7600 },
  { name: 'برج العرب', nameEn: 'Borg El Arab', governorate: 'الإسكندرية', governorateEn: 'Alexandria', lat: 30.9167, lng: 29.5333 },
  { name: 'سموحة', nameEn: 'Smouha', governorate: 'الإسكندرية', governorateEn: 'Alexandria', lat: 31.2155, lng: 29.9575 },

  // Delta & North
  { name: 'المنصورة', nameEn: 'Mansoura', governorate: 'الدقهلية', governorateEn: 'Dakahlia', lat: 31.0409, lng: 31.3785 },
  { name: 'طنطا', nameEn: 'Tanta', governorate: 'الغربية', governorateEn: 'Gharbia', lat: 30.7865, lng: 31.0004 },
  { name: 'المحلة الكبرى', nameEn: 'El Mahalla El Kubra', governorate: 'الغربية', governorateEn: 'Gharbia', lat: 30.9706, lng: 31.1669 },
  { name: 'كفر الشيخ', nameEn: 'Kafr El Sheikh', governorate: 'كفر الشيخ', governorateEn: 'Kafr El Sheikh', lat: 31.1107, lng: 30.9388 },
  { name: 'دسوق', nameEn: 'Desouk', governorate: 'كفر الشيخ', governorateEn: 'Kafr El Sheikh', lat: 31.1311, lng: 30.6472 },
  { name: 'دمنهور', nameEn: 'Damanhur', governorate: 'البحيرة', governorateEn: 'Beheira', lat: 31.0425, lng: 30.4689 },
  { name: 'إيتاي البارود', nameEn: 'Itay El Barud', governorate: 'البحيرة', governorateEn: 'Beheira', lat: 30.8872, lng: 30.6644 },
  { name: 'الزقازيق', nameEn: 'Zagazig', governorate: 'الشرقية', governorateEn: 'Sharkia', lat: 30.5765, lng: 31.5041 },
  { name: 'العاشر من رمضان', nameEn: '10th of Ramadan', governorate: 'الشرقية', governorateEn: 'Sharkia', lat: 30.3015, lng: 31.7431 },
  { name: 'بنها', nameEn: 'Banha', governorate: 'القليوبية', governorateEn: 'Qalyubia', lat: 30.4660, lng: 31.1850 },
  { name: 'شبرا الخيمة', nameEn: 'Shubra El Kheima', governorate: 'القليوبية', governorateEn: 'Qalyubia', lat: 30.1286, lng: 31.2422 },
  { name: 'العبور', nameEn: 'Obour City', governorate: 'القليوبية', governorateEn: 'Qalyubia', lat: 30.2289, lng: 31.4722 },
  { name: 'شبين الكوم', nameEn: 'Shibin El Kom', governorate: 'المنوفية', governorateEn: 'Monufia', lat: 30.5526, lng: 31.0094 },
  { name: 'دمياط', nameEn: 'Damietta', governorate: 'دمياط', governorateEn: 'Damietta', lat: 31.4175, lng: 31.8144 },
  { name: 'رأس البر', nameEn: 'Ras El Bar', governorate: 'دمياط', governorateEn: 'Damietta', lat: 31.5144, lng: 31.8211 },

  // Canal & Coast
  { name: 'بورسعيد', nameEn: 'Port Said', governorate: 'بورسعيد', governorateEn: 'Port Said', lat: 31.2653, lng: 32.3019 },
  { name: 'بورفؤاد', nameEn: 'Port Fouad', governorate: 'بورسعيد', governorateEn: 'Port Said', lat: 31.2483, lng: 32.3350 },
  { name: 'الإسماعيلية', nameEn: 'Ismailia', governorate: 'الإسماعيلية', governorateEn: 'Ismailia', lat: 30.5965, lng: 32.2715 },
  { name: 'فايد', nameEn: 'Fayed', governorate: 'الإسماعيلية', governorateEn: 'Ismailia', lat: 30.3292, lng: 32.2986 },
  { name: 'السويس', nameEn: 'Suez', governorate: 'السويس', governorateEn: 'Suez', lat: 29.9668, lng: 32.5498 },
  { name: 'العين السخنة', nameEn: 'Ain Sokhna', governorate: 'السويس', governorateEn: 'Suez', lat: 29.6000, lng: 32.3167 },

  // Sinai & Red Sea
  { name: 'شرم الشيخ', nameEn: 'Sharm El Sheikh', governorate: 'جنوب سيناء', governorateEn: 'South Sinai', lat: 27.9158, lng: 34.3299 },
  { name: 'دهب', nameEn: 'Dahab', governorate: 'جنوب سيناء', governorateEn: 'South Sinai', lat: 28.5095, lng: 34.5136 },
  { name: 'نويبع', nameEn: 'Nuweiba', governorate: 'جنوب سيناء', governorateEn: 'South Sinai', lat: 29.0333, lng: 34.6667 },
  { name: 'طابا', nameEn: 'Taba', governorate: 'جنوب سيناء', governorateEn: 'South Sinai', lat: 29.4925, lng: 34.8967 },
  { name: 'الطور', nameEn: 'El Tor', governorate: 'جنوب سيناء', governorateEn: 'South Sinai', lat: 28.2364, lng: 33.6256 },
  { name: 'العريش', nameEn: 'Arish', governorate: 'شمال سيناء', governorateEn: 'North Sinai', lat: 31.1316, lng: 33.7984 },
  { name: 'الغردقة', nameEn: 'Hurghada', governorate: 'البحر الأحمر', governorateEn: 'Red Sea', lat: 27.2579, lng: 33.8116 },
  { name: 'الجونة', nameEn: 'El Gouna', governorate: 'البحر الأحمر', governorateEn: 'Red Sea', lat: 27.3944, lng: 33.6764 },
  { name: 'سفاجا', nameEn: 'Safaga', governorate: 'البحر الأحمر', governorateEn: 'Red Sea', lat: 26.7292, lng: 33.9365 },
  { name: 'مرسى علم', nameEn: 'Marsa Alam', governorate: 'البحر الأحمر', governorateEn: 'Red Sea', lat: 25.0676, lng: 34.8790 },

  // Upper Egypt
  { name: 'الفيوم', nameEn: 'Faiyum', governorate: 'الفيوم', governorateEn: 'Faiyum', lat: 29.3084, lng: 30.8428 },
  { name: 'بني سويف', nameEn: 'Beni Suef', governorate: 'بني سويف', governorateEn: 'Beni Suef', lat: 29.0661, lng: 31.0994 },
  { name: 'المنيا', nameEn: 'Minya', governorate: 'المنيا', governorateEn: 'Minya', lat: 28.1099, lng: 30.7503 },
  { name: 'ملوي', nameEn: 'Mallawi', governorate: 'المنيا', governorateEn: 'Minya', lat: 27.7317, lng: 30.8417 },
  { name: 'أسيوط', nameEn: 'Asyut', governorate: 'أسيوط', governorateEn: 'Asyut', lat: 27.1783, lng: 31.1859 },
  { name: 'سوهاج', nameEn: 'Sohag', governorate: 'سوهاج', governorateEn: 'Sohag', lat: 26.5590, lng: 31.6957 },
  { name: 'طهطا', nameEn: 'Tahta', governorate: 'سوهاج', governorateEn: 'Sohag', lat: 26.7694, lng: 31.5022 },
  { name: 'قنا', nameEn: 'Qena', governorate: 'قنا', governorateEn: 'Qena', lat: 26.1551, lng: 32.7160 },
  { name: 'نجع حمادي', nameEn: 'Nag Hammadi', governorate: 'قنا', governorateEn: 'Qena', lat: 26.0494, lng: 32.2414 },
  { name: 'الأقصر', nameEn: 'Luxor', governorate: 'الأقصر', governorateEn: 'Luxor', lat: 25.6872, lng: 32.6396 },
  { name: 'أسوان', nameEn: 'Aswan', governorate: 'أسوان', governorateEn: 'Aswan', lat: 24.0889, lng: 32.8998 },
  { name: 'كوم أمبو', nameEn: 'Kom Ombo', governorate: 'أسوان', governorateEn: 'Aswan', lat: 24.4767, lng: 32.9461 },
  { name: 'إدفو', nameEn: 'Edfu', governorate: 'أسوان', governorateEn: 'Aswan', lat: 24.9781, lng: 32.8753 },

  // Western Desert
  { name: 'مرسى مطروح', nameEn: 'Marsa Matrouh', governorate: 'مطروح', governorateEn: 'Matrouh', lat: 31.3543, lng: 27.2373 },
  { name: 'العلمين', nameEn: 'El Alamein', governorate: 'مطروح', governorateEn: 'Matrouh', lat: 30.8333, lng: 28.9500 },
  { name: 'سيوة', nameEn: 'Siwa', governorate: 'مطروح', governorateEn: 'Matrouh', lat: 29.2032, lng: 25.5195 },
  { name: 'الخارجة', nameEn: 'Kharga', governorate: 'الوادي الجديد', governorateEn: 'New Valley', lat: 25.4514, lng: 30.5472 },
  { name: 'الداخلة', nameEn: 'Dakhla', governorate: 'الوادي الجديد', governorateEn: 'New Valley', lat: 25.5200, lng: 28.9800 },
];

/**
 * Calculates Haversine distance between two points in kilometers.
 */
function calculateDistanceKm(lat1: number, lon1: number, lat2: number, lon2: number): number {
  const R = 6371; // Earth's radius in km
  const dLat = ((lat2 - lat1) * Math.PI) / 180;
  const dLon = ((lon2 - lon1) * Math.PI) / 180;
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos((lat1 * Math.PI) / 180) *
      Math.cos((lat2 * Math.PI) / 180) *
      Math.sin(dLon / 2) *
      Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}

export class LocationResolverService {
  /**
   * Finds the closest Egyptian location to the given latitude and longitude.
   */
  public getNearestPlace(lat?: number | null, lng?: number | null): NearestPlaceResult | null {
    if (lat === null || lat === undefined || lng === null || lng === undefined) {
      return null;
    }

    const numLat = Number(lat);
    const numLng = Number(lng);

    if (isNaN(numLat) || isNaN(numLng)) {
      return null;
    }

    let minDistance = Infinity;
    let closestLocation: KnownLocation = EGYPT_LOCATIONS[0];

    for (const loc of EGYPT_LOCATIONS) {
      const dist = calculateDistanceKm(numLat, numLng, loc.lat, loc.lng);
      if (dist < minDistance) {
        minDistance = dist;
        closestLocation = loc;
      }
    }

    const roundedDist = Math.round(minDistance * 10) / 10;
    const isSameName = closestLocation.name === closestLocation.governorate;
    const formatted = isSameName
      ? closestLocation.name
      : `${closestLocation.name}، ${closestLocation.governorate}`;

    return {
      name: closestLocation.name,
      name_en: closestLocation.nameEn,
      governorate: closestLocation.governorate,
      governorate_en: closestLocation.governorateEn,
      distance_km: roundedDist,
      formatted,
    };
  }
}

export const locationResolverService = new LocationResolverService();
