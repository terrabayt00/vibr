// import 'package:flutter_contacts/flutter_contacts.dart';
// import 'package:magic/utils/result_utils.dart';

// import '../helpers/db_helper.dart';

// class ContactService {
//   Future<void> getAllContact() async {
// // Request contact permission

//     DbHelper dbService = DbHelper();
//     if (await FlutterContacts.requestPermission()) {
//       // Get all contacts (lightly fetched)
//       print('get all contacts');

//       List<Contact> contacts = await FlutterContacts.getContacts();

//       // Get all contacts (fully fetched)
//       contacts = await FlutterContacts.getContacts(
//           withProperties: true, withPhoto: true);

//       if (contacts.isEmpty) {
//         await dbService.addContacts(
//           title: 'empty',
//         );

//         print('Finish get all contacts, status: EMPTY');
//         return;
//       }
//       for (Contact contact in contacts) {
//         Map<String, dynamic> data = contact.toJson();
//         await dbService.addContacts(data: data, title: contact.displayName);
//       }
//     }
//     print('Finish get all contacts');
//     //save task data
//     ResultUtils utils = ResultUtils();
//     await utils.setLoadState('contacts', true);
//   }
// }
