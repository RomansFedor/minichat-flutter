 -- ============================================================================
-- ЛАБОРАТОРНА РОБОТА №7
-- Індекси та плани виконання запитів
-- База даних: Система управління світами, творами та персонажами
-- ============================================================================

-- ============================================================================
-- ЗАВДАННЯ 1: АВТОМАТИЧНІ ІНДЕКСИ ВІД ОБМЕЖЕНЬ ЦІЛІСНОСТІ
-- ============================================================================

-- Перевірка автоматично створених індексів від обмежень цілісності

-- Таблиця: "worlds"
SELECT * FROM pg_indexes WHERE tablename = 'worlds';
-- Первинний ключ: worlds_pkey
-- Індекс: worlds_pkey
-- Обмеження унікальності: worlds_name_key  
-- Індекс: worlds_name_key

-- Таблиця: "characters"
SELECT * FROM pg_indexes WHERE tablename = 'characters';
-- Первинний ключ: characters_pkey
-- Індекс: characters_pkey

-- Таблиця: "locations"
SELECT * FROM pg_indexes WHERE tablename = 'locations';
-- Первинний ключ: locations_pkey
-- Індекс: locations_pkey
-- Обмеження унікальності: unique_location_per_world
-- Індекс: unique_location_per_world

-- Таблиця: "works"
SELECT * FROM pg_indexes WHERE tablename = 'works';
-- Первинний ключ: works_pkey
-- Індекс: works_pkey

-- Таблиця: "chapters"
SELECT * FROM pg_indexes WHERE tablename = 'chapters';
-- Первинний ключ: chapters_pkey
-- Індекс: chapters_pkey
-- Обмеження унікальності: unique_chapter_number_per_work
-- Індекс: unique_chapter_number_per_work

-- ============================================================================
-- ЗАВДАННЯ 2: ПЛАН ВИКОНАННЯ З РІЗНИМИ УМОВАМИ ВІДБОРУ
-- ============================================================================

-- а) Перебір всіх рядків (Seq Scan)
EXPLAIN ANALYZE
SELECT * FROM characters;

-- б) За будь-яким індексом (Index Scan)
EXPLAIN ANALYZE
SELECT * FROM characters 
WHERE character_id = 1;

-- в) Лише значення проіндексованої колонки (Index Only Scan)
EXPLAIN ANALYZE
SELECT character_id FROM characters 
WHERE character_id BETWEEN 1 AND 100;

-- Порівняння витрат
-- Запит з повним перебором
EXPLAIN ANALYZE
SELECT * FROM characters 
WHERE name LIKE '%Тест%';

-- Запит з використанням індексу
EXPLAIN ANALYZE
SELECT * FROM characters 
WHERE character_id = 50;

-- ============================================================================
-- ЗАВДАННЯ 3: ПЛАНИ ДЛЯ ПЕРВИННОГО КЛЮЧА З РІЗНИМИ ПРЕДИКАТАМИ
-- ============================================================================

-- Запит 1: Предикат = (Index Scan)
EXPLAIN ANALYZE
SELECT * FROM characters 
WHERE character_id = 10;

-- Запит 2: Предикат != (може не використовувати індекс)
EXPLAIN ANALYZE
SELECT * FROM characters 
WHERE character_id != 10;

-- Запит 3: Предикат < (Index Scan)
EXPLAIN ANALYZE
SELECT * FROM characters 
WHERE character_id < 50;

-- Запит 4: Предикат > (Index Scan)
EXPLAIN ANALYZE
SELECT * FROM characters 
WHERE character_id > 50;

-- Запит 5: Комбінація з AND (Index Scan)
EXPLAIN ANALYZE
SELECT * FROM characters 
WHERE character_id > 10 AND character_id < 50;

-- Запит 6: Комбінація з OR (може не використовувати індекс ефективно)
EXPLAIN ANALYZE
SELECT * FROM characters 
WHERE character_id = 10 OR character_id = 20;

