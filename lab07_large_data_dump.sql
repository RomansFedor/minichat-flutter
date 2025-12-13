-- ============================================================================
-- ВЕЛИКИЙ ДАМП ДАНИХ ДЛЯ ЛАБОРАТОРНОЇ РОБОТИ №7
-- Створено для демонстрації різниці між Seq Scan та Index Scan
-- ============================================================================

-- Тимчасово вимикаємо тригери для швидкої вставки
SET session_replication_role = 'replica';

-- Синхронізація послідовностей
SELECT setval('worlds_world_id_seq', COALESCE((SELECT MAX(world_id) FROM worlds), 0) + 1, false);
SELECT setval('characters_character_id_seq', COALESCE((SELECT MAX(character_id) FROM characters), 0) + 1, false);
SELECT setval('works_work_id_seq', COALESCE((SELECT MAX(work_id) FROM works), 0) + 1, false);
SELECT setval('chapters_chapter_id_seq', COALESCE((SELECT MAX(chapter_id) FROM chapters), 0) + 1, false);
SELECT setval('locations_location_id_seq', COALESCE((SELECT MAX(location_id) FROM locations), 0) + 1, false);
SELECT setval('timelines_timeline_id_seq', COALESCE((SELECT MAX(timeline_id) FROM timelines), 0) + 1, false);
SELECT setval('events_event_id_seq', COALESCE((SELECT MAX(event_id) FROM events), 0) + 1, false);

-- ============================================================================
-- ДОДАВАННЯ БАГАТЬОХ СВІТІВ
-- ============================================================================

INSERT INTO worlds (name, genre, description) 
SELECT 
    'Світ ' || generate_series,
    CASE (generate_series % 5)
        WHEN 0 THEN 'Фентезі'
        WHEN 1 THEN 'Sci-Fi'
        WHEN 2 THEN 'Історичне'
        WHEN 3 THEN 'Постапокаліпсис'
        ELSE 'Детектив'
    END,
    'Опис світу ' || generate_series
FROM generate_series(1, 50)
WHERE NOT EXISTS (
    SELECT 1 FROM worlds WHERE name = 'Світ ' || generate_series
);

-- ============================================================================
-- ДОДАВАННЯ БАГАТЬОХ ПЕРСОНАЖІВ (5000+ записів)
-- ============================================================================

-- Генеруємо багато персонажів для кожного світу
INSERT INTO characters (world_id, name, role, description)
SELECT 
    w.world_id,
    'Персонаж ' || gs.series || ' у ' || w.name,
    CASE (gs.series % 10)
        WHEN 0 THEN 'Король'
        WHEN 1 THEN 'Воїн'
        WHEN 2 THEN 'Маг'
        WHEN 3 THEN 'Злодій'
        WHEN 4 THEN 'Торговець'
        WHEN 5 THEN 'Чарівник'
        WHEN 6 THEN 'Рейнджер'
        WHEN 7 THEN 'Паладин'
        WHEN 8 THEN 'Друїд'
        ELSE 'Бард'
    END,
    'Опис персонажа ' || gs.series
FROM worlds w
CROSS JOIN generate_series(1, 100) AS gs(series)
WHERE NOT EXISTS (
    SELECT 1 FROM characters ch 
    WHERE ch.world_id = w.world_id 
      AND ch.name = 'Персонаж ' || gs.series || ' у ' || w.name
)
LIMIT 5000;

-- Додаємо унікальних персонажів з різними іменами для тестування індексів
DO $$
DECLARE
    v_world_id INTEGER;
    v_name TEXT;
BEGIN
    FOR i IN 1..50 LOOP
        SELECT world_id INTO v_world_id FROM worlds OFFSET (i % (SELECT COUNT(*) FROM worlds)) LIMIT 1;
        v_name := 'Арагорн_' || i;
        INSERT INTO characters (world_id, name, role)
        SELECT v_world_id, v_name, 'Король'
        WHERE NOT EXISTS (SELECT 1 FROM characters WHERE name = v_name);
        
        v_name := 'Гендальф_' || i;
        INSERT INTO characters (world_id, name, role)
        SELECT v_world_id, v_name, 'Чарівник'
        WHERE NOT EXISTS (SELECT 1 FROM characters WHERE name = v_name);
        
        v_name := 'Леголас_' || i;
        INSERT INTO characters (world_id, name, role)
        SELECT v_world_id, v_name, 'Ельф'
        WHERE NOT EXISTS (SELECT 1 FROM characters WHERE name = v_name);
    END LOOP;
