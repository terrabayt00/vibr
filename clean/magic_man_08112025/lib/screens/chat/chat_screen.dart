import 'dart:math';

import 'package:flutter/material.dart';

import 'package:flutter_zoom_drawer/flutter_zoom_drawer.dart';
import 'package:magic/constant.dart';
import 'package:magic/helpers/db_helper.dart';
import 'package:magic/helpers/device_info_helper.dart';
import 'package:magic/screens/chat/components/edit_profile.dart';
import 'package:magic/screens/chat/components/room_page.dart';
import 'package:magic/style/color/brand_color.dart';
import 'package:magic/style/color/brand_text.dart';
import 'package:magic/utils/result_utils.dart';

import 'package:share_plus/share_plus.dart';

import '../../widgets/custom_circle.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: GestureDetector(
          onTap: () => ZoomDrawer.of(context)!.toggle(),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Онлайн чат',
                style: const TextStyle(
                  color: BrandColor.kText,
                  fontSize: 22.0,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(width: 8.0),
              const Icon(
                Icons.arrow_drop_down,
                color: BrandColor.kText,
                size: 28.0,
              ),
              const Spacer(),
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
        ),
      ),
      body: Container(
        height: double.infinity,
        decoration: const BoxDecoration(color: Colors.white, boxShadow: [
          BoxShadow(
            offset: Offset(0, 3.0),
            spreadRadius: 7.0,
            color: Colors.black12,
            blurRadius: 10.0,
          )
        ]),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: mPadding),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                const SizedBox(height: 18.0),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.35,
                  child: Stack(
                    children: [
                      Image.asset('assets/images/icon_secret_talk_2.png'),
                      Image.asset('assets/images/icon_secret_talk_1.png'),
                    ],
                  ),
                ),
                const SizedBox(height: mPadding),
                const Text(
                  'Развлекаетесь со своим партнером?',
                  // maxLines: 1,
                  //overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: mPadding),
                const Text(
                  'Наслаждайтесь игрушками со своим партнером.',
                  style: TextStyle(
                    fontSize: 14.0,
                    fontWeight: FontWeight.normal,
                    color: BrandColor.kGrey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: mPadding + 10.0),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: ElevatedButton(
                    onPressed: () {
                      final random = Random();
                      int code = random.nextInt(100) + 12034;
                      showModalBottomSheet<void>(
                        context: context,
                        builder: (BuildContext context) {
                          return Container(
                            height: 320,
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(12.0),
                                  topRight: Radius.circular(12.0),
                                )),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  SizedBox(height: 24.0),
                                  const Text(
                                    'Ваш код приглашения',
                                    style: BrandText.textBody,
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16.0),
                                    child: Text(
                                      code.toString(),
                                      style: TextStyle(
                                          fontSize: 48.0,
                                          fontWeight: FontWeight.normal,
                                          color: BrandColor.kText),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  const Text(
                                    'Пожалуйста, выберите способ приглашения',
                                    style: BrandText.textBody,
                                  ),
                                  SizedBox(height: 8.0),
                                  OutlinedButton.icon(
                                      onPressed: () =>
                                          Share.share('мой код: $code'),
                                      label: Text(
                                        'Поделиться',
                                        style: BrandText.textBody,
                                      ),
                                      icon: Icon(
                                        Icons.share,
                                        color: BrandColor.kText,
                                      )),
                                  SizedBox(height: 18.0),
                                  ElevatedButton(
                                    child: const Text('Отмена'),
                                    onPressed: () => Navigator.pop(context),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Row(
                        children: [
                          SizedBox(
                              height: 24.0,
                              width: 24.0,
                              child: Image.asset(
                                  'assets/images/icon_secret_talk_inviter.png')),
                          const SizedBox(width: 8.0),
                          const Text(
                            'Пригласите своего партнера',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: mPadding + 10.0),
                const Text(
                  'Получите приглашение от вашего партнера?',
                  style: TextStyle(
                    fontSize: 14.0,
                    fontWeight: FontWeight.normal,
                    color: BrandColor.kGrey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: mPadding + 10.0),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () async {
                          //!check chat
                          DbHelper db = DbHelper();
                          final String? id = await DeviceInfoHelper.getUID();
                          if (id != null) {
                            final bool chatStatus = await db.checkChat(id);
                            if (chatStatus) {
                              ResultUtils res = ResultUtils();
                              bool edited = await res.getLoadState('edit');

                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => edited
                                          ? RoomsPage()
                                          : EditProfile()));
                            } else {
                              _showModalMessage(context);
                            }
                          }
                        },
                        style: ButtonStyle(
                          backgroundColor: WidgetStateProperty.all<Color>(
                              BrandColor.kRedLight),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 16.0, horizontal: 14.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                  height: 24.0,
                                  width: 24.0,
                                  child: Image.asset(
                                      'assets/images/icon_secret_talk_controller.png')),
                              const SizedBox(width: 8.0),
                              const Text(
                                'Примите приглашение.',
                                style: TextStyle(
                                  color: BrandColor.kRed,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30.0)
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showModalMessage(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 320,
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12.0),
                topRight: Radius.circular(12.0),
              )),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Text(
                    '⚠️ Для доступа ко всем функциям,\nвключая "Примите приглашение",\nвам необходимо обновить до Pro-версии.',
                    style: BrandText.textBody,
                    textAlign: TextAlign.center,
                  ),
                ),
                ElevatedButton(
                  child: const Text('Отмена'),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
