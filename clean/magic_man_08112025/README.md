# Magic Man

Розширений мобільний додаток для управління пристроями та даними з інтеграцією AWS S3.

## Опис проекту

Magic Man - це Flutter додаток з розширеним функціоналом для моніторингу, управління пристроями та обміну даними. Проект використовує Firebase для основного функціоналу та AWS S3 для зберігання файлів.

## Зв'язок з іншими проектами

Цей проект є частиною екосистеми Magic і використовує спільний Firebase проект з:
- `magic_control_08112025` - базовий мобільний додаток для керування
- `magic_dashboard_08112025` - веб-дашборд для моніторингу

**Унікальні особливості:**
- Інтеграція з AWS S3 для зберігання великих файлів
- Розширений функціонал моніторингу
- Робота з геолокацією
- Управління контактами та встановленими додатками

## Передумови

Перед початком роботи переконайтеся, що у вас встановлено:

- Flutter SDK (версія 3.3.0 або вище)
- Dart SDK
- Android Studio / Xcode (для мобільної розробки)
- Firebase CLI
- Node.js (для Firebase CLI)
- AWS CLI (для налаштування S3)
- AWS облікові дані (Access Key ID та Secret Access Key)

### Перевірка середовища

Запустіть команду для перевірки налаштування Flutter:

```bash
flutter doctor
```

Переконайтеся, що всі необхідні компоненти встановлені та налаштовані правильно.

## Налаштування Firebase

### 1. Створення проекту в Firebase Console

