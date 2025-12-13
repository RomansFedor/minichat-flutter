# НАЛАШТУВАННЯ FIREBASE ДЛЯ FLAVORS

## ⚠️ ВИПРАВЛЕННЯ ЗРОБЛЕНО

Тимчасово видалено `applicationIdSuffix` з dev та staging flavors, щоб всі flavors використовували один package name `com.example.chat1`.

Це дозволяє використовувати один `google-services.json` для всіх середовищ.

---

## 📋 ЯКЩО ПОТРІБНО ОКРЕМІ PACKAGE NAMES

Якщо вам потрібно, щоб кожен flavor мав свій унікальний package name (щоб встановлювати всі три версії одночасно на пристрої), виконайте:

### Крок 1: Додати Android Apps у Firebase Console

1. Перейдіть у Firebase Console: https://console.firebase.google.com
2. Виберіть проєкт `minichat-5fef6`
3. Перейдіть у **Project Settings** → **Your apps**
4. Натисніть **Add app** → **Android**

#### Додати Dev app:
- **Package name:** `com.example.chat1.dev`
- **App nickname:** `MiniChat Dev` (опціонально)
- Завантажте `google-services.json`

#### Додати Staging app:
- **Package name:** `com.example.chat1.staging`
- **App nickname:** `MiniChat Staging` (опціонально)
- Завантажте `google-services.json`

### Крок 2: Об'єднати google-services.json

Після додавання обох apps, Firebase надасть окремі `google-services.json` файли. Потрібно об'єднати їх в один файл.

Структура об'єднаного файлу:

```json
{
  "project_info": {
    "project_number": "626864770589",
    "project_id": "minichat-5fef6",
    "storage_bucket": "minichat-5fef6.firebasestorage.app"
  },
  "client": [
    {
      "client_info": {
        "mobilesdk_app_id": "1:626864770589:android:7ceec97f224c2bea6b80f4",
        "android_client_info": {
          "package_name": "com.example.chat1"
        }
      },
      ...
    },
    {
      "client_info": {
        "mobilesdk_app_id": "1:626864770589:android:XXXXX",
        "android_client_info": {
          "package_name": "com.example.chat1.dev"
        }
      },
      ...
    },
    {
      "client_info": {
        "mobilesdk_app_id": "1:626864770589:android:YYYYY",
        "android_client_info": {
          "package_name": "com.example.chat1.staging"
        }
      },
      ...
    }
  ],
  "configuration_version": "1"
}
```

### Крок 3: Повернути applicationIdSuffix

Після оновлення `google-services.json`, поверніть у `android/app/build.gradle.kts`:

```kotlin
create("dev") {
    dimension = "environment"
    applicationIdSuffix = ".dev"  // ← повернути
    versionNameSuffix = "-dev"
    resValue("string", "app_name", "MiniChat Dev")
}

create("staging") {
    dimension = "environment"
    applicationIdSuffix = ".staging"  // ← повернути
    versionNameSuffix = "-stg"
    resValue("string", "app_name", "MiniChat Staging")
}
```

---

## ✅ ПОТОЧНИЙ СТАН

Наразі всі flavors використовують один package name `com.example.chat1`, що дозволяє:
- ✅ Використовувати один `google-services.json`
- ✅ Легко збирати та тестувати різні flavors
- ✅ Не потрібно додаткових налаштувань Firebase

**Недолік:** Не можна встановити всі три версії одночасно на одному пристрої (оскільки package name однаковий).

Для лабораторної роботи цього достатньо, оскільки головне - продемонструвати роботу з різними середовищами через flavors та змінні середовища.

---

**Підсумок:** Тимчасове рішення застосовано. Якщо потрібні окремі package names - виконайте інструкції вище.