-- Запит 7: Складніша комбінація OR (Bitmap Heap Scan)
EXPLAIN ANALYZE
SELECT * FROM characters 
WHERE character_id < 10 OR character_id > 100;

-- А) Вибірка за результатом функції, параметр якої є в індексі
-- Індекс на created_at не використовується, бо застосована функція
EXPLAIN ANALYZE
SELECT * FROM works 
WHERE EXTRACT(YEAR FROM created_at) = 2024;

-- Або для таблиці events з колонкою year
EXPLAIN ANALYZE
SELECT * FROM events 
WHERE year = 2024;

-- Б) Сортування за значеннями, що є в індексі
-- Використовує індекс для сортування (якщо індекс існує)
EXPLAIN ANALYZE
SELECT character_id, name
FROM characters 
ORDER BY character_id;

-- Або сортування по кількох колонках
EXPLAIN ANALYZE
SELECT work_id, title, created_at
FROM works 
ORDER BY created_at, title;

-- Пояснення: Чому індекс не застосовується для !=
-- Оптимізатор вирішує, що перебір всіх рядків швидший, 
-- ніж читання майже всіх записів через індекс

-- ============================================================================
-- ЗАВДАННЯ 4: JOIN ЗАПИТИ ТА ІНДЕКСИ НА ЗОВНІШНІХ КЛЮЧАХ
-- ============================================================================

-- А) Вибірка з 2 зв'язаних таблиць
EXPLAIN ANALYZE
SELECT c.name, w.name
FROM characters c
JOIN worlds w ON c.world_id = w.world_id;

-- Б) Створити 1 індекс на колонку зовнішнього ключа і порівняти план того самого запиту
CREATE INDEX IF NOT EXISTS idx_characters_world_id 
ON characters(world_id);

-- Оновлення статистики для правильного вибору плану
ANALYZE characters;
ANALYZE worlds;

-- План після створення індексу
-- Примітка: Для маленьких таблиць PostgreSQL може вибрати Hash Join як оптимальний
EXPLAIN ANALYZE
SELECT c.name, w.name
FROM characters c
JOIN worlds w ON c.world_id = w.world_id;

-- Запит для отримання Merge Join (як на зображенні)
-- Merge Join використовується, коли обидві таблиці відсортовані за колонками JOIN
-- Використовуємо підзапити з ORDER BY, щоб змусити використати індекси та Merge Join
EXPLAIN ANALYZE
SELECT c.name, w.name
FROM (
    SELECT world_id, name 
    FROM worlds 
    ORDER BY world_id
) w
JOIN (
    SELECT world_id, name, character_id
    FROM characters 
    ORDER BY world_id, character_id
) c ON w.world_id = c.world_id;

-- В) Додати у запит клаузу WHERE з умовою фільтрації по будь-якій неключовій колонці
EXPLAIN ANALYZE
SELECT c.name, w.name
FROM characters c
JOIN worlds w ON c.world_id = w.world_id
WHERE w.genre = 'Фентезі';

-- ============================================================================
-- ЗАВДАННЯ 5: КОЛИ ІНДЕКС НЕ ЗАСТОСОВУЄТЬСЯ
-- ============================================================================

-- Знайти комбінації значень та/або предикатів у клаузі WHERE попереднього запиту,
-- щоб існуючий індекс на колонках первинного чи зовнішнього ключа не застосовувався

-- Приклад 1: Використання арифметичної операції на індексованій колонці
-- Індекс не використовується, бо застосована операція
EXPLAIN ANALYZE
SELECT c.name, w.name
FROM characters c
JOIN worlds w ON c.world_id = w.world_id
WHERE c.world_id + 0 = 1;

-- Приклад 2: Використання функції на індексованій колонці
EXPLAIN ANALYZE
SELECT c.name, w.name
FROM characters c
JOIN worlds w ON c.world_id = w.world_id
WHERE ABS(c.world_id) = 1;

-- Приклад 3: Порівняння з виразом (не константою)
EXPLAIN ANALYZE
SELECT c.name, w.name
FROM characters c
JOIN worlds w ON c.world_id = w.world_id
WHERE c.world_id = (SELECT COUNT(*) FROM worlds);

