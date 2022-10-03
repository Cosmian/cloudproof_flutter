import 'dart:convert';

import 'package:cloudproof/cloudproof.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Cloudproof', () {
    test('CoverCryptDecryption.decrypt', () async {
      final encrypted = base64Decode(
          "AAAApQAAAGGQRxoBq/Yf0KlkLjBCRbCR8tQDF7AJ6RZaFaP/GOJFdnoHqouOoYSF3WGAy2vrkeVOi6kmRRo1h0Y6+6lzGLMXAdiJUa59Oy+ZYQ/OmJwRj0ZmE8TgLxTskF7UmbXnwQP3iETaIBoY2Picl3mwZQTLsz2nPMUDskMK/fjleKCNqR0aA3IuCMS4JpyEeZyuFClHPbjsJxMHS0BtsyaTXebXSreOIYBPl2ywpyvqdtDaY6o3wQzaiLHRU5cseDcxcUj/+SEWZRJKIgEYwwmurO6LoH+wCSjuTaVA0kDaDdd/HSZ2b+2RxdyeaV1K+l/d0aXIXUNX4qQWguQ9rbZg9zDI01jV7tk2Q/PIuB/qkF/D0Fz2mNDdk6J4G4fM0f7DL9yVM8Y9bfsSe15UEigK/gkSXKs96/xZGeDAqEdb3aoFKW6m272aefo4p0V754qGV8WQX2lPnWFkyD4TBeFnWzPjzdytdKvyMbcGJ1iACDKvdUa5JpVmfIIZyxaQYZuYoaPinVZ6Vx2vUhT/wLvTTBIlzxdpq3ydY54okyT9IHJFCwQBOB2xpaC6RYfaxTHUOSC1P9w1L4KNiQD0em0Q8fJD1REvznjhOL0YiRxMuOMhH9AcZsX2LVVI3uNSa81CUOhgSXqI2U5MFphwHD7V2ZrzmzUPDy++LeL1hYwWs31DjEt6cu/ORE3HnV2ccnqovED0+2GjnahHbqoaOU92akiGrxXrSYXMuevYP9e6ERi7Fm81pVjWsmN/3/vfWydRlqjo7VXHQIPOxyqc/6v0mCGFHV7UWw==");

      final key = base64Decode(
          "7F4indGmKCsQbfLHHiyH0n19acuqI8NU33S56oAREgQ7+yX/bsaCQQMeKkPoftF2pAEvH7bVDAPXQMSsss9vCQECAQR+WA+2Z7Y+BPGV0norPeSMFTPASyUXH6pn6VDlEfFkDw==");

      final result = CoverCryptDecryption(key).decrypt(encrypted);

      expect(
          base64Encode(result),
          equals(
              "eyJTbiI6Il81TjlsalFAb1MiLCJnaXZlbk5hbWUiOiJNYXJ0aW5vcyIsImRlcGFydG1lbnROdW1iZXIiOiIzNzciLCJ0aXRsZSI6Il80XFxDV1Y5UXRoIiwiY2FZZWxsb3dQYWdlc0NhdGVnb3J5IjoiMTo0MzVTUDJWTSIsInVpZCI6IkZMMk5NTFdyd14iLCJlbXBsb3llZU51bWJlciI6IkdJdGtaYmFdcjkiLCJNYWlsIjoiWWxjcF5ldWdaVCIsIlRlbGVwaG9uZU51bWJlciI6IlVGdnI+PnpTMFQiLCJNb2JpbGUiOiI7ZV9qVVlYWkw/IiwiZmFjc2ltaWxlVGVsZXBob25lTnVtYmVyIjoiMFFCMG5PakM1SSIsImNhUGVyc29uTG9jYWxpc2F0aW9uIjoiYm01bjhMdGRjWiIsIkNuIjoiallUTHJPbHMxMSIsImNhVW5pdGRuIjoiT0l3VUlhYEloMiIsImRlcGFydG1lbnQiOiJwXz5OdFpkXFx3OSIsImNvIjoiRnJhbmNlIn0="));
    });
    test('CoverCryptDecryption.decrypt', () async {
      final encrypted = base64Decode(
          "AAAApQAAAGGQRxoBq/Yf0KlkLjBCRbCR8tQDF7AJ6RZaFaP/GOJFdnoHqouOoYSF3WGAy2vrkeVOi6kmRRo1h0Y6+6lzGLMXAdiJUa59Oy+ZYQ/OmJwRj0ZmE8TgLxTskF7UmbXnwQP3iETaIBoY2Picl3mwZQTLsz2nPMUDskMK/fjleKCNqR0aA3IuCMS4JpyEeZyuFClHPbjsJxMHS0BtsyaTXebXSreOIYBPl2ywpyvqdtDaY6o3wQzaiLHRU5cseDcxcUj/+SEWZRJKIgEYwwmurO6LoH+wCSjuTaVA0kDaDdd/HSZ2b+2RxdyeaV1K+l/d0aXIXUNX4qQWguQ9rbZg9zDI01jV7tk2Q/PIuB/qkF/D0Fz2mNDdk6J4G4fM0f7DL9yVM8Y9bfsSe15UEigK/gkSXKs96/xZGeDAqEdb3aoFKW6m272aefo4p0V754qGV8WQX2lPnWFkyD4TBeFnWzPjzdytdKvyMbcGJ1iACDKvdUa5JpVmfIIZyxaQYZuYoaPinVZ6Vx2vUhT/wLvTTBIlzxdpq3ydY54okyT9IHJFCwQBOB2xpaC6RYfaxTHUOSC1P9w1L4KNiQD0em0Q8fJD1REvznjhOL0YiRxMuOMhH9AcZsX2LVVI3uNSa81CUOhgSXqI2U5MFphwHD7V2ZrzmzUPDy++LeL1hYwWs31DjEt6cu/ORE3HnV2ccnqovED0+2GjnahHbqoaOU92akiGrxXrSYXMuevYP9e6ERi7Fm81pVjWsmN/3/vfWydRlqjo7VXHQIPOxyqc/6v0mCGFHV7UWw==");

      final key = base64Decode(
          "7F4indGmKCsQbfLHHiyH0n19acuqI8NU33S56oAREgQ7+yX/bsaCQQMeKkPoftF2pAEvH7bVDAPXQMSsss9vCQECAQR+WA+2Z7Y+BPGV0norPeSMFTPASyUXH6pn6VDlEfFkDw==");

      // With cache
      final coverCryptDecryptionWithCache = CoverCryptDecryptionWithCache(key);
      const uid = "00000001";

      final result = coverCryptDecryptionWithCache.decrypt(encrypted);

      coverCryptDecryptionWithCache.destroyDecryptionCache();

      expect(
          base64Encode(result),
          equals(
              "eyJTbiI6Il81TjlsalFAb1MiLCJnaXZlbk5hbWUiOiJNYXJ0aW5vcyIsImRlcGFydG1lbnROdW1iZXIiOiIzNzciLCJ0aXRsZSI6Il80XFxDV1Y5UXRoIiwiY2FZZWxsb3dQYWdlc0NhdGVnb3J5IjoiMTo0MzVTUDJWTSIsInVpZCI6IkZMMk5NTFdyd14iLCJlbXBsb3llZU51bWJlciI6IkdJdGtaYmFdcjkiLCJNYWlsIjoiWWxjcF5ldWdaVCIsIlRlbGVwaG9uZU51bWJlciI6IlVGdnI+PnpTMFQiLCJNb2JpbGUiOiI7ZV9qVVlYWkw/IiwiZmFjc2ltaWxlVGVsZXBob25lTnVtYmVyIjoiMFFCMG5PakM1SSIsImNhUGVyc29uTG9jYWxpc2F0aW9uIjoiYm01bjhMdGRjWiIsIkNuIjoiallUTHJPbHMxMSIsImNhVW5pdGRuIjoiT0l3VUlhYEloMiIsImRlcGFydG1lbnQiOiJwXz5OdFpkXFx3OSIsImNvIjoiRnJhbmNlIn0="));
    });
  });
}