1. Перейдіть на [Firebase Console](https://console.firebase.google.com/)
2. Використайте існуючий проект Magic (спільний з іншими додатками)
3. Додайте Android та/або iOS додаток до проекту
4. Завантажте конфігураційні файли:
   - `google-services.json` для Android (розмістіть в `android/app/`)
   - `GoogleService-Info.plist` для iOS (розмістіть в `ios/Runner/`)

### 2. Увімкнення необхідних сервісів Firebase

В Firebase Console увімкніть наступні сервіси:
- **Authentication** (Email/Password, Google, Phone)
- **Cloud Firestore** (база даних)
- **Realtime Database**
- **Firebase Storage** (для файлів)
- **Cloud Functions** (якщо потрібні серверні операції)

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
cd magic_man_08112025

# Встановіть залежності
flutter pub get

# Налаштування Firebase для Flutter
flutterfire configure
```

Оберіть ваш Firebase проект Magic зі списку та платформи (Android, iOS), які ви хочете підтримувати.

Ця команда створить або оновить файл `lib/firebase_options.dart` з налаштуваннями для вашого проекту.

## Налаштування AWS S3

### 1. Створення S3 Bucket

1. Перейдіть в [AWS Console](https://console.aws.amazon.com/)
2. Відкрийте сервіс S3
3. Створіть новий bucket:
   - Оберіть унікальну назву (наприклад, `magic-man-storage`)
   - Виберіть регіон (найближчий до ваших користувачів)
   - Налаштуйте параметри доступу (Block all public access або налаштуйте політику)

### 2. Налаштування IAM User

1. Перейдіть в IAM → Users → Create user
2. Створіть нового користувача для додатку
3. Надайте права доступу до S3:
   - Прикріпіть політику `AmazonS3FullAccess` або створіть кастомну політику
4. Створіть Access Key:
   - Security credentials → Create access key
   - Збережіть `Access Key ID` та `Secret Access Key`

### 3. Встановлення AWS CLI (опціонально)

```bash
# macOS
brew install awscli

# Або через pip
pip3 install awscli

# Налаштування AWS CLI
aws configure
```

Введіть ваші облікові дані:
- AWS Access Key ID
- AWS Secret Access Key
- Default region name (наприклад, `us-east-1`)
- Default output format: `json`

### 4. Конфігурація AWS S3 в додатку

Створіть файл `lib/config/aws_config.dart` (якщо він не існує):

```dart
class AWSConfig {
  static const String bucketName = 'your-bucket-name';
  static const String region = 'us-east-1';
  static const String accessKeyId = 'YOUR_ACCESS_KEY_ID';
  static const String secretAccessKey = 'YOUR_SECRET_ACCESS_KEY';
  
  // Або використовуйте AWS Cognito для безпечнішої аутентифікації
  static const String identityPoolId = 'your-cognito-identity-pool-id';
}
```

**ВАЖЛИВО:** Не зберігайте облікові дані безпосередньо в коді для production. Використовуйте:
- AWS Cognito Identity Pool
- Environment variables
- Secure storage (flutter_secure_storage)

### 5. Налаштування CORS для S3 Bucket

В AWS Console → S3 → ваш bucket → Permissions → CORS configuration:

```json
[
    {
        "AllowedHeaders": ["*"],
        "AllowedMethods": ["GET", "PUT", "POST", "DELETE"],
        "AllowedOrigins": ["*"],
        "ExposeHeaders": ["ETag"]
    }
]
```

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

## Генерація іконок

Проект використовує `flutter_launcher_icons` для генерації іконок:

```bash
# Генерація іконок
flutter pub run flutter_launcher_icons
```

Налаштування в `pubspec.yaml`:
- Іконка знаходиться в `assets/images/icon.png`
- Мінімальний SDK для Android: 23

## Структура проекту

```
lib/
├── main.dart                 # Точка входу додатку
├── constant.dart             # Константи додатку
├── menu_items.dart           # Пункти меню
├── alarm/                    # Сигнали та нагадування
├── config/                   # Конфігурації (Firebase, AWS)
├── helpers/                  # Допоміжні класи
├── model/                    # Моделі даних
├── screens/                  # Екрани додатку
├── storage/                  # Локальне сховище
├── style/                    # Стилі та теми
├── utils/                    # Утиліти
└── widgets/                  # Переиспользуємі віджети

assets/
└── images/                   # Зображення та іконки
```

## Основні залежності

### Firebase
- `firebase_core` - ядро Firebase
- `firebase_auth` - аутентифікація
- `cloud_firestore` - Firestore база даних
- `firebase_storage` - сховище файлів
- `flutter_firebase_chat_core` - чат

### AWS & HTTP
- `dio` - HTTP клієнт для роботи з AWS API

### Функціонал
- `geolocator` - геолокація
- `flutter_contacts` - робота з контактами
- `device_info_plus` - інформація про пристрій
- `installed_apps` - список встановлених додатків
- `flutter_downloader` - завантаження файлів
- `workmanager` - фонові задачі
- `permission_handler` - дозволи

### UI & UX
- `flutter_zoom_drawer` - висувне меню
- `provider` - state management
- `share_plus` - поширення контенту

## Налаштування дозволів

### Android (`android/app/src/main/AndroidManifest.xml`)

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.READ_CONTACTS" />
<uses-permission android:name="android.permission.WRITE_CONTACTS" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```

### iOS (`ios/Runner/Info.plist`)

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Потрібен доступ до геолокації</string>
<key>NSContactsUsageDescription</key>
<string>Потрібен доступ до контактів</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Потрібен доступ до фото</string>
```

## Робота з AWS S3 в додатку

### Приклад завантаження файлу на S3

```dart
import 'package:dio/dio.dart';

Future<void> uploadFileToS3(File file) async {
  final dio = Dio();
  
  // Генерація presigned URL через ваш backend або AWS SDK
  final uploadUrl = await getPresignedUrl(file.path);
  
  // Завантаження файлу
  await dio.put(
    uploadUrl,
    data: file.openRead(),
    options: Options(
      headers: {
        'Content-Type': 'application/octet-stream',
        'Content-Length': file.lengthSync(),
      },
    ),
  );
}
```

## Налаштування правил безпеки Firebase

Не забудьте налаштувати правила безпеки для Firestore та Storage в Firebase Console.

### Firestore Rules (приклад)
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    match /devices/{deviceId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
  }
}
```

## Можливі проблеми та рішення

### Помилка з дозволами на Android

Додайте необхідні дозволи в `AndroidManifest.xml` та запросіть їх динамічно через `permission_handler`.

### Помилка підключення до AWS S3

Перевірте:
1. Правильність облікових даних (Access Key, Secret Key)
2. CORS налаштування для bucket
3. IAM політики для користувача
4. Регіон bucket співпадає з конфігурацією

### Помилка при flutterfire configure

```bash
firebase login --reauth
dart pub global activate flutterfire_cli
flutterfire configure
```

### Помилки з градлом

```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
```

### Помилка з іконками

```bash
flutter pub run flutter_launcher_icons
flutter clean
flutter build apk
```

## Тестування AWS S3 з'єднання

```bash
# Перевірка доступу до bucket через AWS CLI
aws s3 ls s3://your-bucket-name/

# Завантаження тестового файлу
aws s3 cp test.txt s3://your-bucket-name/test.txt
```

## Best Practices для AWS S3

1. **Безпека:**
   - Використовуйте AWS Cognito замість прямих облікових даних
   - Налаштуйте bucket policies правильно
   - Увімкніть versioning для важливих файлів

2. **Продуктивність:**
   - Використовуйте CloudFront CDN для швидкого доступу
   - Налаштуйте lifecycle policies для автоматичного видалення старих файлів
   - Використовуйте multipart upload для великих файлів

3. **Вартість:**
   - Моніторте використання через AWS CloudWatch
   - Налаштуйте lifecycle переходи (Standard → Glacier)
   - Видаляйте непотрібні файли

## Підтримка

Для питань та проблем зверніться до команди розробників проекту Magic.

## Корисні посилання

- [Firebase Documentation](https://firebase.google.com/docs)
- [AWS S3 Documentation](https://docs.aws.amazon.com/s3/)
- [Flutter Documentation](https://flutter.dev/docs)
- [FlutterFire Documentation](https://firebase.flutter.dev/)

## Ліцензія

Приватний проект. Всі права захищені.
