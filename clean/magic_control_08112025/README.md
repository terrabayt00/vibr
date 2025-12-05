# Magic Control

Мобільний додаток для керування пристроями через Firebase.

## Опис проекту

Magic Control - це Flutter додаток для контролю та управління пристроями. Проект використовує Firebase для аутентифікації, зберігання даних та чату між користувачами.

## Зв'язок з іншими проектами

Цей проект є частиною екосистеми Magic і використовує спільний Firebase проект з:
- `magic_dashboard_08112025` - веб-дашборд для моніторингу
- `magic_man_08112025` - мобільний додаток з розширеним функціоналом

## Передумови

Перед початком роботи переконайтеся, що у вас встановлено:

- Flutter SDK (версія 3.8.1 або вище)
- Dart SDK
- Android Studio / Xcode (для мобільної розробки)
- Firebase CLI
- Node.js (для Firebase CLI)

### Перевірка середовища

Запустіть команду для перевірки налаштування Flutter:

```bash
flutter doctor
```

Переконайтеся, що всі необхідні компоненти встановлені та налаштовані правильно.

## Налаштування Firebase

### 1. Створення проекту в Firebase Console

1. Перейдіть на [Firebase Console](https://console.firebase.google.com/)
2. Створіть новий проект або використовуйте існуючий проект Magic
3. Додайте Android та/або iOS додаток до проекту
4. Завантажте конфігураційні файли:
   - `google-services.json` для Android (розмістіть в `android/app/`)
   - `GoogleService-Info.plist` для iOS (розмістіть в `ios/Runner/`)

### 2. Увімкнення необхідних сервісів Firebase

В Firebase Console увімкніть наступні сервіси:
- **Authentication** (Email/Password, Google)
- **Cloud Firestore** (база даних)
- **Realtime Database**
- **Firebase Storage** (для файлів та зображень)

### 3. Встановлення Firebase CLI

```bash
# Встановлення Firebase CLI
npm install -g firebase-tools

# Авторизація в Firebase
firebase login
```

### 4. Встановлення FlutterFire CLI

```bash
# Встановлення FlutterFire CLI
dart pub global activate flutterfire_cli
```

### 5. Ініціалізація Firebase в проекті

```bash
# Перейдіть в директорію проекту
cd magic_control_08112025

# Встановіть залежності
flutter pub get

# Налаштування Firebase для Flutter
flutterfire configure
```

Оберіть ваш Firebase проект зі списку та платформи (Android, iOS), які ви хочете підтримувати.

Ця команда створить або оновить файл `lib/firebase_options.dart` з налаштуваннями для вашого проекту.

## Встановлення залежностей

```bash
flutter pub get
```

## Запуск проекту

### Режим розробки

```bash
# Для Android
flutter run

# Для iOS
flutter run

# Для конкретного пристрою
flutter run -d <device_id>
```

### Збірка для продакшену

#### Android

```bash
# APK файл
flutter build apk --release

# App Bundle (рекомендовано для Google Play)
flutter build appbundle --release
```

Збудовані файли будуть доступні в:
- APK: `build/app/outputs/flutter-apk/app-release.apk`
- App Bundle: `build/app/outputs/bundle/release/app-release.aab`

#### iOS

```bash
flutter build ios --release
```

Після збірки відкрийте проект в Xcode для підписання та публікації:

```bash
open ios/Runner.xcworkspace
```

## Структура проекту

```
lib/
├── main.dart                 # Точка входу додатку
├── helper/                   # Допоміжні класи
│   ├── db_helper.dart       # Робота з базою даних
│   ├── device_helper.dart   # Управління пристроями
│   └── message_helper.dart  # Обробка повідомлень
├── model/                    # Моделі даних
│   ├── control_model.dart
│   ├── device_model.dart
│   ├── girl_model.dart
│   └── magic_user.dart
├── screens/                  # Екрани додатку
│   ├── chat/                # Чат функціонал
│   ├── control/             # Управління
│   └── home/                # Головний екран
├── style/                    # Стилі та теми
│   └── brand_color.dart
└── utils/                    # Утиліти
    └── file_utils.dart
```

## Основні залежності

- `firebase_core` - ядро Firebase
- `firebase_auth` - аутентифікація
- `cloud_firestore` - Firestore база даних
- `firebase_storage` - сховище файлів
- `flutter_firebase_chat_core` - чат функціонал
- `device_info_plus` - інформація про пристрій

## Налаштування правил безпеки Firebase

Не забудьте налаштувати правила безпеки для Firestore та Storage в Firebase Console, щоб захистити ваші дані.

## Можливі проблеми та рішення

### Помилка "google-services.json not found"

Переконайтеся, що файл `google-services.json` розміщений в `android/app/` директорії.

### Помилка при flutterfire configure

Переконайтеся, що Firebase CLI та FlutterFire CLI встановлені та ви авторизовані:

```bash
firebase login
dart pub global activate flutterfire_cli
```

### Помилки з градлом

Очистіть кеш та перезберіть проект:

```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
```

## Підтримка

Для питань та проблем зверніться до команди розробників проекту Magic.

## Ліцензія

Приватний проект. Всі права захищені.