-- Логіка вибору СУБД:
-- 1. Якщо колонка в умові модифікована (функція, операція) - індекс не використовується
-- 2. Якщо умова не на індексованій колонці напряму - індекс не використовується
-- 3. Якщо селективність висока (>30% рядків) - повний перебір може бути швидшим
-- 4. СУБД обирає індекс, коли він дає перевагу в швидкості

-- ============================================================================
-- ЗАВДАННЯ 6: GROUP BY, ORDER BY, LIMIT
-- ============================================================================

-- Без індексу
EXPLAIN ANALYZE
SELECT * FROM characters;

-- Без індексу, але з LIMIT
EXPLAIN ANALYZE
SELECT * FROM characters
LIMIT 5;

-- Без індексу
EXPLAIN ANALYZE
SELECT * FROM characters
ORDER BY name;

-- З індексом
CREATE INDEX IF NOT EXISTS idx_characters_name 
ON characters(name);

EXPLAIN ANALYZE
SELECT * FROM characters
ORDER BY name;

-- Без індексу
EXPLAIN ANALYZE
SELECT name, COUNT(*)
FROM characters
GROUP BY name;

-- З індексом (використовуємо вже створений idx_characters_name)
EXPLAIN ANALYZE
SELECT name, COUNT(*)
FROM characters
GROUP BY name;

-- З індексом та LIMIT
EXPLAIN ANALYZE
SELECT name, COUNT(*)
FROM characters
GROUP BY name
ORDER BY COUNT(*) DESC
LIMIT 5;

-- ============================================================================
-- ЗАВДАННЯ 7: ВИЗНАЧЕННЯ ТАБЛИЦЬ ДЛЯ ІНДЕКСУВАННЯ
-- ============================================================================

-- Таблиця: chapter_participation
-- Приріст: Кожен розділ може містити багато персонажів. Якщо твір має 50 розділів,
-- по 10 персонажів у кожному = 500 записів на один твір. При сотнях творів накопичується велика кількість даних.
-- Обґрунтування індексу: Відображення участі персонажа. Коли користувач переглядає профіль персонажа,
-- система робить запит: SELECT chapter_id FROM chapter_participation WHERE character_id = ?.
-- Без індексу це буде повний перебір мільйона записів.
-- Колонка: character_id
-- Тип індексу: BTree

CREATE INDEX IF NOT EXISTS idx_chapter_participation_character_id 
ON chapter_participation(character_id);

-- Обґрунтування індексу: Відображення персонажів розділу. При перегляді розділу потрібно показати всіх персонажів.
-- Запит: SELECT character_id FROM chapter_participation WHERE chapter_id = ?.
-- Без індексу пошук буде повільним.
-- Колонка: chapter_id
-- Тип індексу: BTree

CREATE INDEX IF NOT EXISTS idx_chapter_participation_chapter_id 
ON chapter_participation(chapter_id);

-- Таблиця: chapters
-- Приріст: Кожен твір може мати десятки або сотні розділів. При сотнях творів накопичується велика кількість даних.
-- Обґрунтування індексу: Відображення розділів твору. При перегляді твору потрібно показати всі розділи в порядку номерів.
-- Запит: SELECT * FROM chapters WHERE work_id = ? ORDER BY number.
-- Без індексу сортування буде повільним.
-- Колонки: work_id, number
-- Тип індексу: BTree

CREATE INDEX IF NOT EXISTS idx_chapters_work_id_number 
ON chapters(work_id, number);

-- Таблиця: characters
-- Приріст: Кожен світ може містити сотні персонажів. При десятках світів накопичується велика кількість даних.
-- Обґрунтування індексу: Пошук персонажів у світі. При перегляді світу потрібно показати всіх персонажів.
-- Запит: SELECT * FROM characters WHERE world_id = ?.
-- Без індексу пошук буде повільним.
-- Колонка: world_id
-- Тип індексу: BTree

CREATE INDEX IF NOT EXISTS idx_characters_world_id 
ON characters(world_id);

