# Magic Dashboard

Веб-дашборд для моніторингу та управління системою Magic.

## Опис проекту

Magic Dashboard - це Flutter веб-додаток для моніторингу пристроїв, користувачів та даних системи Magic. Проект підтримує багато платформ та може бути задеплоєний на Firebase Hosting.

## Зв'язок з іншими проектами

Цей проект є частиною екосистеми Magic і використовує спільний Firebase проект з:
- `magic_control_08112025` - мобільний додаток для керування
- `magic_man_08112025` - розширений мобільний додаток

## Передумови

Перед початком роботи переконайтеся, що у вас встановлено:

- Flutter SDK (версія 3.3.0 або вище)
- Dart SDK
- Firebase CLI
- Node.js (для Firebase CLI)
- Веб-браузер (Chrome рекомендовано для розробки)

### Перевірка середовища

Запустіть команду для перевірки налаштування Flutter:

```bash
flutter doctor
```

Переконайтеся, що підтримка веб-платформи увімкнена:

```bash
flutter config --enable-web
flutter doctor
```

## Налаштування Firebase

### 1. Створення проекту в Firebase Console

1. Перейдіть на [Firebase Console](https://console.firebase.google.com/)
2. Використайте існуючий проект Magic (спільний з іншими додатками екосистеми)
3. Додайте веб-додаток до проекту:
   - Натисніть "Add app" → виберіть веб-іконку
   - Зареєструйте додаток з назвою "Magic Dashboard"
   - Скопіюйте конфігурацію Firebase (буде потрібна для ініціалізації)

### 2. Увімкнення необхідних сервісів Firebase

В Firebase Console увімкніть наступні сервіси:
- **Authentication** (Email/Password, Google)
- **Cloud Firestore** (база даних)
- **Realtime Database**
- **Firebase Storage** (для файлів)
- **Firebase Hosting** (для розгортання веб-додатку)

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
cd magic_dashboard_08112025

# Встановіть залежності
flutter pub get

# Налаштування Firebase для Flutter
flutterfire configure
```

Оберіть ваш Firebase проект Magic зі списку та платформу **web**.

Ця команда створить або оновить файл `lib/firebase_options.dart` з налаштуваннями для вашого проекту.

### 6. Ініціалізація Firebase Hosting

```bash
# Ініціалізація hosting в проекті
firebase init hosting
```

При ініціалізації:
- Виберіть існуючий проект Magic
- Public directory: введіть `build/web`
- Configure as single-page app: `Yes`
- Set up automatic builds with GitHub: `No` (або `Yes` якщо потрібна CI/CD)
- Overwrite index.html: `No`

Це створить файл `firebase.json` з налаштуваннями хостингу.

## Встановлення залежностей

```bash
flutter pub get
```

## Запуск проекту

### Режим розробки (локально)

```bash
# Запуск веб-сервера розробки
flutter run -d chrome

# Або для будь-якого браузера
flutter run -d web-server
```

Додаток буде доступний за адресою `http://localhost:xxxxx`

## Збірка та деплой на Firebase Hosting

### 1. Збірка веб-додатку

```bash
# Збірка для продакшену
flutter build web --release
```

Збудовані файли будуть в директорії `build/web/`

### 2. Тестування збірки локально (опціонально)

```bash
# Запуск локального Firebase сервера
firebase serve --only hosting
```

Відкрийте `http://localhost:5000` для перевірки збірки.

### 3. Деплой на Firebase Hosting

```bash
# Деплой на Firebase Hosting
firebase deploy --only hosting
```

Після успішного деплою ви отримаєте URL вашого додатку, наприклад:
```
https://your-project-id.web.app
https://your-project-id.firebaseapp.com
```

### 4. Налаштування кастомного домену (опціонально)

1. Перейдіть в Firebase Console → Hosting
2. Натисніть "Add custom domain"
3. Введіть ваш домен та слідуйте інструкціям для налаштування DNS

## Структура проекту

```
lib/
├── main.dart                 # Точка входу додатку
├── control/                  # Контролери
├── data/                     # Дані та константи
├── helpers/                  # Допоміжні класи
├── model/                    # Моделі даних
├── screen/                   # Екрани додатку
├── services/                 # Сервіси (API, Firebase)
├── style/                    # Стилі та теми
└── widgets/                  # Переиспользуємі віджети

web/
├── index.html               # HTML шаблон
├── manifest.json            # PWA маніфест
└── icons/                   # Іконки PWA

firebase.json                # Конфігурація Firebase
```

## Основні залежності

- `firebase_core` - ядро Firebase
- `firebase_auth` - аутентифікація
- `cloud_firestore` - Firestore база даних
- `firebase_storage` - сховище файлів
- `provider` - state management
- `flutter_map` / `flutter_osm_plugin` - карти

## Конфігурація Firebase Hosting

Приклад `firebase.json`:

```json
{
  "hosting": {
    "public": "build/web",
    "ignore": [
      "firebase.json",
      "**/.*",
      "**/node_modules/**"
    ],
    "rewrites": [
      {
        "source": "**",
        "destination": "/index.html"
      }
    ],
    "headers": [
      {
        "source": "**/*.@(jpg|jpeg|gif|png|svg|webp)",
        "headers": [
          {
            "key": "Cache-Control",
            "value": "max-age=7200"
          }
        ]
      }
    ]
  }
}
```

## Оновлення додатку на хостингу

Після внесення змін в код:

```bash
# 1. Зберіть новий білд
flutter build web --release

# 2. Деплой оновлення
firebase deploy --only hosting
```

## Налаштування правил безпеки Firebase

Налаштуйте правила безпеки для Firestore та Storage в Firebase Console:

### Firestore Rules (приклад)
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

### Storage Rules (приклад)
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /{allPaths=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

## Можливі проблеми та рішення

### Помилка при збірці веб-додатку

Очистіть кеш та перезберіть:

```bash
flutter clean
flutter pub get
flutter build web --release
```

### Помилка CORS при роботі з Firebase

Переконайтеся, що домени додані до whitelist в Firebase Console → Authentication → Settings → Authorized domains.

### Помилка при firebase deploy

Переконайтеся, що ви авторизовані та маєте права на проект:

```bash
firebase login
firebase projects:list
firebase use your-project-id
```

### Білий екран після деплою

Перевірте консоль браузера на помилки. Можливо потрібно:
1. Очистити кеш браузера
2. Перевірити правильність конфігурації Firebase
3. Переконатися, що файл `lib/firebase_options.dart` правильно налаштований

## Перегляд логів Firebase Hosting

```bash
# Перегляд логів
firebase hosting:channel:list

# Відкат до попередньої версії (якщо потрібно)
firebase hosting:clone SOURCE_SITE_ID:SOURCE_CHANNEL_ID TARGET_SITE_ID:live
```

## CI/CD (опціонально)

Для автоматичного деплою можна налаштувати GitHub Actions:

1. В Firebase Console отримайте токен:
```bash
firebase login:ci
```

2. Додайте токен до GitHub Secrets (FIREBASE_TOKEN)

3. Створіть `.github/workflows/deploy.yml` з автоматичним деплоєм

## Підтримка

Для питань та проблем зверніться до команди розробників проекту Magic.

## Ліцензія

Приватний проект. Всі права захищені.
