# Firebase Push Notifications — Flutter Demo

Учебное приложение для демонстрации работы с push-уведомлениями Firebase Cloud Messaging (FCM) во Flutter.

---

## Содержание

1. [Что делает приложение](#что-делает-приложение)
2. [Предварительные требования](#предварительные-требования)
3. [Шаг 1 — Создание проекта в Firebase Console](#шаг-1--создание-проекта-в-firebase-console)
4. [Шаг 2 — Добавление Android-приложения в Firebase](#шаг-2--добавление-android-приложения-в-firebase)
5. [Шаг 3 — Добавление iOS-приложения в Firebase](#шаг-3--добавление-ios-приложения-в-firebase)
6. [Шаг 4 — Настройка Flutter-проекта](#шаг-4--настройка-flutter-проекта)
7. [Шаг 5 — Разбор кода приложения](#шаг-5--разбор-кода-приложения)
8. [Шаг 6 — Запуск и тестирование](#шаг-6--запуск-и-тестирование)
9. [Шаг 7 — Отправка тестового уведомления из Firebase Console](#шаг-7--отправка-тестового-уведомления-из-firebase-console)
10. [Шаг 8 — Отправка уведомления через REST API (cURL)](#шаг-8--отправка-уведомления-через-rest-api-curl)
11. [Как работают push-уведомления — теория](#как-работают-push-уведомления--теория)
12. [Три состояния приложения](#три-состояния-приложения)
13. [Частые ошибки и их решения](#частые-ошибки-и-их-решения)

---

## Что делает приложение

- Инициализирует Firebase
- Запрашивает разрешение на отправку уведомлений
- Получает и отображает FCM-токен устройства (можно скопировать)
- Показывает уведомления в трёх состояниях: **foreground**, **background**, **terminated**
- Ведёт историю полученных уведомлений прямо в интерфейсе
- Показывает локальные уведомления в шторке, когда приложение открыто (foreground)

---

## Предварительные требования

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (версия 3.11+)
- Аккаунт [Firebase](https://console.firebase.google.com/)
- Для Android: Android Studio + эмулятор **с Google Play Services** (или реальное устройство)
- Для iOS: Xcode 15+, реальное устройство (push не работают на симуляторе), аккаунт Apple Developer

---

## Шаг 1 — Создание проекта в Firebase Console

### 1.1. Откройте Firebase Console

Перейдите по ссылке: [https://console.firebase.google.com/](https://console.firebase.google.com/)

### 1.2. Создайте новый проект

1. Нажмите **"Add project"** (Создать проект)
2. Введите название проекта, например: `kumbel-push-demo`
3. На шаге Google Analytics — можете отключить (для учебного проекта не нужен)
4. Нажмите **"Create project"**
5. Дождитесь создания и нажмите **"Continue"**

---

## Шаг 2 — Добавление Android-приложения в Firebase

### 2.1. Добавьте Android-приложение

1. На главной странице проекта нажмите иконку **Android** (робот)
2. В поле **"Android package name"** введите:
   ```
   com.example.kumbel_push_notifications
   ```
   > Это значение из файла `android/app/build.gradle.kts` → `applicationId`
3. Поле **"App nickname"** — можно оставить пустым
4. Поле **"Debug signing certificate SHA-1"** — для тестирования можно пропустить
5. Нажмите **"Register app"**

### 2.2. Скачайте google-services.json

1. На следующем шаге Firebase предложит скачать файл **`google-services.json`**
2. **Скачайте** этот файл
3. **Переместите** его в папку:
   ```
   android/app/google-services.json
   ```

   Структура должна выглядеть так:
   ```
   android/
   ├── app/
   │   ├── build.gradle.kts
   │   ├── google-services.json   ← сюда!
   │   └── src/
   ├── build.gradle.kts
   └── settings.gradle.kts
   ```

4. Нажмите **"Next"** → **"Next"** → **"Continue to console"**

### 2.3. Что уже настроено в проекте (не нужно делать вручную)

В этом проекте Android-конфигурация уже подготовлена:

**`android/settings.gradle.kts`** — добавлен плагин Google Services:
```kotlin
plugins {
    // ...
    id("com.google.gms.google-services") version "4.4.2" apply false
}
```

**`android/app/build.gradle.kts`** — плагин подключён:
```kotlin
plugins {
    // ...
    id("com.google.gms.google-services")
}
```

**`android/app/build.gradle.kts`** — minSdk установлен в 21:
```kotlin
minSdk = 21
```

---

## Шаг 3 — Добавление iOS-приложения в Firebase

### 3.1. Добавьте iOS-приложение

1. На главной странице проекта в Firebase Console нажмите **"Add app"** → выберите **iOS** (яблоко)
2. В поле **"Apple bundle ID"** введите:
   ```
   com.example.kumbelPushNotifications
   ```
   > Это значение из `ios/Runner.xcodeproj/project.pbxproj` → `PRODUCT_BUNDLE_IDENTIFIER`
3. Нажмите **"Register app"**

### 3.2. Скачайте GoogleService-Info.plist

1. Скачайте файл **`GoogleService-Info.plist`**
2. Откройте проект в Xcode:
   ```bash
   open ios/Runner.xcworkspace
   ```
3. Перетащите `GoogleService-Info.plist` в папку **Runner** в Xcode
4. В диалоге убедитесь, что стоит галочка **"Copy items if needed"** и target **Runner** выбран
5. Нажмите **"Finish"**

   Файл должен оказаться здесь:
   ```
   ios/
   ├── Runner/
   │   ├── AppDelegate.swift
   │   ├── GoogleService-Info.plist   ← сюда!
   │   └── ...
   ```

### 3.3. Включите Push Notifications в Xcode

1. Откройте проект в Xcode (`open ios/Runner.xcworkspace`)
2. Выберите target **Runner** в левой панели
3. Перейдите на вкладку **"Signing & Capabilities"**
4. Нажмите **"+ Capability"**
5. Найдите и добавьте:
   - **Push Notifications**
   - **Background Modes** → поставьте галочку **"Remote notifications"**

### 3.4. Настройте APNs ключ в Firebase

Для iOS push-уведомления проходят через Apple Push Notification service (APNs). Firebase нужен ключ для связи с APNs.

1. Перейдите в [Apple Developer Console](https://developer.apple.com/account/resources/authkeys/list)
2. Нажмите **"Keys"** → **"+"**
3. Введите имя ключа, например: `FCM Push Key`
4. Поставьте галочку **"Apple Push Notifications service (APNs)"**
5. Нажмите **"Continue"** → **"Register"**
6. **Скачайте** `.p8` файл (это можно сделать только один раз!)
7. Запомните **Key ID** (отображается на странице ключа)
8. Запомните **Team ID** (показан в правом верхнем углу Apple Developer Console)

Теперь загрузите ключ в Firebase:

1. В Firebase Console → **Project Settings** (шестерёнка) → **Cloud Messaging**
2. В разделе **"Apple app configuration"** нажмите **"Upload"** рядом с APNs Authentication Key
3. Загрузите скачанный `.p8` файл
4. Введите **Key ID** и **Team ID**
5. Нажмите **"Upload"**

### 3.5. Что уже настроено в проекте (не нужно делать вручную)

**`ios/Runner/AppDelegate.swift`** — добавлена инициализация Firebase и регистрация APNs:
```swift
import FirebaseCore
import FirebaseMessaging

// В application(_:didFinishLaunchingWithOptions:):
FirebaseApp.configure()
UNUserNotificationCenter.current().delegate = self
application.registerForRemoteNotifications()

// Передача APNs токена в Firebase:
override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
) {
    Messaging.messaging().apnsToken = deviceToken
}
```

---

## Шаг 4 — Настройка Flutter-проекта

### 4.1. Установите зависимости

В проекте уже добавлены необходимые пакеты в `pubspec.yaml`:

```yaml
dependencies:
  firebase_core: ^3.12.1
  firebase_messaging: ^15.2.4
  flutter_local_notifications: ^18.0.1
```

Выполните команду для установки:

```bash
flutter pub get
```

### 4.2. (Опционально) Используйте FlutterFire CLI

Вместо ручного добавления `google-services.json` и `GoogleService-Info.plist` можно использовать FlutterFire CLI, который сделает всё автоматически:

```bash
# Установка FlutterFire CLI
dart pub global activate flutterfire_cli

# Конфигурация (выберите платформы и Firebase проект)
flutterfire configure
```

Эта команда:
- Скачает `google-services.json` для Android
- Скачает `GoogleService-Info.plist` для iOS
- Создаст файл `lib/firebase_options.dart` с конфигурацией

Если вы используете FlutterFire CLI, измените инициализацию в `main.dart`:
```dart
import 'firebase_options.dart';

// Вместо:
await Firebase.initializeApp();

// Используйте:
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
```

---

## Шаг 5 — Разбор кода приложения

### 5.1. Структура main.dart

Файл `lib/main.dart` содержит всю логику приложения. Разберём ключевые части:

### 5.2. Background handler (обработчик фоновых сообщений)

```dart
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('Background message: ${message.messageId}');
}
```

**Важно:**
- Это **top-level функция** (не метод класса!) — Flutter вызывает её в отдельном изоляте
- `@pragma('vm:entry-point')` — гарантирует, что tree-shaking не удалит функцию
- Нужна повторная инициализация `Firebase.initializeApp()`, т.к. это новый изолят
- Регистрируется один раз в `main()`:
  ```dart
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  ```

### 5.3. Notification Channel (Android)

```dart
const AndroidNotificationChannel _androidChannel = AndroidNotificationChannel(
  'high_importance_channel',
  'High Importance Notifications',
  description: 'Канал для важных уведомлений',
  importance: Importance.high,
);
```

На Android 8+ (API 26+) для показа уведомлений нужен **Notification Channel**. Importance.high обеспечивает звук и всплывающее окно.

### 5.4. Запрос разрешений

```dart
final settings = await messaging.requestPermission(
  alert: true,
  badge: true,
  sound: true,
);
```

- На **iOS** — показывает системный диалог запроса разрешения
- На **Android 13+** (API 33+) — тоже показывает диалог (`POST_NOTIFICATIONS` permission)
- На **Android < 13** — разрешение даётся автоматически

### 5.5. Получение FCM-токена

```dart
final token = await messaging.getToken();
```

FCM-токен — это уникальный идентификатор устройства для отправки push-уведомлений. Этот токен:
- Уникален для каждого устройства + приложения
- Может измениться (поэтому слушаем `onTokenRefresh`)
- Нужно отправлять на ваш сервер для таргетированной отправки

### 5.6. Обработка сообщений в foreground

```dart
FirebaseMessaging.onMessage.listen((message) {
  // Приложение открыто — сообщение приходит сюда
});
```

По умолчанию, когда приложение открыто, push-уведомление **НЕ показывается** в шторке. Поэтому мы используем `flutter_local_notifications` для показа локального уведомления:

```dart
_localNotifications.show(
  notification.hashCode,
  notification.title,
  notification.body,
  NotificationDetails(
    android: AndroidNotificationDetails(
      _androidChannel.id,
      _androidChannel.name,
      // ...
    ),
  ),
);
```

### 5.7. Обработка нажатия на уведомление

```dart
// Приложение было в background
FirebaseMessaging.onMessageOpenedApp.listen((message) { ... });

// Приложение было terminated (убито)
final initialMessage = await messaging.getInitialMessage();
```

---

## Шаг 6 — Запуск и тестирование

### Android

```bash
flutter run
```

Убедитесь, что:
- Файл `android/app/google-services.json` на месте
- Эмулятор имеет Google Play Services (используйте образ с "Google APIs")
- Или используйте реальное устройство

### iOS

```bash
flutter run --device-id <ваш_device_id>

# Или откройте в Xcode:
open ios/Runner.xcworkspace
# И запустите на реальном устройстве
```

Убедитесь, что:
- Файл `ios/Runner/GoogleService-Info.plist` на месте (добавлен через Xcode!)
- Push Notifications capability включён
- APNs ключ загружен в Firebase
- Запуск на **реальном устройстве** (push не работают на симуляторе)

---

## Шаг 7 — Отправка тестового уведомления из Firebase Console

### 7.1. Скопируйте FCM Token

1. Запустите приложение
2. На экране появится FCM Token — нажмите иконку копирования

### 7.2. Отправьте уведомление

1. Откройте [Firebase Console](https://console.firebase.google.com/) → ваш проект
2. В левом меню: **Engage** → **Messaging** (или **Cloud Messaging**)
3. Нажмите **"Create your first campaign"** → **"Firebase Notification messages"**
4. Заполните:
   - **Notification title**: `Привет из Firebase!`
   - **Notification text**: `Это тестовое push-уведомление`
5. Нажмите **"Send test message"**
6. В поле **"Add an FCM registration token"** вставьте скопированный токен
7. Нажмите **"+"** для добавления токена
8. Нажмите **"Test"**

### 7.3. Проверьте результат

- Если приложение **открыто (foreground)** — уведомление появится в списке с зелёной меткой "Foreground" и в шторке
- Если приложение **свёрнуто (background)** — уведомление появится в шторке. При нажатии на него приложение откроется, и уведомление появится в списке с оранжевой меткой "Background"
- Если приложение **убито (terminated)** — уведомление появится в шторке. При нажатии приложение запустится, и уведомление появится с красной меткой "Terminated"

---

## Шаг 8 — Отправка уведомления через REST API (cURL)

Для программной отправки можно использовать Firebase Cloud Messaging API v1.

### 8.1. Получите Server Key

**Вариант 1 — Legacy API (проще для тестирования):**

1. Firebase Console → Project Settings → Cloud Messaging
2. Скопируйте **Server key**

```bash
curl -X POST https://fcm.googleapis.com/fcm/send \
  -H "Authorization: key=YOUR_SERVER_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "to": "FCM_TOKEN_УСТРОЙСТВА",
    "notification": {
      "title": "Привет из cURL!",
      "body": "Отправлено через REST API"
    },
    "data": {
      "action": "open_profile",
      "user_id": "123"
    }
  }'
```

**Вариант 2 — FCM API v1 (рекомендуемый):**

Для этого нужен OAuth 2.0 Access Token. Проще всего использовать `gcloud`:

```bash
# Авторизация
gcloud auth login

# Получение токена
ACCESS_TOKEN=$(gcloud auth print-access-token)

# Отправка
curl -X POST \
  "https://fcm.googleapis.com/v1/projects/YOUR_PROJECT_ID/messages:send" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "message": {
      "token": "FCM_TOKEN_УСТРОЙСТВА",
      "notification": {
        "title": "Привет из FCM v1!",
        "body": "Отправлено через новый API"
      },
      "data": {
        "action": "open_profile",
        "user_id": "123"
      }
    }
  }'
```

---

## Как работают push-уведомления — теория

### Общая схема

```
┌─────────────┐      ┌─────────────────┐      ┌──────────────┐
│  Ваш сервер │ ───→ │  Firebase Cloud  │ ───→ │  Устройство  │
│  (Backend)  │      │  Messaging (FCM) │      │  (Android/   │
│             │      │                  │      │   iOS)       │
└─────────────┘      └─────────────────┘      └──────────────┘
      │                      │                        │
      │  HTTP запрос         │  APNs (iOS)            │  Показ
      │  с токеном           │  FCM (Android)         │  уведомления
      │  устройства          │                        │
```

### Как это работает:

1. **Регистрация**: Приложение при запуске получает FCM-токен от Firebase
2. **Сохранение**: Токен отправляется на ваш бэкенд и сохраняется в базе данных
3. **Отправка**: Когда нужно отправить push, бэкенд делает HTTP-запрос к FCM API с токеном устройства
4. **Доставка**: FCM доставляет сообщение на устройство:
   - На Android — напрямую через FCM
   - На iOS — через Apple Push Notification service (APNs)
5. **Отображение**: Устройство показывает уведомление и/или передаёт данные в приложение

### Типы сообщений FCM

| Тип | Описание | Поведение |
|-----|----------|-----------|
| **Notification message** | Содержит `notification` (title, body) | Система сама показывает уведомление |
| **Data message** | Содержит только `data` | Приложение само решает, что делать |
| **Комбинированное** | `notification` + `data` | Система показывает + данные передаются |

---

## Три состояния приложения

| Состояние | Описание | Как обрабатывается |
|-----------|----------|-------------------|
| **Foreground** | Приложение открыто и видно на экране | `FirebaseMessaging.onMessage` — система НЕ показывает уведомление автоматически, нужно показать через `flutter_local_notifications` |
| **Background** | Приложение свёрнуто, но не убито | Система показывает уведомление. При нажатии → `FirebaseMessaging.onMessageOpenedApp` |
| **Terminated** | Приложение полностью закрыто | Система показывает уведомление. При нажатии → `FirebaseMessaging.instance.getInitialMessage()` |

### Визуальная диаграмма обработки:

```
Push-уведомление приходит
        │
        ├── Приложение в Foreground?
        │   └── Да → onMessage → показать через local_notifications
        │
        ├── Приложение в Background?
        │   └── Да → Система показывает уведомление
        │           └── Пользователь нажал → onMessageOpenedApp
        │
        └── Приложение Terminated?
            └── Да → Система показывает уведомление
                    └── Пользователь нажал → getInitialMessage()
```

---

## Частые ошибки и их решения

### 1. `google-services.json` не найден

```
Execution failed for task ':app:processDebugGoogleServices'.
File google-services.json is missing.
```

**Решение**: Скачайте `google-services.json` из Firebase Console и положите в `android/app/`.

### 2. `GoogleService-Info.plist` не найден (iOS)

```
[Firebase/Core][I-COR000012] Could not locate configuration file: 'GoogleService-Info.plist'.
```

**Решение**: Добавьте файл через Xcode (не просто копированием в файловую систему!).

### 3. Push не приходят на iOS симуляторе

**Это нормально.** Push-уведомления на iOS работают только на реальных устройствах.

### 4. Нет диалога запроса разрешения на Android

На Android < 13 разрешение на уведомления даётся автоматически. Диалог появляется только на Android 13+ (API 33+).

### 5. Токен = null

Возможные причины:
- Нет интернета
- Google Play Services не установлены (на эмуляторе)
- `google-services.json` / `GoogleService-Info.plist` невалидные
- На iOS: не загружен APNs ключ в Firebase

### 6. Foreground уведомления не показываются в шторке

По умолчанию FCM **не показывает** уведомление, когда приложение открыто. Для этого используется пакет `flutter_local_notifications` — он вручную создаёт локальное уведомление.

### 7. `MissingPluginException`

```bash
flutter clean
flutter pub get
```

Для iOS также выполните:
```bash
cd ios && pod install && cd ..
```

### 8. Background handler не вызывается

Убедитесь, что:
- Функция-обработчик объявлена на **верхнем уровне** (не внутри класса)
- Используется аннотация `@pragma('vm:entry-point')`
- `Firebase.initializeApp()` вызывается внутри обработчика

---

## Полезные ссылки

- [firebase_messaging (pub.dev)](https://pub.dev/packages/firebase_messaging)
- [flutter_local_notifications (pub.dev)](https://pub.dev/packages/flutter_local_notifications)
- [Firebase Cloud Messaging docs](https://firebase.google.com/docs/cloud-messaging)
- [FlutterFire — Cloud Messaging](https://firebase.flutter.dev/docs/messaging/overview)