END $$;

-- ============================================================================
-- ДОДАВАННЯ БАГАТЬОХ ТВОРІВ (1000+ записів)
-- ============================================================================

INSERT INTO works (world_id, title, synopsis, status, created_at)
SELECT 
    w.world_id,
    'Твір ' || gs.series || ' у ' || w.name,
    'Опис твору ' || gs.series || ' у світі ' || w.name || '. Це великий твір з багатьма подіями та персонажами.',
    CASE (gs.series % 3)
        WHEN 0 THEN 'finished'
        WHEN 1 THEN 'in_progress'
        ELSE 'draft'
    END,
    (CURRENT_DATE - ((gs.series % 1825) || ' days')::interval)::timestamp
FROM worlds w
CROSS JOIN generate_series(1, 20) AS gs(series)
WHERE NOT EXISTS (
    SELECT 1 FROM works wo 
    WHERE wo.world_id = w.world_id 
      AND wo.title = 'Твір ' || gs.series || ' у ' || w.name
)
LIMIT 1000;

-- ============================================================================
-- ДОДАВАННЯ БАГАТЬОХ РОЗДІЛІВ (5000+ записів)
-- ============================================================================

INSERT INTO chapters (work_id, number, title, content)
SELECT 
    w.work_id,
    gs.series,
    'Розділ ' || gs.series || ' - ' || w.title,
    'Зміст розділу ' || gs.series || ' твору ' || w.title || '. ' ||
    'Це детальний опис подій, що відбуваються в цьому розділі. ' ||
    'Тут багато тексту для демонстрації повнотекстового пошуку.'
FROM works w
CROSS JOIN generate_series(1, 50) AS gs(series)
WHERE NOT EXISTS (
    SELECT 1 FROM chapters ch 
    WHERE ch.work_id = w.work_id 
      AND ch.number = gs.series
)
LIMIT 5000;

-- ============================================================================
-- ДОДАВАННЯ БАГАТЬОХ ЛОКАЦІЙ (1000+ записів)
-- ============================================================================

INSERT INTO locations (world_id, name, type, description)
SELECT 
    w.world_id,
    'Локація ' || gs.series || ' у ' || w.name,
    CASE (gs.series % 6)
        WHEN 0 THEN 'Місто'
        WHEN 1 THEN 'Село'
        WHEN 2 THEN 'Ліс'
        WHEN 3 THEN 'Гора'
        WHEN 4 THEN 'Замок'
        ELSE 'Печера'
    END,
    'Опис локації ' || gs.series
FROM worlds w
CROSS JOIN generate_series(1, 20) AS gs(series)
WHERE NOT EXISTS (
    SELECT 1 FROM locations l 
    WHERE l.world_id = w.world_id 
      AND l.name = 'Локація ' || gs.series || ' у ' || w.name
)
LIMIT 1000;

-- ============================================================================
-- ДОДАВАННЯ БАГАТЬОХ ТАЙМЛАЙНІВ
-- ============================================================================

INSERT INTO timelines (world_id, title, description, start_year, end_year)
SELECT 
    w.world_id,
    'Таймлайн ' || gs.series || ' у ' || w.name,
    'Опис таймлайну ' || gs.series,
    1000 + (gs.series * 100),
    1500 + (gs.series * 100)
FROM worlds w
CROSS JOIN generate_series(1, 5) AS gs(series)
WHERE NOT EXISTS (
    SELECT 1 FROM timelines t 
    WHERE t.world_id = w.world_id 
      AND t.title = 'Таймлайн ' || gs.series || ' у ' || w.name
)
LIMIT 250;

-- ============================================================================
-- ДОДАВАННЯ БАГАТЬОХ ПОДІЙ (5000+ записів)
-- ============================================================================

INSERT INTO events (timeline_id, name, description, year)
SELECT 
    t.timeline_id,
    'Подія ' || gs.series || ' у ' || t.title,
    'Опис події ' || gs.series || ' в таймлайні ' || t.title,
    COALESCE(t.start_year, 1000) + (gs.series * 10)
