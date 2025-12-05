# Magic Ecosystem

Комплексна система для управління пристроями та даними з використанням Firebase та AWS S3.

## Огляд проектів

Екосистема Magic складається з трьох взаємопов'язаних проектів, які використовують спільний Firebase проект:

### 📱 Magic Control (`magic_control_08112025`)
Базовий мобільний додаток для керування пристроями.

**Основні функції:**
- Аутентифікація користувачів через Firebase
- Управління пристроями
- Чат між користувачами
- Зберігання файлів у Firebase Storage

**Платформи:** Android, iOS

[📖 Детальна документація →](./magic_control_08112025/README.md)

---

### 🌐 Magic Dashboard (`magic_dashboard_08112025`)
Веб-дашборд для моніторингу та управління.

**Основні функції:**
- Веб-інтерфейс для моніторингу
- Управління пристроями та контактами
- Візуалізація на картах
- Експорт даних у CSV

**Платформи:** Web (Firebase Hosting), також підтримує Desktop (Windows, macOS, Linux)

**Live Demo:** https://sofa-demo.web.app

[📖 Детальна документація →](./magic_dashboard_08112025/README.md)

---

### 📲 Magic Man (`magic_man_08112025`)
Розширений мобільний додаток з інтеграцією AWS S3.

**Основні функції:**
- Весь функціонал Magic Control
- Інтеграція з AWS S3 для великих файлів
- Геолокація та відстеження
- Робота з контактами пристрою
- Список встановлених додатків
- Фонові завдання та нагадування

**Платформи:** Android, iOS

[📖 Детальна документація →](./magic_man_08112025/README.md)

---

## Швидкий старт

### Загальні передумови

Встановіть наступне програмне забезпечення:

1. **Flutter SDK** (версія 3.3.0+)
   ```bash
   # Перевірте версію
   flutter --version
   
   # Перевірте налаштування
   flutter doctor
   ```

2. **Firebase CLI**
   ```bash
   npm install -g firebase-tools
   firebase login
   ```

3. **FlutterFire CLI**
   ```bash
   dart pub global activate flutterfire_cli
   ```

4. **AWS CLI** (тільки для Magic Man)
   ```bash
   # macOS
   brew install awscli
   
   # Налаштування
   aws configure
   ```

### Налаштування Firebase (для всіх проектів)

1. **Створіть проект Firebase:**
   - Перейдіть на [Firebase Console](https://console.firebase.google.com/)
   - Створіть новий проект "Magic"

2. **Увімкніть сервіси:**
   - Authentication (Email/Password, Google)
   - Cloud Firestore
   - Realtime Database
   - Firebase Storage
   - Firebase Hosting (для Dashboard)

3. **Додайте платформи:**
   - Android apps (для Magic Control та Magic Man)
   - iOS apps (для Magic Control та Magic Man)
   - Web app (для Magic Dashboard)

### Ініціалізація проектів

#### Magic Control
```bash
cd magic_control_08112025
flutter pub get
flutterfire configure
flutter run
```

#### Magic Dashboard
```bash
cd magic_dashboard_08112025
flutter config --enable-web
flutter pub get
flutterfire configure
firebase init hosting
flutter run -d chrome
```

#### Magic Man
```bash
cd magic_man_08112025
flutter pub get
flutterfire configure
flutter run
```

---

## Архітектура системи

```
┌─────────────────────────────────────────────────────────┐
│                    Firebase Project                      │
│  ┌──────────────┬──────────────┬──────────────────────┐ │
│  │ Authentication│  Firestore   │  Realtime Database  │ │
│  └──────────────┴──────────────┴──────────────────────┘ │
│  ┌──────────────┬──────────────┬──────────────────────┐ │
│  │ Storage      │   Hosting    │   Cloud Functions   │ │
│  └──────────────┴──────────────┴──────────────────────┘ │
└─────────────────────────────────────────────────────────┘
           │                │                 │
           ▼                ▼                 ▼
    ┌──────────┐    ┌──────────┐      ┌──────────┐
    │  Magic   │    │  Magic   │      │  Magic   │
    │ Control  │    │Dashboard │      │   Man    │
    │ (Mobile) │    │  (Web)   │      │ (Mobile) │
    └──────────┘    └──────────┘      └──────────┘
                                             │
                                             ▼
                                      ┌──────────┐
                                      │  AWS S3  │
                                      │ Storage  │
                                      └──────────┘
```

---

## Структура проектів

```
clean/
├── README.md                        # Цей файл
├── magic_control_08112025/          # Мобільний додаток (контроль)
│   ├── README.md
│   ├── lib/
│   ├── android/
│   └── pubspec.yaml
├── magic_dashboard_08112025/        # Веб-дашборд
│   ├── README.md
│   ├── lib/
│   ├── web/
│   ├── firebase.json
│   └── pubspec.yaml
└── magic_man_08112025/              # Розширений мобільний додаток
    ├── README.md
    ├── lib/
    ├── android/
    ├── assets/
    └── pubspec.yaml
```

---

## Деплой

### Magic Control (Mobile App)

**Android:**
```bash
cd magic_control_08112025
flutter build appbundle --release
```
Файл для Google Play: `build/app/outputs/bundle/release/app-release.aab`

**iOS:**
```bash
flutter build ios --release
open ios/Runner.xcworkspace
```

### Magic Dashboard (Web)

**Деплой на Firebase Hosting:**
```bash
cd magic_dashboard_08112025
flutter build web --release
firebase deploy --only hosting
```

Додаток буде доступний на: `https://your-project-id.web.app`

### Magic Man (Mobile App)

**Android:**
```bash
cd magic_man_08112025
flutter pub run flutter_launcher_icons
flutter build appbundle --release
```

**iOS:**
```bash
flutter build ios --release
open ios/Runner.xcworkspace
```

---

## Налаштування правил безпеки

### Firestore Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Користувачі можуть читати та писати тільки свої дані
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Пристрої доступні всім авторизованим користувачам
    match /devices/{deviceId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
    
    // Чати доступні тільки учасникам
    match /rooms/{roomId} {
      allow read: if request.auth != null && 
                     request.auth.uid in resource.data.userIds;
      allow create: if request.auth != null;
    }
  }
}
```

### Storage Rules

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /users/{userId}/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    match /public/{allPaths=**} {
      allow read: if true;
      allow write: if request.auth != null;
    }
  }
}
```