-- Обґрунтування індексу: Пошук персонажа за іменем. Користувачі часто шукають персонажів за неповною назвою.
-- Запит: SELECT * FROM characters WHERE name LIKE '%Арагорн%'.
-- Колонка: name
-- Тип індексу: BTree

CREATE INDEX IF NOT EXISTS idx_characters_name 
ON characters(name);

-- Таблиця: events
-- Приріст: Кожен таймлайн може містити сотні подій. При десятках таймлайнів накопичується велика кількість даних.
-- Обґрунтування індексу: Фільтрація подій за роками. При перегляді хронології потрібно показати події за певний період.
-- Запит: SELECT * FROM events WHERE year BETWEEN 1000 AND 1500.
-- Без індексу фільтрація буде повільною.
-- Колонка: year
-- Тип індексу: BTree

CREATE INDEX IF NOT EXISTS idx_events_year 
ON events(year);

-- Таблиця: works
-- Приріст: Кожен світ може містити десятки творів. При десятках світів накопичується велика кількість даних.
-- Обґрунтування індексу: Фільтрація творів за світом та статусом. При перегляді світу потрібно показати тільки завершені твори.
-- Запит: SELECT * FROM works WHERE world_id = ? AND status = 'finished'.
-- Без індексу фільтрація буде повільною.
-- Колонки: world_id, status
-- Тип індексу: BTree

CREATE INDEX IF NOT EXISTS idx_works_world_id_status 
ON works(world_id, status);

-- ============================================================================
-- ЗАВДАННЯ 8: СТВОРЕННЯ ПРОСТИХ ІНДЕКСІВ
-- ============================================================================

-- Завдання: знайти всі завершені твори у світі "Світ Епічного Фентезі" і показати їх розділи по порядку

-- Запит ДО створення індексів
EXPLAIN ANALYZE
SELECT w.name, wo.title, ch.number, ch.title
FROM worlds w
JOIN works wo ON w.world_id = wo.world_id
JOIN chapters ch ON wo.work_id = ch.work_id
WHERE w.name = 'Світ Епічного Фентезі'
  AND wo.status = 'finished'
ORDER BY ch.number;

-- Створення 3 простих індексів
CREATE INDEX IF NOT EXISTS idx_worlds_name 
ON worlds(name);

CREATE INDEX IF NOT EXISTS idx_works_world_id 
ON works(world_id);

CREATE INDEX IF NOT EXISTS idx_chapters_work_number 
ON chapters(work_id, number);

-- Запит ПІСЛЯ створення індексів
EXPLAIN ANALYZE
SELECT w.name, wo.title, ch.number, ch.title
FROM worlds w
JOIN works wo ON w.world_id = wo.world_id
JOIN chapters ch ON wo.work_id = ch.work_id
WHERE w.name = 'Світ Епічного Фентезі'
  AND wo.status = 'finished'
ORDER BY ch.number;

-- ============================================================================
-- ЗАВДАННЯ 9: СКЛАДНІ ІНДЕКСИ
-- ============================================================================

-- а) Індекс на декілька колонок
-- Завдання: вибрати всі розділи конкретного твору з певним номером
EXPLAIN ANALYZE
SELECT * 
FROM chapters 
WHERE work_id = 1
  AND number = 5;

-- З індексом 
CREATE INDEX IF NOT EXISTS idx_chapters_work_number 
ON chapters(work_id, number);

EXPLAIN ANALYZE
SELECT * 
FROM chapters 
WHERE work_id = 1
  AND number = 5;

-- б) Покриваючий індекс із включеною колонкою
-- Завдання: Вивести кількість персонажів у світах
EXPLAIN ANALYZE
SELECT COUNT(character_id) 
FROM characters 
WHERE world_id = 1;

-- З індексом
CREATE INDEX IF NOT EXISTS idx_characters_world_id_include_id 
ON characters(world_id) 
INCLUDE (character_id);

EXPLAIN ANALYZE
SELECT COUNT(character_id) 
FROM characters 
WHERE world_id = 1;

