class ItemData {
  final String title;
  final String value;
  bool? icon;
  ItemData({
    required this.title,
    required this.value,
    this.icon,
  });
}

List<ItemData> items = [
  ItemData(title: 'Обратная связь', value: ''),
  ItemData(title: 'О нас', value: ''),
  ItemData(title: 'Помощь', value: '')
];

List<ItemData> itemsSwitch = [
  ItemData(title: 'Регулировка фона', value: '', icon: true),
  ItemData(title: 'Управление световым\nиндикатором', value: '', icon: true),
  ItemData(
      title: 'Поверните телефон для\nвыключения вибрации',
      value: '',
      icon: true),
  ItemData(title: 'Уведомления Объвления', value: '', icon: true),
  ItemData(title: 'Защита данных', value: '', icon: true),
];
