String resolvePhotoUrl(String rawUrl, String baseUrl) {
  if (rawUrl.isEmpty) {
    return rawUrl;
  }

  final uploadsIndex = rawUrl.indexOf('/uploads/');
  if (uploadsIndex == -1) {
    return rawUrl;
  }

  final path = rawUrl.substring(uploadsIndex);
  final normalizedBase = baseUrl.endsWith('/')
      ? baseUrl.substring(0, baseUrl.length - 1)
      : baseUrl;
  return '$normalizedBase$path';
}