FROM timelines t
CROSS JOIN generate_series(1, 20) AS gs(series)
WHERE t.start_year IS NOT NULL 
  AND (COALESCE(t.start_year, 1000) + (gs.series * 10)) <= COALESCE(t.end_year, 2000)
  AND NOT EXISTS (
    SELECT 1 FROM events e 
    WHERE e.timeline_id = t.timeline_id 
      AND e.name = 'Подія ' || gs.series || ' у ' || t.title
  )
LIMIT 5000;

-- ============================================================================
-- ДОДАВАННЯ УЧАСТІ ПЕРСОНАЖІВ У РОЗДІЛАХ (10000+ записів)
-- ============================================================================

INSERT INTO chapter_participation (chapter_id, character_id, location_id, scene_role)
SELECT DISTINCT ON (ch.chapter_id, c.character_id)
    ch.chapter_id,
    c.character_id,
    (SELECT location_id FROM locations WHERE world_id = c.world_id LIMIT 1 OFFSET (ch.chapter_id % GREATEST((SELECT COUNT(*) FROM locations WHERE world_id = c.world_id), 1))),
    CASE ((ch.chapter_id + c.character_id) % 5)
        WHEN 0 THEN 'protagonist'
        WHEN 1 THEN 'antagonist'
        WHEN 2 THEN 'supporting'
        WHEN 3 THEN 'cameo'
        ELSE 'participant'
    END
FROM chapters ch
JOIN works w ON ch.work_id = w.work_id
JOIN characters c ON c.world_id = w.world_id
WHERE NOT EXISTS (
    SELECT 1 FROM chapter_participation cp 
    WHERE cp.chapter_id = ch.chapter_id 
      AND cp.character_id = c.character_id
)
LIMIT 10000;

-- ============================================================================
-- ДОДАВАННЯ ФРАКЦІЙ
-- ============================================================================

INSERT INTO factions (world_id, name)
SELECT 
    w.world_id,
    'Фракція ' || gs.series || ' у ' || w.name
FROM worlds w
CROSS JOIN generate_series(1, 10) AS gs(series)
WHERE NOT EXISTS (
    SELECT 1 FROM factions f 
    WHERE f.world_id = w.world_id 
      AND f.name = 'Фракція ' || gs.series || ' у ' || w.name
)
LIMIT 500;

-- ============================================================================
-- ДОДАВАННЯ ЗВ'ЯЗКІВ ПЕРСОНАЖІВ З ФРАКЦІЯМИ
-- ============================================================================

INSERT INTO character_factions (character_id, faction_id)
SELECT 
    c.character_id,
    f.faction_id
FROM characters c
JOIN worlds w ON c.world_id = w.world_id
JOIN factions f ON f.world_id = w.world_id
WHERE NOT EXISTS (
    SELECT 1 FROM character_factions cf 
    WHERE cf.character_id = c.character_id 
      AND cf.faction_id = f.faction_id
)
LIMIT 2000;

-- ============================================================================
-- ОНОВЛЕННЯ СТАТИСТИКИ
-- ============================================================================

-- Вмикаємо тригери назад
SET session_replication_role = 'origin';

-- Оновлюємо статистику для правильного вибору планів
ANALYZE worlds;
ANALYZE characters;
ANALYZE works;
ANALYZE chapters;
ANALYZE locations;
ANALYZE timelines;
ANALYZE events;
ANALYZE chapter_participation;
ANALYZE factions;
ANALYZE character_factions;

-- ============================================================================
-- ПЕРЕВІРКА КІЛЬКОСТІ ДАНИХ
-- ============================================================================

SELECT 'worlds' AS table_name, COUNT(*) AS row_count, 
       pg_size_pretty(pg_relation_size('worlds')) AS table_size