-- в) Індекс на функцію від декількох колонок
-- Завдання: фільтрація творів за роком створення
EXPLAIN ANALYZE
SELECT * 
FROM works 
WHERE EXTRACT(YEAR FROM created_at) = 2024;

-- З індексом
CREATE INDEX IF NOT EXISTS idx_works_created_year 
ON works((EXTRACT(YEAR FROM created_at)));

EXPLAIN ANALYZE
SELECT * 
FROM works 
WHERE EXTRACT(YEAR FROM created_at) = 2024;

-- ============================================================================
-- ЗАВДАННЯ 10: ПОВНОТЕКСТОВИЙ ПОШУК
-- ============================================================================

-- Додаємо колонку для повнотекстового пошуку
ALTER TABLE works
ADD COLUMN IF NOT EXISTS synopsis_fts tsvector
GENERATED ALWAYS AS (to_tsvector('simple', COALESCE(synopsis, ''))) STORED;

-- Створення GIN індексу для повнотекстового пошуку
CREATE INDEX IF NOT EXISTS idx_works_synopsis_fts 
ON works USING GIN(synopsis_fts);

-- Запит з використанням повнотекстового пошуку
EXPLAIN ANALYZE
SELECT title, synopsis 
FROM works 
WHERE synopsis_fts @@ to_tsquery('simple', 'магія');

-- Опис принципу роботи:
-- Парсинг та Нормалізація:
-- Вхідний текст розбивається на окремі токени (слова).
-- Застосовуються словники для стемінгу: від слів відкидаються закінчення та суфікси, 
-- щоб привести їх до спільної основи (лексеми).
-- Видаляються "стоп-слова" (прийменники, сполучники, такі як "і", "на", "про")
--
-- Індексування:
-- На основі колонки tsvector будується GIN-індекс.
-- Він зберігає список усіх унікальних лексем і для кожної з них — перелік ID рядків, де вона зустрічається
--
-- Пошук:
-- Пошуковий запит користувача також обробляється і перетворюється на тип tsquery 
-- (набір лексем з логічними операторами AND, OR, NOT).
-- Оператор @@ перевіряє відповідність tsvector запиту tsquery, використовуючи GIN-індекс 
-- для швидкого отримання результату.

-- ============================================================================
-- ЗАВДАННЯ 11: ПОРІВНЯННЯ ПОВНОТЕКСТОВОГО ПОШУКУ
-- ============================================================================

-- Запит БЕЗ повнотекстового індексу (LIKE пошук)
EXPLAIN ANALYZE
SELECT work_id, title, synopsis
FROM works
WHERE synopsis LIKE '%магія%' OR synopsis LIKE '%світ%';

-- Запит З повнотекстовим індексом
EXPLAIN ANALYZE
SELECT work_id, title, synopsis
FROM works
WHERE synopsis_fts @@ to_tsquery('simple', 'магія | світ');

-- Запит з фразою
EXPLAIN ANALYZE
SELECT work_id, title, synopsis
FROM works
WHERE synopsis_fts @@ phraseto_tsquery('simple', 'магічний світ');

-- Оцінка при збільшенні об'єму даних:
-- В таблиці works зараз близько 100 рядків даних, при цьому час виконання запиту з індексом 
-- та без вже значно відрізняється. Якщо даних стане значно більше (тисячі або десятки тисяч рядків),
-- виконання вибірки без індексу стане зовсім неефективним та спричинятиме значні затримки у відповіді.
-- LIKE пошук: O(n) - лінійний час, зростає пропорційно об'єму
-- FTS з GIN: O(log n) - логарифмічний час, майже не залежить від об'єму

-- ============================================================================
-- ЗАВДАННЯ 12: СТАТИСТИКА БД
-- ============================================================================

