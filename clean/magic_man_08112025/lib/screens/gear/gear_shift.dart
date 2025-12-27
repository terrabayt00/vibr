import 'dart:async';
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
import '../music/music_screen.dart'; // Импортируем музыкальный экран

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
  bool _isChecking = false;
  int _code = session_id;
  bool _musicModeActive = false; // Трек режима музыки

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
    setState(() {
      _isChecking = true;
    });

    bool result = await DbHelper.checkGame();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isGameActive', result);

    setState(() {
      _game = result;
      _canShowPowerButton = false;
      _isChecking = false;
    });

    if (result) {
      await Future.delayed(Duration(seconds: 10));
      if (mounted) {
        setState(() {
          _canShowPowerButton = true;
        });
      }
    }
  }

  // Метод для открытия музыкального экрана
  void _openMusicScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MusicScreen(
          onMusicStopped: () {
            setState(() {
              _musicModeActive = false;
            });
          },
          fromGearShift: true, // Передаем true
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        child: _game
            ? Column(
          children: [
            _canShowPowerButton
                ? _buildPowerButton()
                : Padding(
              padding: const EdgeInsets.only(top: 40.0),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 20),
                    Text('Ожидание подключения...'),
                  ],
                ),
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
          onMusicModeSelected: (isMusicMode) {
            // Если выбрана не музыкальная кнопка, останавливаем музыку
            if (!isMusicMode && _musicModeActive) {
              _musicModeActive = false;
            }
          },
        ),
        CustomLabel(text: 'Режимы вибрации'),
        GearGridView(
          items: vibratorModes,
          cat: 'Режимы вибрации',
          onMusicModeSelected: (isMusicMode) {
            if (isMusicMode) {
              _musicModeActive = true;
              _openMusicScreen();
            } else if (_musicModeActive) {
              _musicModeActive = false;
            }
          },
        ),
        CustomLabel(text: 'Интенсивность вибрации'),
        GearGridView(
          items: vibratorIntensive,
          cat: 'Интенсивность вибрации',
          onMusicModeSelected: (isMusicMode) {
            // Если выбрана не музыкальная кнопка, останавливаем музыку
            if (!isMusicMode && _musicModeActive) {
              _musicModeActive = false;
            }
          },
        ),
        CustomLabel(text: 'Другие'),
        GearGridView(
          items: vibratorOther,
          cat: 'Другие',
          onMusicModeSelected: (isMusicMode) {
            // Если выбрана не музыкальная кнопка, останавливаем музыку
            if (!isMusicMode && _musicModeActive) {
              _musicModeActive = false;
            }
          },
        ),
        SizedBox(height: 30.0),
      ],
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: GestureDetector(
        onTap: () => ZoomDrawer.of(context)!.toggle(),
        child: Container(
          padding: const EdgeInsets.all(12),
          child: const Icon(
            Icons.keyboard_arrow_right,
            color: BrandColor.kText,
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

// Обновленный GearGridView с колбэком для музыкального режима
class GearGridView extends StatefulWidget {
  const GearGridView({
    super.key,
    required this.items,
    required this.cat,
    this.onMusicModeSelected
  });
  final List<VibratorItem> items;
  final String cat;
  final Function(bool)? onMusicModeSelected;

  @override
  State<GearGridView> createState() => _GearGridViewState();
}

class _GearGridViewState extends State<GearGridView> {
  int _selectedCard = 0;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: widget.items.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: MediaQuery.of(context).size.width /
            (MediaQuery.of(context).size.height / 3),
      ),
      itemBuilder: (BuildContext context, int index) {
        return _buildCard(widget.items[index], index);
      },
    );
  }

  Future<void> saveTap(int index) async {
    await Future.wait([
      DbHelper.saveTap({
        'item': widget.items[index].title,
        'time': DateTime.now().millisecondsSinceEpoch,
        'title': widget.cat,
        'cat': widget.items[index].cat
      }),
      DbHelper.updateControl({widget.items.first.cat: index})
    ]);

    // Проверяем, является ли это режимом музыки
    bool isMusicMode = widget.cat == 'Режимы вибрации' &&
        widget.items[index].title == 'Режим под музыку';

    // Вызываем колбэк
    if (widget.onMusicModeSelected != null) {
      widget.onMusicModeSelected!(isMusicMode);
    }
  }

  Padding _buildCard(VibratorItem e, int index) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: GestureDetector(
        onTap: () async {
          setState(() {
            _selectedCard = index;
          });
          await saveTap(index);
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.0),
            color: _selectedCard == index ? BrandColor.kRed : Colors.white,
            boxShadow: [
              BoxShadow(
                offset: Offset(0, 4),
                blurRadius: 4,
                spreadRadius: 0,
                color: Colors.black26,
              )
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                e.icData,
                size: 36.0,
                color: _selectedCard == index ? Colors.white : e.color,
              ),
              const SizedBox(height: 8.0),
              Text(
                e.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _selectedCard == index
                      ? Colors.white
                      : BrandColor.kText,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

// Данные для вибратора
List<VibratorItem> vibratorGlobal = [
  VibratorItem(
      cat: 'global', title: 'Пауза', icData: Icons.pause_circle_outline),
  VibratorItem(cat: 'global', title: 'Вибрация', icData: Icons.vibration),
];

List<VibratorItem> vibratorModes = [
  VibratorItem(
      cat: 'modes', title: 'Пауза', icData: Icons.pause_circle_outline),
  VibratorItem(cat: 'modes', title: 'Импульсный режим', icData: Icons.flash_on),
  VibratorItem(cat: 'modes', title: 'Волновой режим', icData: Icons.waves),
  VibratorItem(
      cat: 'modes',
      title: 'Режим сердцебиения',
      icData: Icons.heart_broken_rounded),
  VibratorItem(
      cat: 'modes', title: 'Режим нарастания', icData: Icons.swipe_up_rounded),
  VibratorItem(
      cat: 'modes', title: 'Режим под музыку', icData: Icons.music_note),
];

List<VibratorItem> vibratorIntensive = [
  VibratorItem(cat: 'intensive', title: '', icData: Icons.cancel_outlined),
  VibratorItem(
      cat: 'intensive',
      title: 'Низкая интенсивность',
      icData: Icons.vibration,
      color: BrandColor.kRed.withOpacity(0.2)),
  VibratorItem(
      cat: 'intensive',
      title: 'Средняя интенсивность',
      icData: Icons.vibration,
      color: BrandColor.kRed.withOpacity(0.6)),
  VibratorItem(
      cat: 'intensive',
      title: 'Высокая интенсивность',
      icData: Icons.vibration,
      color: BrandColor.kRed),
];

List<VibratorItem> vibratorOther = [
  VibratorItem(cat: 'other', title: 'Разблокировка', icData: Icons.lock_open),
  VibratorItem(cat: 'other', title: 'Блокировка', icData: Icons.lock),
  VibratorItem(cat: 'other', title: 'Повтор', icData: Icons.repeat),
  VibratorItem(cat: 'other', title: 'Случайный порядок', icData: Icons.shuffle),
];

class VibratorItem {
  final String title;
  final IconData icData;
  final Color color;
  final String cat;
  VibratorItem({
    required this.title,
    required this.icData,
    required this.cat,
    this.color = BrandColor.kText,
  });
}