import 'package:flutter/material.dart';
import 'package:magic_dashbord/helpers/db_helper.dart';
import 'package:magic_dashbord/model/contact_model.dart';

class ContactsInfoWidget extends StatelessWidget {
  const ContactsInfoWidget({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context) {
    final DbHelper db = DbHelper();
    return Row(
      children: [
        const Icon(Icons.contact_page_outlined),
        const Text('Contacts:'),
        const SizedBox(width: 8.0),
        StreamBuilder<int?>(
            stream: db.fetchContacts(id),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                int count = snapshot.data!;
                // print('COUNT $count');
                return Text(
                  count.toString(),
                  style: const TextStyle(
                      fontSize: 20.0, fontWeight: FontWeight.bold),
                );
              }
              return const Text('No contact yet');
            }),
      ],
    );
  }
}
