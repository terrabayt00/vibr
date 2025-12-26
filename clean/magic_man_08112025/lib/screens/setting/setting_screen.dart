import 'package:flutter/material.dart';
import 'package:flutter_zoom_drawer/flutter_zoom_drawer.dart';
import 'package:magic/screens/setting/swith_item.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:magic/style/color/brand_color.dart';
import 'package:magic/style/color/brand_text.dart';

import '../../widgets/custom_circle.dart';
import 'item_data.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  String _currentIntensity = 'Средний';

  @override
  void initState() {
    super.initState();
    _loadIntensity();
  }

  Future<void> _loadIntensity() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentIntensity = prefs.getString('intensity') ?? 'Средний';
    });
  }

  Future<void> _saveIntensity(String intensity) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('intensity', intensity);
    setState(() {
      _currentIntensity = intensity;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildIntensityRow(context),
              const SwithItemButton(),
              ...items.map((item) => _buildRow(
                context,
                item,
                onTap: _getOnTapForItem(context, item),
              )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIntensityRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 40.0),
      child: InkWell(
        onTap: () {
          _showIntensityDialog(context);
        },
        borderRadius: BorderRadius.circular(8.0),
        splashColor: BrandColor.kRed.withOpacity(0.1),
        highlightColor: BrandColor.kRed.withOpacity(0.05),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  'Регулировка интенсивности',
                  overflow: TextOverflow.ellipsis,
                  style: BrandText.sTitle,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    _currentIntensity,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                    style: BrandText.sRed,
                  ),
                  const SizedBox(width: 4.0),
                  const Icon(
                    Icons.arrow_forward_ios_outlined,
                    color: BrandColor.kText,
                    size: 16.0,
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showIntensityDialog(BuildContext context) {
    String selectedIntensity = _currentIntensity;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Интенсивность'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildIntensityOption(
                    context,
                    'Низкий',
                    selectedIntensity == 'Низкий',
                        () {
                      setState(() {
                        selectedIntensity = 'Низкий';
                      });
                    },
                  ),
                  _buildIntensityOption(
                    context,
                    'Средний',
                    selectedIntensity == 'Средний',
                        () {
                      setState(() {
                        selectedIntensity = 'Средний';
                      });
                    },
                  ),
                  _buildIntensityOption(
                    context,
                    'Высокий',
                    selectedIntensity == 'Высокий',
                        () {
                      setState(() {
                        selectedIntensity = 'Высокий';
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Отмена'),
                ),
                TextButton(
                  onPressed: () async {
                    await _saveIntensity(selectedIntensity);
                    Navigator.of(context).pop();
                    _showSavedMessage(context, 'Интенсивность установлена: $selectedIntensity');
                  },
                  child: const Text('Сохранить'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildIntensityOption(
      BuildContext context,
      String title,
      bool isSelected,
      VoidCallback onTap,
      ) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? BrandColor.kRed : Colors.grey,
            ),
            const SizedBox(width: 12.0),
            Text(
              title,
              style: TextStyle(
                fontSize: 16.0,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? BrandColor.kText : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSavedMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  VoidCallback? _getOnTapForItem(BuildContext context, ItemData item) {
    // Визначаємо дію для кожного пункту меню
    switch (item.title) {
      case 'Обратная связь':
        return () => _launchUrl('https://magic-motion.icu/');
      case 'О нас':
        return () => _launchUrl('https://magic-motion.icu/');
      case 'Помощь':
        return () => _launchUrl('https://magic-motion.icu/');
      case 'Язык':
        return () => _showDialog(context, 'Язык', 'Функция в разработке');
      case 'FAQ':
        return () => _showDialog(context, 'FAQ', 'Функция в разработке');
      case 'Уведомления':
        return () => _showDialog(context, 'Уведомления', 'Функция в разработке');
      case 'Контактная поддержка':
        return () => _showDialog(context, 'Контактная поддержка', 'Функция в разработке');
      case 'Политика конфиденциальности':
        return () => _showDialog(context, 'Политика конфиденциальности', 'Функция в разработке');
      case 'Условия использования':
        return () => _showDialog(context, 'Условия использования', 'Функция в разработке');
      default:
        return () => _showDialog(context, item.title, 'Функция в разработке');
    }
  }

  Future<void> _launchUrl(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      print('Не удалось открыть ссылку: $url');
    }
  }

  Widget _buildRow(BuildContext context, ItemData item, {VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 40.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8.0),
        splashColor: BrandColor.kRed.withOpacity(0.1),
        highlightColor: BrandColor.kRed.withOpacity(0.05),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  item.title,
                  overflow: TextOverflow.ellipsis,
                  style: BrandText.sTitle,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (item.value.isNotEmpty) Text(
                    item.value,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                    style: BrandText.sRed,
                  ),
                  const SizedBox(width: 4.0),
                  const Icon(
                    Icons.arrow_forward_ios_outlined,
                    color: BrandColor.kText,
                    size: 16.0,
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
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
              'Настройки',
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