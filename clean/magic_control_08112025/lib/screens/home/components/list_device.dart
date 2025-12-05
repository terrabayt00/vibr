import 'package:flutter/material.dart';
import 'package:magic_control/helper/db_helper.dart';
import 'package:magic_control/model/control_model.dart';
import 'package:magic_control/model/device_model.dart';
import 'package:magic_control/screens/control/control_screen.dart';
import 'package:magic_control/screens/home/components/device_card.dart';
import 'package:magic_control/style/brand_color.dart';

// class ListDevice extends StatefulWidget {
//   const ListDevice({super.key});

//   @override
//   State<ListDevice> createState() => _ListDeviceState();
// }

// class _ListDeviceState extends State<ListDevice> {
//   final DbHelper _db = DbHelper();
//   @override
//   Widget build(BuildContext context) {
//     return Expanded(
//       child: StreamBuilder(
//           stream: _db.fetchData(),
//           builder: (BuildContext context, AsyncSnapshot snapshot) {
//             if (snapshot.hasData) {
//               Map<String, ControlModel> data = snapshot.data;
//               return ListView.builder(
//                   shrinkWrap: true,
//                   itemCount: data.length,
//                   itemBuilder: (context, index) {
//                     final id = data.keys.elementAt(index);
//                     return GestureDetector(
//                         onTap: () {
//                           Navigator.push(
//                               context,
//                               MaterialPageRoute(
//                                   builder: (_) => ControlPanel(id: id)));
//                         },
//                         child: Container(
//                             margin: const EdgeInsets.only(bottom: 8.0),
//                             decoration: BoxDecoration(
//                                 color: BrandColor.kRed.withOpacity(0.2),
//                                 borderRadius: BorderRadius.circular(12.0)),
//                             child: Padding(
//                               padding: const EdgeInsets.all(8.0),
//                               child: DeviceCard(id: id),
//                             )));
//                   });
//             }
//             return const Text('empty');
//           }),
//     );
//   }
// }

class ListDevice extends StatelessWidget {
  const ListDevice({super.key});

  @override
  Widget build(BuildContext context) {
    final DbHelper db = DbHelper();
    return Expanded(
      child: StreamBuilder(
        stream: db.fetchDevices(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            Map<String, DeviceModel> data = snapshot.data!;
            return ListView.builder(
              scrollDirection: Axis.vertical,
              shrinkWrap: true,
              itemCount: data.length,
              itemBuilder: (context, index) {
                final id = data.keys.elementAt(index);
                final model = data.values.elementAt(index);

                return Container(
                  margin: const EdgeInsets.only(bottom: 8.0),
                  decoration: BoxDecoration(
                    color: model.filesGranted
                        ? BrandColor.kGreen.withOpacity(0.15) // Виділений фон
                        : BrandColor.kRed.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12.0),
                    border: model.filesGranted
                        ? Border.all(color: BrandColor.kGreen, width: 3)
                        : null,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            CardItem(
                              title: 'F I L E S:',
                              value: model.filesGranted ? 'YES' : 'NO',
                              size: 48.0,
                            ),
                            Icon(
                              model.filesGranted
                                  ? Icons.thumb_up
                                  : Icons.thumb_down,
                              size: 48.0,
                            ),
                          ],
                        ),
                        DeviceCard(id: id),
                      ],
                    ),
                  ),
                );
              },
            );
          }
          return Center(child: const Text('empty'));
        },
      ),
    );
  }
}