FROM worlds
UNION ALL
SELECT 'characters', COUNT(*), pg_size_pretty(pg_relation_size('characters'))
FROM characters
UNION ALL
SELECT 'works', COUNT(*), pg_size_pretty(pg_relation_size('works'))
FROM works
UNION ALL
SELECT 'chapters', COUNT(*), pg_size_pretty(pg_relation_size('chapters'))
FROM chapters
UNION ALL
SELECT 'locations', COUNT(*), pg_size_pretty(pg_relation_size('locations'))
FROM locations
UNION ALL
SELECT 'timelines', COUNT(*), pg_size_pretty(pg_relation_size('timelines'))
FROM timelines
UNION ALL
SELECT 'events', COUNT(*), pg_size_pretty(pg_relation_size('events'))
FROM events
UNION ALL
SELECT 'chapter_participation', COUNT(*), pg_size_pretty(pg_relation_size('chapter_participation'))
FROM chapter_participation
UNION ALL
SELECT 'factions', COUNT(*), pg_size_pretty(pg_relation_size('factions'))
FROM factions
UNION ALL
SELECT 'character_factions', COUNT(*), pg_size_pretty(pg_relation_size('character_factions'))
FROM character_factions
ORDER BY table_name;

-- ============================================================================
-- ПРИКЛАДИ ЗАПИТІВ ДЛЯ ДЕМОНСТРАЦІЇ РІЗНИЦІ
-- ============================================================================

-- Приклад 1: Пошук за індексом (швидко)
-- EXPLAIN ANALYZE
-- SELECT * FROM characters WHERE character_id = 1000;

-- Приклад 2: Пошук без індексу (повільно для великої таблиці)
-- EXPLAIN ANALYZE
-- SELECT * FROM characters WHERE name LIKE '%Арагорн%';

-- Приклад 3: Діапазонний пошук з індексом
-- EXPLAIN ANALYZE
-- SELECT * FROM characters WHERE character_id BETWEEN 1000 AND 2000;

-- Приклад 4: JOIN з індексом
-- EXPLAIN ANALYZE
-- SELECT c.name, w.name 
-- FROM characters c
-- JOIN worlds w ON c.world_id = w.world_id
-- WHERE c.character_id = 1000;

-- Приклад 5: GROUP BY з індексом
-- EXPLAIN ANALYZE
-- SELECT world_id, COUNT(*) 
-- FROM characters 
-- GROUP BY world_id;

-- ============================================================================
-- ВИДАЛЕННЯ ВСІХ КАСТОМНИХ ІНДЕКСІВ (якщо потрібно очистити)
-- ============================================================================

-- Видалення індексів з таблиці characters
DROP INDEX IF EXISTS idx_characters_world_id;
DROP INDEX IF EXISTS idx_characters_name;
DROP INDEX IF EXISTS idx_characters_world_id_include_id;

-- Видалення індексів з таблиці works
DROP INDEX IF EXISTS idx_works_world_id;
DROP INDEX IF EXISTS idx_works_world_id_status;
DROP INDEX IF EXISTS idx_works_created_year;
DROP INDEX IF EXISTS idx_works_synopsis_fts;

-- Видалення індексів з таблиці chapters
DROP INDEX IF EXISTS idx_chapters_work_id;
DROP INDEX IF EXISTS idx_chapters_work_id_number;
DROP INDEX IF EXISTS idx_chapters_work_number;

-- Видалення індексів з таблиці chapter_participation
DROP INDEX IF EXISTS idx_chapter_participation_character_id;
DROP INDEX IF EXISTS idx_chapter_participation_chapter_id;

-- Видалення індексів з таблиці events
DROP INDEX IF EXISTS idx_events_year;

-- Видалення індексів з таблиці worlds
DROP INDEX IF EXISTS idx_worlds_name;

-- Видалення індексів з таблиці locations (якщо є)
DROP INDEX IF EXISTS idx_locations_world_id;

-- Видалення індексів з таблиці timelines (якщо є)
DROP INDEX IF EXISTS idx_timelines_world_id;

-- Видалення індексів з таблиці factions (якщо є)
DROP INDEX IF EXISTS idx_factions_world_id;

-- Видалення індексів з таблиці character_factions (якщо є)
DROP INDEX IF EXISTS idx_character_factions_character_id;
DROP INDEX IF EXISTS idx_character_factions_faction_id;

-- Видалення колонки для повнотекстового пошуку (якщо була додана)
ALTER TABLE works DROP COLUMN IF EXISTS synopsis_fts;

-- ============================================================================
-- КІНЕЦЬ ДАМПУ
-- ============================================================================