---

## AWS S3 (Magic Man)

### Налаштування

1. **Створіть S3 Bucket:**
   - Увійдіть в [AWS Console](https://console.aws.amazon.com/)
   - Створіть bucket з унікальною назвою

2. **Створіть IAM User:**
   - Надайте права S3FullAccess
   - Збережіть Access Key та Secret Key

3. **Налаштуйте CORS:**
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

4. **Додайте конфігурацію в проект:**
   Створіть `lib/config/aws_config.dart` у Magic Man проекті

---

## Загальні команди

### Очищення проектів
```bash
# Очистити всі проекти
for dir in magic_*/; do
  cd "$dir"
  flutter clean
  cd ..
done
```

### Оновлення залежностей
```bash
# Оновити всі проекти
for dir in magic_*/; do
  cd "$dir"
  flutter pub get
  cd ..
done
```

### Запуск аналізу
```bash
# Аналіз коду для всіх проектів
for dir in magic_*/; do
  cd "$dir"
  flutter analyze
  cd ..
done
```

---

## Можливі проблеми та рішення

### 1. Firebase Configuration Issues

**Проблема:** `[core/no-app] No Firebase App '[DEFAULT]' has been created`

**Рішення:**
```bash
flutterfire configure
flutter clean
flutter pub get
```

### 2. Gradle Build Failed (Android)

**Рішення:**
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
```

### 3. Xcode Build Failed (iOS)

**Рішення:**
```bash
cd ios
pod deintegrate
pod install
cd ..
flutter clean
flutter build ios
```

### 4. Web Build Issues

**Рішення:**
```bash
flutter config --enable-web
flutter clean
flutter pub get
flutter build web --release
```

### 5. AWS S3 Connection Failed

**Перевірте:**
- Правильність Access Key та Secret Key
- CORS налаштування bucket
- IAM політики користувача
- Регіон bucket

---

## Корисні посилання

### Документація
- [Flutter Documentation](https://flutter.dev/docs)
- [Firebase Documentation](https://firebase.google.com/docs)
- [FlutterFire Documentation](https://firebase.flutter.dev/)
- [AWS S3 Documentation](https://docs.aws.amazon.com/s3/)

### Консолі
- [Firebase Console](https://console.firebase.google.com/)
- [AWS Console](https://console.aws.amazon.com/)
- [Google Play Console](https://play.google.com/console)
- [App Store Connect](https://appstoreconnect.apple.com/)

### Інструменти
- [Flutter DevTools](https://flutter.dev/docs/development/tools/devtools)
- [Firebase CLI Reference](https://firebase.google.com/docs/cli)
- [AWS CLI Reference](https://docs.aws.amazon.com/cli/)

---

## Команда розробників

Для питань та проблем зверніться до команди розробників проекту Magic.

## Ліцензія

Приватний проект. Всі права захищені.

---

**Версія документації:** 1.0  
**Остання оновлення:** 8 листопада 2025
