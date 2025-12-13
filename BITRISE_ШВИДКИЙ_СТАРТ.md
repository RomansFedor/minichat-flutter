# ⚡ BITRISE - ШВИДКИЙ СТАРТ

## 🎯 ЩО ПОТРІБНО ЗРОБИТИ

### 1️⃣ GitHub (5 хвилин)
1. Створіть репозиторій на GitHub
2. Підключіть локальний Git:
   ```bash
   git remote add origin https://github.com/YOUR_USERNAME/minichat-flutter.git
   git push -u origin main
   ```

### 2️⃣ Bitrise (10 хвилин)
1. Зареєструйтесь на https://www.bitrise.io (через GitHub)
2. **Add new App** → оберіть ваш GitHub репозиторій
3. Project Type: **Flutter**
4. Register Webhook ✅

### 3️⃣ Firebase (5 хвилин)
1. Firebase Console → Project Settings → Service Accounts
2. **Generate new private key** → завантажте JSON
3. Bitrise → Secrets → додайте JSON як `BITRISE_FIREBASE_SERVICE_ACCOUNT_JSON`

### 4️⃣ Workflow (10 хвилин)
Використайте готовий `bitrise.yml` або налаштуйте вручну:

**Основні кроки:**
- Flutter Install
- Flutter Analyze  
- Flutter Build APK
- Firebase App Distribution

### 5️⃣ Тестування (2 хвилини)
```bash
git commit --allow-empty -m "Test Bitrise build"
git push origin main
```

✅ Перевірте Bitrise → Builds → має з'явитися нова збірка!

---

## 📁 ФАЙЛИ

- `bitrise.yml` - конфігурація Bitrise (можна використати)
- `BITRISE_ПРАКТИЧНЕ_НАЛАШТУВАННЯ.md` - детальна інструкція
- `LAB7_GIT_BITRISE_SETUP.md` - теоретична документація

---

## 🔗 ПОСИЛАННЯ

- **GitHub:** https://github.com/YOUR_USERNAME/minichat-flutter
- **Bitrise:** https://app.bitrise.io
- **Firebase:** https://console.firebase.google.com

---

**Детальна інструкція:** Читайте `BITRISE_ПРАКТИЧНЕ_НАЛАШТУВАННЯ.md`

