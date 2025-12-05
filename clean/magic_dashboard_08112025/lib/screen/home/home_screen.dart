import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:magic_dashbord/screen/home/components/block_content.dart';
import 'package:magic_dashbord/screen/home/components/footer_item.dart';
import 'package:magic_dashbord/screen/home/components/my_social_widget.dart';
import 'package:magic_dashbord/screen/login/login_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
                image: DecorationImage(
              image: AssetImage(
                'assets/images/room.jpg',
              ),
              fit: BoxFit.cover,
            )),
          ),
          Container(
            color: Colors.black54,
          ),
          Positioned(
              top: 50.0,
              right: 30.0,
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  ClipRRect(
                      borderRadius: BorderRadius.circular(12.0),
                      child: Image.asset('assets/images/room_r.jpg')),
                  Container(
                    width: 480.0,
                    decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(12.0)),
                    child: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        'Мебель в Москве',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white, fontSize: 36.0),
                      ),
                    ),
                  )
                ],
              )),
          Padding(
            padding: const EdgeInsets.fromLTRB(30.0, 30.0, 30.0, 0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.data_saver_off_outlined,
                        color: Colors.white,
                      ),
                      SizedBox(width: 8.0),
                      Text(
                        'Sofa Room: Мебель, созданная для вашего комфорта.',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 14.0,
                            fontWeight: FontWeight.normal),
                      ),
                    ],
                  ),
                  const SizedBox(height: 50.0),
                  const Text(
                    'Мечтаете о стильном и комфортном доме?',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 32.0,
                        fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    'Создайте уютную атмосферу в каждой комнате с помощью нашей высококачественной мебели!',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16.0,
                        fontWeight: FontWeight.normal),
                  ),
                  const BlockTextContent(title: 'Уютная гостиная:', data: [
                    'Мягкий диван, где вы сможете расслабиться после долгого дня.',
                    'Пушистый ковер, который добавит тепла и уюта.',
                    'Журнальный столик, на котором вы сможете разместить свои любимые журналы и книги.',
                    'Кресла, где вы сможете удобно расположиться с друзьями и близкими.',
                    'Телевизор, который обеспечит вам развлечения на любой вкус.'
                  ]),
                  const BlockTextContent(data: [
                    'Большая кровать, на которой вы сможете выспаться и зарядиться энергией на весь день.',
                    'Прикроватные тумбочки, где вы сможете хранить свои личные вещи.',
                    'Шкаф, где вы сможете разместить свою одежду и постельное белье.',
                    'Комод, который поможет вам организовать хранение вещей.',
                    'Туалетный столик, где вы сможете привести себя в порядок.',
                  ], title: 'Светлая спальня:'),
                  Container(
                    decoration: const BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        )),
                    child: Padding(
                      padding: const EdgeInsets.all(18.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Клиентам',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 18.0),
                              ),
                              FooterItem(
                                title: 'Магазины на карте',
                                link: 'https://mebel.ru/salons/map/',
                              ),
                              FooterItem(
                                title: 'Статьи',
                                link: 'https://mebel.ru/articles/',
                              ),
                            ],
                          ),
                          const Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 20.0),
                              FooterItem(
                                title: 'Карта сайта',
                                link: 'https://mebel.ru/sitemap/',
                              ),
                              FooterItem(
                                title: 'Доставка',
                                link: 'https://mebel.ru/delivery/',
                              ),
                            ],
                          ),
                          const Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 20.0),
                              FooterItem(
                                title: 'Оплата',
                                link: 'https://mebel.ru/payment/',
                              ),
                              FooterItem(
                                  title: 'Гарантия',
                                  link: 'https://mebel.ru/warranty/'),
                            ],
                          ),
                          const Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Сервис',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 18.0),
                              ),
                              FooterItem(
                                title: 'Реклама на сайте',
                                link: 'https://mebel.ru/advertising-site/',
                              ),
                              FooterItem(
                                title: 'Технические требования',
                                link: 'https://mebel.ru/tech-requirements.pdf',
                              ),
                            ],
                          ),
                          SizedBox(
                            width: 200.0,
                            child: Column(
                              children: [
                                const Text(
                                  'Присоединяйтесь',
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 18.0),
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    MySocialWidget(
                                      iconData: FontAwesomeIcons.vk,
                                      iconColor: Colors.white,
                                      link:
                                          'https://vk.com/mebelru_ru', //provide the link
                                    ),
                                    MySocialWidget(
                                      iconData: FontAwesomeIcons.pinterest,
                                      iconColor: Colors.white,
                                      link:
                                          'https://www.pinterest.ru/mebelmebelru/',
                                    ),
                                    MySocialWidget(
                                      iconData: FontAwesomeIcons.youtube,
                                      iconColor: Colors.white,
                                      link:
                                          'https://www.youtube.com/channel/UCxX6Ktp4JLQ3uv_ihWT68sg',
                                    ),
                                    MySocialWidget(
                                      iconData: FontAwesomeIcons.webflow,
                                      iconColor: Colors.white,
                                      link: 'https://dzen.ru/mebelru',
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8.0),
                                GestureDetector(
                                    onLongPress: () {
                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (_) =>
                                                  const LoginScreen()));
                                    },
                                    child: const SizedBox(
                                      height: 20.0,
                                      width: 50.0,
                                      //  color: Colors.white,
                                      child: Text(
                                        '',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ))
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