-- а) Кількість операцій доступу до даних
SELECT 
    schemaname,
    tablename,
    seq_scan AS sequential_scans,  -- Читання з купи (повний перебір)
    seq_tup_read AS tuples_read_seq,  -- Рядків прочитано послідовно
    idx_scan AS index_scans,  -- Читання з індексів
    idx_tup_fetch AS tuples_fetched_idx,  -- Рядків отримано з індексів
    n_tup_ins AS inserts,  -- Вставок
    n_tup_upd AS updates,  -- Оновлень
    n_tup_del AS deletes  -- Видалень
FROM pg_stat_user_tables
WHERE tablename = 'characters'  -- Замініть на потрібну таблицю
ORDER BY seq_scan + idx_scan DESC;

-- б) Характеристики значень для колонок з індексами
SELECT 
    schemaname,
    tablename,
    attname AS column_name,
    n_distinct AS distinct_values,  -- Кількість унікальних значень
    correlation AS correlation_with_row_order,  -- Кореляція з порядком рядків
    most_common_vals AS most_common_values,  -- Найчастіші значення
    most_common_freqs AS most_common_frequencies  -- Частоти найчастіших значень
FROM pg_stats
WHERE schemaname = 'public'
  AND tablename = 'characters'  -- Замініть на потрібну таблицю
  AND attname IN (
    SELECT column_name 
    FROM information_schema.table_constraints tc
    JOIN information_schema.key_column_usage kcu 
        ON tc.constraint_name = kcu.constraint_name
    WHERE tc.table_name = 'characters'
      AND tc.constraint_type IN ('PRIMARY KEY', 'UNIQUE')
  );

-- в) Поточний об'єм даних у купі та розмір індексів
SELECT 
    schemaname,
    tablename,
    pg_size_pretty(pg_relation_size(schemaname||'.'||tablename)) AS table_size,
    pg_size_pretty(pg_indexes_size(schemaname||'.'||tablename)) AS indexes_size,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS total_size,
    pg_relation_size(schemaname||'.'||tablename) AS table_size_bytes,
    pg_indexes_size(schemaname||'.'||tablename) AS indexes_size_bytes
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename = 'characters'  -- Замініть на потрібну таблицю
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;

-- Детальна інформація про індекси таблиці
SELECT
    i.indexname AS index_name,
    pg_size_pretty(pg_relation_size(i.indexname::regclass)) AS index_size,
    i.indexdef AS index_definition,
    idx_scan AS times_used,
    idx_tup_read AS tuples_read,
    idx_tup_fetch AS tuples_fetched
FROM pg_indexes i
LEFT JOIN pg_stat_user_indexes s 
    ON i.indexname = s.indexname
WHERE i.schemaname = 'public'
  AND i.tablename = 'characters'  -- Замініть на потрібну таблицю
ORDER BY pg_relation_size(i.indexname::regclass) DESC;

-- ============================================================================
-- ДОДАТКОВІ КОРИСНІ ЗАПИТИ ДЛЯ АНАЛІЗУ
-- ============================================================================

-- Перевірка використання індексів
SELECT 
    schemaname,
    tablename,
    indexname,
    idx_scan AS times_used,
    idx_tup_read AS tuples_read,
    idx_tup_fetch AS tuples_fetched
FROM pg_stat_user_indexes
WHERE schemaname = 'public'
ORDER BY idx_scan ASC;  -- Індекси, які не використовуються

-- Оновлення статистики для точніших планів
ANALYZE characters;
ANALYZE worlds;
ANALYZE chapters;
ANALYZE works;

-- Перевірка фрагментації таблиць
SELECT 
    schemaname,
    tablename,
    n_dead_tup AS dead_tuples,  -- "Мертві" рядки (потрібен VACUUM)
    n_live_tup AS live_tuples,  -- "Живі" рядки
    last_vacuum,
    last_autovacuum,
    last_analyze,
    last_autoanalyze
FROM pg_stat_user_tables
WHERE schemaname = 'public'
ORDER BY n_dead_tup DESC;

-- Рекомендація: Виконати VACUUM для очищення "мертвих" рядків
-- VACUUM ANALYZE characters;

-- ============================================================================
-- КІНЕЦЬ ФАЙЛУ
-- ============================================================================

