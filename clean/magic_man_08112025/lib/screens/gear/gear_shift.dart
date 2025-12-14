import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_zoom_drawer/flutter_zoom_drawer.dart';
import 'package:magic/helpers/db_helper.dart';
import 'package:magic/main.dart';
import 'package:magic/screens/gear/grid.dart';
import 'package:magic/style/color/brand_text.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../style/color/brand_color.dart';
import '../../widgets/custom_circle.dart';

class GearShiftScreen extends StatefulWidget {
  const GearShiftScreen({super.key});

  @override
  State<GearShiftScreen> createState() => _GearShiftScreenState();
}

class _GearShiftScreenState extends State<GearShiftScreen> {
  bool _powerOn = false;
  bool _loading = false;
  bool _game = false;
  bool _canShowPowerButton = false;
  bool _isChecking = false; // Додано: флаг для стану перевірки
  int _code = session_id;

  @override
  void initState() {
    saveState();
    super.initState();
  }

  saveState() async {
    await DbHelper.resetControl();
    await checkgame();
  }

  checkgame() async {
    // Додано: початок перевірки
    setState(() {
      _isChecking = true;
    });

    bool result = await DbHelper.checkGame();
    // Save game status for background sync logic
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isGameActive', result);
    // Завжди скидаємо флаг при перевірці
    setState(() {
      _game = result;
      _canShowPowerButton = false;
      _isChecking = false; // Додано: завершення перевірки
    });

    // Якщо гра активна, чекаємо 10 секунд
    if (result) {
      await Future.delayed(Duration(seconds: 10));
      if (mounted) {
        setState(() {
          _canShowPowerButton = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        child: _game
            ? Column(
          children: [
            // Змінено: перевірка чи можна показувати кнопку
            _canShowPowerButton
                ? _buildPowerButton()
                : Padding(
              padding: const EdgeInsets.only(top: 40.0),
              child: Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text('Ожидание подключения...'),
                ],
              ),
            ),
            _powerOn
                ? !_loading
                ? LoadingWidget()
                : _buildControl()
                : _loading
                ? LoadingWidget(text: 'Отключение...')
                : SizedBox(),
          ],
        )
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 60.0),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Для создания соединения между устройствами вам необходимо использовать следующий код:',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ),
            Text(
              _code.toString(),
              style: TextStyle(
                fontSize: 48.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 30.0),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ElevatedButton(
                onPressed: () {
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
                                  _code.toString(),
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
                                      Share.share('мой код: $_code'),
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
                        'Отправте свой КОД партнеру',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 45.0),
            // Змінено: кнопка Проверить з індикатором завантаження
            _isChecking
                ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: CircularProgressIndicator(),
            )
                : ElevatedButton.icon(
              style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all(
                      BrandColor.kRed)),
              onPressed: checkgame,
              icon: Icon(
                Icons.refresh_outlined,
                color: Colors.white,
              ),
              label: Text(
                'Проверить',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> initConnect(bool state) async {
    await Future.delayed(Duration(seconds: 5), () {
      setState(() {
        _loading = state;
      });
    });
  }

  Widget _buildPowerButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () async {
              setState(() {
                _powerOn = !_powerOn;
              });
              bool state = _powerOn;
              await initConnect(state);
            },
            child: Card(
              color: _powerOn ? BrandColor.kRed : Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.power_settings_new,
                      size: 36.0,
                      color: _powerOn ? Colors.white : BrandColor.kText,
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      'Включить/выключить вибратор',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: _powerOn ? Colors.white : BrandColor.kText),
                    )
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControl() {
    return Column(
      children: [
        CustomLabel(text: 'Общие'),
        GearGridView(
          items: vibratorGlobal,
          cat: 'Общие',
        ),
        CustomLabel(text: 'Режимы вибрации'),
        GearGridView(
          items: vibratorModes,
          cat: 'Режимы вибрации',
        ),
        CustomLabel(text: 'Интенсивность вибрации'),
        GearGridView(
          items: vibratorIntensive,
          cat: 'Интенсивность вибрації',
        ),
        CustomLabel(text: 'Другие'),
        GearGridView(
          items: vibratorOther,
          cat: 'Другие',
        ),
        SizedBox(height: 30.0),
      ],
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      title: GestureDetector(
        onTap: () => ZoomDrawer.of(context)!.toggle(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: 4,
              child: Text(
                'Джойстик',
                style: const TextStyle(
                  color: BrandColor.kText,
                  fontSize: 22.0,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Spacer(
              flex: 1,
            ),
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
    );
  }
}

class LoadingWidget extends StatelessWidget {
  const LoadingWidget({super.key, this.text = 'Подключение...'});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(height: 40.0),
        CircularProgressIndicator.adaptive(),
        SizedBox(height: 8.0),
        Text(
          text,
          style:
          TextStyle(color: BrandColor.kText, fontWeight: FontWeight.w600),
        )
      ],
    );
  }
}

class CustomLabel extends StatelessWidget {
  const CustomLabel({
    super.key,
    required this.text,
  });
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Text(
        text,
        style: BrandText.sTitle,
      ),
    );
  }
}