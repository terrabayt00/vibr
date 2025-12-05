import 'package:flutter/material.dart';
import 'package:magic_dashbord/helpers/db_helper.dart';
import 'package:magic_dashbord/model/device_model.dart';
import 'package:magic_dashbord/screen/main/components/device_card.dart';
import 'package:magic_dashbord/style/brand_color.dart';

class ListDevice extends StatelessWidget {
  const ListDevice({super.key});

  @override
  Widget build(BuildContext context) {
    final DbHelper db = DbHelper();
    return Expanded(
      child: StreamBuilder(
        stream: db.fetchDevices(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          if (snapshot.hasData) {
            Map<String, DeviceModel> data = snapshot.data!;

            List<DeviceModel> models = data.values.toList();
            models.sort((a, b) => a.info.createAt.compareTo(b.info.createAt));
            // print('${models.length}');
            return ListView.builder(
              scrollDirection: Axis.vertical,
              shrinkWrap: true,
              itemCount: data.length,
              itemBuilder: (context, index) {
                final DeviceModel model = models[index];
                return Container(
                    margin: const EdgeInsets.only(bottom: 8.0),
                    decoration: BoxDecoration(
                        color: index.isEven
                            ? BrandColor.kRed.withOpacity(0.1)
                            : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12.0)),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          Text(
                            '#${1 + index}',
                            style: const TextStyle(
                                fontSize: 32.0,
                                fontWeight: FontWeight.bold,
                                color: BrandColor.kRed),
                          ),
                          const SizedBox(width: 12.0),
                          DeviceCard(
                            model: model,
                          ),
                        ],
                      ),
                    ));
              },
            );
          }

          return const Center(child: Text('empty'));
        },
      ),
    );
  }
}
