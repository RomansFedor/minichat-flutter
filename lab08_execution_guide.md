# ІНСТРУКЦІЯ ДО ВИКОНАННЯ ЛАБОРАТОРНОЇ РОБОТИ №8

## Кроки виконання:

### 1. Підготовка

Переконайтеся, що у вас є:
- PostgreSQL 11+ (для підтримки композитних типів та INCLUDE в індексах)
- Доступ до БД з правами на створення таблиць, типів та тригерів
- Резервна копія поточної БД (на всяк випадок)

### 2. Виконання скрипту

```bash
# Виконайте скрипт в pgAdmin або через psql
psql -U your_user -d your_database -f lab08_database_refactoring.sql
```

Або в pgAdmin:
1. Відкрийте `lab08_database_refactoring.sql`
2. Виконайте весь скрипт (F5)

### 3. Перевірка результатів

#### Перевірка створених таблиць:

```sql
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN (
    'users', 'comments', 'ratings', 'work_history', 
    'character_locations', 'descriptions', 'world_statistics'
)
ORDER BY table_name;
```

#### Перевірка створених типів:

```sql
SELECT typname, typtype 
FROM pg_type 
WHERE typnamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public')
AND typname IN ('address_type', 'full_name_type', 'chapter_stage_type')
ORDER BY typname;
```

#### Перевірка нових колонок:

```sql
-- Перевірка works
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'works' 
AND column_name IN ('average_rating', 'total_ratings', 'comment_count', 'is_archived');

-- Перевірка chapters
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'chapters' 
AND column_name = 'stage';
```

#### Перевірка тригерів:

```sql
SELECT trigger_name, event_object_table, action_timing, event_manipulation
FROM information_schema.triggers
WHERE trigger_schema = 'public'
AND trigger_name LIKE 'trigger_%'
ORDER BY event_object_table, trigger_name;
```

### 4. Тестування функціональності

#### Тест 1: Вставка користувача з композитним типом

```sql
INSERT INTO users (username, email, full_name)
VALUES (
    'test_user',
    'test@example.com',
    ROW('Іван', 'Петрович', 'Коваленко')::full_name_type
);

SELECT 
    username,
    (full_name).first_name,
    (full_name).last_name
FROM users
WHERE username = 'test_user';
```

#### Тест 2: Додавання оцінки та перевірка денормалізації

```sql
-- Додаємо оцінку
INSERT INTO ratings (work_id, user_id, rating_value)
VALUES (1, 1, 5);

-- Перевіряємо, що average_rating оновився
SELECT work_id, title, average_rating, total_ratings
FROM works
WHERE work_id = 1;
```

#### Тест 3: Додавання коментаря

```sql
INSERT INTO comments (work_id, user_id, content)
VALUES (1, 1, 'Чудовий твір!');

-- Перевіряємо comment_count
SELECT work_id, title, comment_count
FROM works
WHERE work_id = 1;
```

#### Тест 4: Перевірка історії змін

```sql
-- Оновлюємо твір
UPDATE works 
SET title = 'Нова назва'
WHERE work_id = 1;

-- Перевіряємо історію
SELECT * FROM work_history
WHERE work_id = 1
ORDER BY changed_at DESC;
```

### 5. Створення діаграми

Використайте pgAdmin або інший інструмент для створення ER-діаграми:

1. В pgAdmin: Клацніть правою кнопкою на базі даних → "Generate ERD"
2. Або використайте онлайн інструменти (dbdiagram.io, draw.io)

### 6. Звіт

У звіт включіть:

1. **Результати виконання скрипту** (скріншоти або текст)
2. **Діаграму нової схеми БД**
3. **Приклади даних до/після** (скріншоти таблиць)
4. **Приклад композитного типу** (як показано вище)
5. **Аналіз змін** (використайте `lab08_analysis_and_explanations.md`)

### 7. Можливі проблеми та рішення

#### Проблема: "тип не існує"
**Рішення:** Переконайтеся, що типи створюються перед використанням

#### Проблема: "обмеження вже існує"
**Рішення:** Додайте `IF NOT EXISTS` або видаліть існуюче обмеження

#### Проблема: "колонка вже існує"
**Рішення:** Використайте `ADD COLUMN IF NOT EXISTS`

### 8. Відкат змін (якщо потрібно)

Якщо потрібно відкатити зміни:

```sql
-- Видалення таблиць
DROP TABLE IF EXISTS world_statistics CASCADE;
DROP TABLE IF EXISTS descriptions CASCADE;
DROP TABLE IF EXISTS character_locations CASCADE;
DROP TABLE IF EXISTS work_history CASCADE;
DROP TABLE IF EXISTS ratings CASCADE;
DROP TABLE IF EXISTS comments CASCADE;
DROP TABLE IF EXISTS users CASCADE;

-- Видалення типів
DROP TYPE IF EXISTS chapter_stage_type CASCADE;
DROP TYPE IF EXISTS full_name_type CASCADE;
DROP TYPE IF EXISTS address_type CASCADE;

-- Видалення колонок
ALTER TABLE works 
DROP COLUMN IF EXISTS average_rating,
DROP COLUMN IF EXISTS total_ratings,
DROP COLUMN IF EXISTS comment_count,
DROP COLUMN IF EXISTS is_archived,
DROP COLUMN IF EXISTS archived_at,
DROP COLUMN IF EXISTS archived_reason;

ALTER TABLE characters 
DROP COLUMN IF EXISTS is_archived,
DROP COLUMN IF EXISTS archived_at;

ALTER TABLE chapters 
DROP COLUMN IF EXISTS stage;

ALTER TABLE locations 
DROP COLUMN IF EXISTS address;
```

---

**Примітка:** Завжди робіть резервну копію перед виконанням скриптів оновлення!



