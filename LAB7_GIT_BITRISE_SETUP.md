# 📦 ЛАБОРАТОРНА РОБОТА №7: Git Repository та CI/CD з Bitrise

## 🎯 Мета роботи

Створити Git репозиторій для Flutter проекту MiniChat, опублікувати його на GitHub, інтегрувати з Bitrise.io та налаштувати автоматичну збірку та розгортання через Firebase App Distribution для Android платформи.

---

## 📋 ЗМІСТ

1. [Створення Git репозиторію](#1-створення-git-репозиторію)
2. [Публікація на GitHub](#2-публікація-на-github)
3. [Налаштування Bitrise.io](#3-налаштування-bitriseio)
4. [Налаштування Workflow для Android](#4-налаштування-workflow-для-android)
5. [Firebase App Distribution](#5-firebase-app-distribution)

---

## 1. СТВОРЕННЯ GIT РЕПОЗИТОРІЮ

### 1.1 Ініціалізація репозиторію

```bash
# Перевірка версії Git
git --version

# Ініціалізація репозиторію в поточній директорії
git init

# Перевірка статусу
git status
```

### 1.2 Налаштування .gitignore

Переконайтесь, що файл `.gitignore` містить необхідні виключення для Flutter проекту:

```
# Build artifacts
/build/
/android/app/debug/
/android/app/profile/
/android/app/release/

# Local configuration
/android/local.properties
/android/app/google-services.json

# IDE
.idea/
*.iml

# Dependencies
.pub/
.dart_tool/
.packages

# Firebase keys (якщо не потрібні в репозиторії)
# firebase_options.dart можна залишити або виключити
```

### 1.3 Перший коміт

```bash
# Додавання всіх файлів до індексу
git add .

# Створення першого коміту
git commit -m "Initial commit: MiniChat Flutter project

- Firebase integration (Auth, Firestore, Analytics, Crashlytics)
- BLoC state management
- Chat and Contacts features
- SharedPreferences for local storage"

# Перевірка історії
git log --oneline
```

---

## 2. ПУБЛІКАЦІЯ НА GITHUB

### 2.1 Створення репозиторію на GitHub

1. **Перейдіть на [GitHub.com](https://github.com)**
2. **Натисніть "New repository"** або перейдіть за посиланням: `https://github.com/new`
3. **Заповніть форму:**
   - **Repository name:** `minichat-flutter` (або будь-яка назва)
   - **Description:** `MiniChat - Flutter chat application with Firebase integration`
   - **Visibility:** Public або Private (на ваш вибір)
   - **НЕ створюйте README, .gitignore, або license** (вони вже є локально)

4. **Натисніть "Create repository"**

### 2.2 Підключення локального репозиторію до GitHub

```bash
# Додавання remote репозиторію
# Замініть YOUR_USERNAME та YOUR_REPO_NAME на ваші значення
git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO_NAME.git

# Перевірка remote
git remote -v

# Перейменування гілки на main (якщо потрібно)
git branch -M main

# Відправка коду на GitHub
git push -u origin main
```

### 2.3 Перевірка

Перейдіть на сторінку вашого репозиторію на GitHub та переконайтесь, що всі файли успішно завантажені.

---

## 3. НАЛАШТУВАННЯ BITRISE.IO

### 3.1 Створення облікового запису

1. **Перейдіть на [Bitrise.io](https://www.bitrise.io)**
2. **Натисніть "Sign up"**
3. **Оберіть "Sign up with GitHub"** (рекомендовано для зручності)
4. **Авторизуйте доступ до GitHub** (Bitrise отримає доступ до ваших репозиторіїв)

### 3.2 Додавання нового проекту

1. **На головній сторінці натисніть "Add new App"**
2. **Оберіть GitHub як джерело коду**
3. **Оберіть ваш репозиторій** `minichat-flutter` зі списку
4. **Натисніть "Next"**

### 3.3 Початкове налаштування Flutter-застосунку

#### Крок 1: Project Slug
- **Project slug:** автоматично заповнюється (наприклад, `minichat-flutter`)
- Натисніть "Next"

#### Крок 2: Setup Repository Access
- Оберіть **branch:** `main` (або `master`)
- Натисніть "Next"

#### Крок 3: Setup Project Type
- Оберіть **Project Type:** `Flutter`
- Bitrise автоматично визначить Flutter проект
- Натисніть "Next"

#### Крок 4: Validation
- Bitrise перевірить структуру проекту
- Переконайтесь, що всі перевірки успішні
- Натисніть "Next"

#### Крок 5: Register a Webhook
- Натисніть "Register a Webhook"
- Це дозволить Bitrise автоматично запускати збірки при push до репозиторію
- Натисніть "Next"

#### Крок 6: Setup SSH Key (опціонально)
- Якщо потрібен SSH доступ, налаштуйте ключ
- Або пропустіть цей крок
- Натисніть "Next"

### 3.4 Початковий Workflow

Після завершення налаштування, Bitrise створить базовий Workflow з наступними кроками:

1. **Activate SSH Key** - активація SSH ключа
2. **Git Clone Repository** - клонування репозиторію
3. **Do anything with Script step** - місце для кастомних скриптів
4. **Flutter Install** - встановлення Flutter SDK
5. **Flutter Test** - запуск тестів
6. **Flutter Build** - збірка застосунку

---

## 4. НАЛАШТУВАННЯ WORKFLOW ДЛЯ ANDROID

### 4.1 Створення кастомного Workflow

1. **Перейдіть в розділ "Workflows"** в вашому проекті
2. **Натисніть "Add workflow"** або клонуйте існуючий
3. **Назвіть workflow:** `android-build-and-distribute`

### 4.2 Додавання необхідних кроків

#### Крок 1: Activate SSH Key
- **Step ID:** `activate-ssh-key`
- Налаштування за замовчуванням

#### Крок 2: Git Clone Repository
- **Step ID:** `git-clone`
- Виберіть branch: `main`

#### Крок 3: Cache: Pull
- **Step ID:** `cache-pull`
- Це прискорює наступні збірки

#### Крок 4: Flutter Install
- **Step ID:** `flutter-installer`
- **Flutter version:** `3.24.0` (або актуальна версія)
- **Channel:** `stable`

#### Крок 5: Flutter Analyze
- **Step ID:** `flutter-analyze`
- Перевірка коду на помилки

#### Крок 6: Flutter Test (опціонально)
- **Step ID:** `flutter-test`
- Запуск unit та widget тестів

#### Крок 7: Install missing Android SDK components
- **Step ID:** `install-missing-android-tools`
- **Android SDK components:** `platform-tools,platforms;android-34,build-tools;34.0.0`

#### Крок 8: Set up Android signing
- **Step ID:** `android-signing-config`
- Цей крок налаштовується для production збірок
- Для тестових збірок можна використовувати debug signing

**Важливо:** Для production потрібно додати ключі в Bitrise Secrets:
- `BITRISEIO_ANDROID_KEYSTORE_URL` - URL до keystore файлу
- `BITRISEIO_ANDROID_KEYSTORE_PASSWORD` - пароль keystore
- `BITRISEIO_ANDROID_KEYSTORE_ALIAS` - alias ключа
- `BITRISEIO_ANDROID_KEYSTORE_PRIVATE_KEY_PASSWORD` - пароль приватного ключа

#### Крок 9: Flutter Build APK
- **Step ID:** `flutter-build`
- **Flutter project location:** `./` (корінь проекту)
- **Flutter build arguments:** `build apk --release`
- **Target file path:** `build/app/outputs/flutter-apk/app-release.apk`

#### Крок 10: Sign APK
- **Step ID:** `sign-apk`
- **APK path:** `$BITRISE_FLUTTER_APK_PATH` або `build/app/outputs/flutter-apk/app-release.apk`
- Використовує ключі з кроку 8

#### Крок 11: Deploy to Bitrise.io
- **Step ID:** `deploy-to-bitrise-io`
- Завантажує APK файл в Bitrise для завантаження

#### Крок 12: Cache: Push
- **Step ID:** `cache-push`
- Зберігає кеш для наступних збірок

---

## 5. FIREBASE APP DISTRIBUTION

### 5.1 Підготовка Firebase проекту

1. **Перейдіть в [Firebase Console](https://console.firebase.google.com)**
2. **Виберіть ваш проект:** `minichat-5fef6`
3. **Перейдіть в розділ "App Distribution"** (в меню зліва)
4. **Якщо це перший раз, натисніть "Get started"**

### 5.2 Створення Firebase Service Account

1. **Перейдіть в Firebase Console → Project Settings → Service Accounts**
2. **Натисніть "Generate new private key"**
3. **Збережіть JSON файл** (він потрібен для Bitrise)
4. **Важливо:** Збережіть цей файл безпечно, він містить приватний ключ

### 5.3 Додавання Firebase App Distribution в Bitrise Workflow

#### Крок: Firebase App Distribution

1. **У вашому Workflow після кроку "Sign APK" додайте новий крок**
2. **Знайдіть step:** `firebase-app-distribution`
3. **Або використайте:** `Fastlane` з плагіном `firebase_app_distribution`

#### Налаштування кроку Firebase App Distribution:

**Варіант 1: Використання власного step (якщо доступний)**

```yaml
- firebase-app-distribution:
    inputs:
    - service_credentials_file: "$BITRISEIO_FIREBASE_SERVICE_ACCOUNT_JSON_URL"
    - app_path: "$BITRISE_FLUTTER_APK_PATH"
    - groups: "testers"
    - release_notes: "Build $BITRISE_BUILD_NUMBER"
```

**Варіант 2: Використання Fastlane**

1. **Додайте step:** `fastlane`
2. **Lane:** `firebase_distribution`
3. **Work directory:** `./`

Потрібно створити файл `Fastfile` в корені проекту:

```ruby
# android/fastlane/Fastfile
default_platform(:android)

platform :android do
  desc "Distribute to Firebase App Distribution"
  lane :firebase_distribution do
    firebase_app_distribution(
      app: ENV["BITRISE_FLUTTER_APK_PATH"],
      groups: "testers",
      release_notes: "Build #{ENV["BITRISE_BUILD_NUMBER"]}",
      firebase_cli_token: ENV["FIREBASE_TOKEN"]
    )
  end
end
```

### 5.4 Додавання Secrets в Bitrise

1. **Перейдіть в ваш проект Bitrise → Code → Secrets**
2. **Додайте наступні Environment Variables:**

#### Firebase Service Account JSON

**Назва:** `FIREBASE_SERVICE_ACCOUNT_JSON_URL`  
**Тип:** Secret File  
**Значення:** Завантажте JSON файл з Firebase Service Account

**Або використайте Text Secret з вмістом JSON:**

**Назва:** `FIREBASE_SERVICE_ACCOUNT_JSON`  
**Тип:** Secret Text  
**Значення:** Весь вміст JSON файлу (як текст)

#### Firebase CLI Token (альтернативний спосіб)

```bash
# Отримайте токен через Firebase CLI
firebase login:ci
```

**Назва:** `FIREBASE_TOKEN`  
**Тип:** Secret Text  
**Значення:** Токен отриманий з команди вище

### 5.5 Налаштування тестерів

1. **У Firebase Console → App Distribution → Testers & Groups**
2. **Створіть групу тестерів** (наприклад, "QA Team")
3. **Додайте email адреси тестерів**
4. **Використайте назву групи в Bitrise Workflow**

---

## 6. ПОВНИЙ ПРИКЛАД WORKFLOW

### Остаточна конфігурація Workflow

```yaml
workflows:
  android-build-and-distribute:
    steps:
    - activate-ssh-key@4:
        run_if: '{{getenv "SSH_RSA_PRIVATE_KEY" | ne ""}}'
    - git-clone@6: {}
    - cache-pull@2: {}
    - flutter-installer@0:
        inputs:
        - flutter_version: "3.24.0"
        - channel: "stable"
    - flutter-analyze@0: {}
    - install-missing-android-tools@3:
        inputs:
        - android_home: "$ANDROID_HOME"
    - android-signing-config@0:
        inputs:
        - keystore_url: "$BITRISEIO_ANDROID_KEYSTORE_URL"
        - keystore_password: "$BITRISEIO_ANDROID_KEYSTORE_PASSWORD"
        - keystore_alias: "$BITRISEIO_ANDROID_KEYSTORE_ALIAS"
        - private_key_password: "$BITRISEIO_ANDROID_KEYSTORE_PRIVATE_KEY_PASSWORD"
    - flutter-build@0:
        inputs:
        - project_location: "$BITRISE_FLUTTER_PROJECT_LOCATION"
        - build_arguments: "build apk --release"
        - target_platform: "android"
    - sign-apk@1:
        inputs:
        - apk_path: "$BITRISE_FLUTTER_APK_PATH"
    - firebase-app-distribution@3:
        inputs:
        - service_credentials_file_path: "$BITRISE_FIREBASE_SERVICE_ACCOUNT_JSON"
        - app_path: "$BITRISE_FLUTTER_APK_PATH"
        - groups: "testers"
        - release_notes: "Build #$BITRISE_BUILD_NUMBER - Automated build from Bitrise"
    - deploy-to-bitrise-io@2:
        inputs:
        - deploy_path: "$BITRISE_FLUTTER_APK_PATH"
    - cache-push@2: {}
```

---

## 7. ТРИГЕРИ ЗБІРКИ

### 7.1 Автоматичні збірки

**Push до main branch:**
- Workflow автоматично запускається при push до `main`
- Налаштовано через GitHub webhook

### 7.2 Ручний запуск

1. **Перейдіть в Bitrise → Builds**
2. **Натисніть "Start/Schedule a Build"**
3. **Оберіть branch:** `main`
4. **Оберіть workflow:** `android-build-and-distribute`
5. **Натисніть "Start Build"**

### 7.3 Pull Request збірки

Для PR можна створити окремий workflow:

```yaml
workflows:
  pull-request:
    steps:
    - activate-ssh-key@4: {}
    - git-clone@6: {}
    - flutter-installer@0: {}
    - flutter-analyze@0: {}
    - flutter-test@0: {}
```

---

## 8. ПЕРЕВІРКА ТА ТЕСТУВАННЯ

### 8.1 Перший запуск

1. **Створіть тестовий коміт:**
   ```bash
   git commit --allow-empty -m "Test Bitrise build"
   git push origin main
   ```

2. **Перевірте статус збірки в Bitrise**
3. **Перевірте логи кожного кроку**

### 8.2 Типові проблеми та рішення

#### Помилка: "Flutter not found"
- **Рішення:** Переконайтесь, що step `flutter-installer` використовує правильну версію Flutter

#### Помилка: "Android SDK not found"
- **Рішення:** Додайте step `install-missing-android-tools` перед збіркою

#### Помилка: "Keystore not found"
- **Рішення:** Переконайтесь, що всі Secrets для Android signing додано правильно

#### Помилка: "Firebase authentication failed"
- **Рішення:** Перевірте, що `FIREBASE_SERVICE_ACCOUNT_JSON` містить правильний JSON

---

## 9. СТРУКТУРА ПРОЕКТУ ПОСЛЯ ІНТЕГРАЦІЇ

```
minichat-flutter/
├── .git/                          # Git репозиторій
├── .gitignore                     # Git виключення
├── android/
│   ├── app/
│   │   ├── build.gradle.kts
│   │   └── google-services.json   # Виключено з Git
│   └── local.properties           # Виключено з Git
├── lib/                           # Dart код
├── pubspec.yaml                   # Залежності
├── README.md                      # Опис проекту
└── bitrise.yml                    # Bitrise конфігурація (опціонально)
```

---

## 10. ПІДСУМОК

### ✅ Виконані завдання:

1. ✅ **Створено Git репозиторій** локально
2. ✅ **Опубліковано на GitHub** 
3. ✅ **Створено обліковий запис Bitrise.io**
4. ✅ **Інтегровано GitHub репозиторій з Bitrise**
5. ✅ **Налаштовано Workflow для Android**
6. ✅ **Додано Firebase App Distribution** для автоматичного розповсюдження

### 📊 Результат:

- **Автоматична збірка** при кожному push до `main`
- **Автоматичне тестування** коду (analyze, tests)
- **Автоматичне розгортання** в Firebase App Distribution
- **Сповіщення тестерів** про нові збірки

### 🔄 Workflow процесу:

```
Push to GitHub → Bitrise Webhook → 
Flutter Install → Analyze → Test → 
Build APK → Sign APK → 
Firebase App Distribution → 
Notification to Testers
```

---

## 11. ДОДАТКОВІ МАТЕРІАЛИ

- [Bitrise Flutter Documentation](https://devcenter.bitrise.io/en/getting-started/getting-started-with-flutter-apps.html)
- [Firebase App Distribution](https://firebase.google.com/docs/app-distribution)
- [Git Documentation](https://git-scm.com/doc)
- [GitHub Documentation](https://docs.github.com/)

---

**Дата створення:** 2025  
**Версія:** 1.0  
**Проект:** MiniChat Flutter Application

