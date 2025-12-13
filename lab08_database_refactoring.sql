-- ============================================================================
-- ЛАБОРАТОРНА РОБОТА №8
-- Рефакторинг та оптимізація структури бази даних
-- Система управління світами, творами та персонажами
-- ================= ===========================================================

-- ============================================================================
-- ЗАВДАННЯ 1: НОВИЙ БІЗНЕС-ПРОЦЕС - СИСТЕМА КОМЕНТАРІВ ТА ВІДГУКІВ
-- ============================================================================

-- Концептуальний опис:
-- Додаємо можливість користувачам залишати коментарі та відгуки до творів.
-- Користувачі можуть коментувати твори, ставити оцінки, відповідати на коментарі.
-- Це потребує нових таблиць: users, comments, ratings.

-- Створення композитного типу для адреси локації
-- (використовується в завданні 6)
CREATE TYPE address_type AS (
    street VARCHAR(255),
    city VARCHAR(100),
    country VARCHAR(100),
    coordinates POINT
);

-- Створення композитного типу для ПІБ персонажа
-- (використовується в завданні 6)
CREATE TYPE full_name_type AS (
    first_name VARCHAR(100),
    middle_name VARCHAR(100),
    last_name VARCHAR(100)
);

-- ============================================================================
-- ЗАВДАННЯ 1: РОЗШИРЕННЯ СТРУКТУРИ - НОВІ ТАБЛИЦІ
-- ============================================================================

-- а) Розширення існуючої таблиці works - додаємо поле для середньої оцінки
-- (денормалізація для швидших запитів)
ALTER TABLE works 
ADD COLUMN IF NOT EXISTS average_rating DECIMAL(3,2) DEFAULT 0.00,
ADD COLUMN IF NOT EXISTS total_ratings INTEGER DEFAULT 0;

-- б) Нова таблиця користувачів (для системи коментарів)
CREATE TABLE IF NOT EXISTS users (
    user_id SERIAL PRIMARY KEY,
    username VARCHAR(100) NOT NULL UNIQUE,
    email VARCHAR(255) NOT NULL UNIQUE,
    full_name full_name_type,  -- Композитний тип для ПІБ
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- в) Нова таблиця коментарів до творів
CREATE TABLE IF NOT EXISTS comments (
    comment_id SERIAL PRIMARY KEY,
    work_id INTEGER NOT NULL REFERENCES works(work_id) ON DELETE CASCADE,
    user_id INTEGER NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    parent_comment_id INTEGER REFERENCES comments(comment_id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_edited BOOLEAN DEFAULT FALSE,
    is_deleted BOOLEAN DEFAULT FALSE
);

-- г) Нова таблиця оцінок творів
CREATE TABLE IF NOT EXISTS ratings (
    rating_id SERIAL PRIMARY KEY,
    work_id INTEGER NOT NULL REFERENCES works(work_id) ON DELETE CASCADE,
    user_id INTEGER NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    rating_value INTEGER NOT NULL CHECK (rating_value BETWEEN 1 AND 5),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_user_work_rating UNIQUE (user_id, work_id)
);

-- ============================================================================
-- ЗАВДАННЯ 2: ВИПРАВЛЕННЯ ЛОГІЧНИХ НЕДОЛІКІВ
-- ============================================================================

-- а) Додаємо історію змін (версіонування) для творів
-- Проблема: немає збереження історії змін, не можна відстежити, хто і коли змінив
CREATE TABLE IF NOT EXISTS work_history (
    history_id SERIAL PRIMARY KEY,
    work_id INTEGER NOT NULL REFERENCES works(work_id) ON DELETE CASCADE,
    changed_by INTEGER REFERENCES users(user_id) ON DELETE SET NULL,
    change_type VARCHAR(50) NOT NULL CHECK (change_type IN ('created', 'updated', 'status_changed', 'deleted')),
    old_value TEXT,
    new_value TEXT,
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    description TEXT
);

-- б) Додаємо поле для відстеження актуальності даних
-- Проблема: немає інформації про те, коли дані стали застарілими
ALTER TABLE works 
ADD COLUMN IF NOT EXISTS is_archived BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS archived_at TIMESTAMP,
ADD COLUMN IF NOT EXISTS archived_reason TEXT;

ALTER TABLE characters 
ADD COLUMN IF NOT EXISTS is_archived BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS archived_at TIMESTAMP;

-- в) Додаємо стадії виконання для розділів
-- Проблема: статус 'draft'/'in_progress'/'finished' недостатньо детальний
CREATE TYPE chapter_stage_type AS ENUM (
    'planned',      -- Заплановано
    'outline',      -- Конспект
    'draft',        -- Чернетка
    'first_review', -- Перший перегляд
    'editing',      -- Редагування
    'final_review', -- Фінальний перегляд
    'finished'      -- Завершено
);

ALTER TABLE chapters 
DROP COLUMN IF EXISTS status;

ALTER TABLE chapters 
ADD COLUMN stage chapter_stage_type DEFAULT 'planned';

-- ============================================================================
-- ЗАВДАННЯ 3: ВИПРАВЛЕННЯ СТРУКТУРНИХ НЕДОЛІКІВ
-- ============================================================================

-- а) Виправлення некоректної кардинальності - додаємо зв'язок many-to-many між персонажами та локаціями
-- Проблема: персонаж може бути тільки в одній локації через chapter_participation
CREATE TABLE IF NOT EXISTS character_locations (
    character_location_id SERIAL PRIMARY KEY,
    character_id INTEGER NOT NULL REFERENCES characters(character_id) ON DELETE CASCADE,
    location_id INTEGER NOT NULL REFERENCES locations(location_id) ON DELETE CASCADE,
    visit_date TIMESTAMP,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_character_location UNIQUE (character_id, location_id)
);

-- б) Уніфікація назв колонок - замінюємо description на notes там, де це доречно
-- (залишаємо як є, бо це не критично, але додаємо коментарі)

-- в) Додаємо обмеження цілісності для дат
-- Проблема: немає перевірки, що start_year < end_year
ALTER TABLE timelines 
ADD CONSTRAINT check_timeline_years 
CHECK (start_year IS NULL OR end_year IS NULL OR start_year <= end_year);

-- г) Додаємо обмеження для дат завершення творів
-- Проблема: finished_at може бути раніше за created_at
ALTER TABLE works 
ADD CONSTRAINT check_work_dates 
CHECK (finished_at IS NULL OR finished_at >= created_at);

-- д) Виправлення типу даних - додаємо композитний тип для адреси локації
-- Проблема: адреса може бути складною структурою
ALTER TABLE locations 
ADD COLUMN IF NOT EXISTS address address_type;

-- ============================================================================
-- ЗАВДАННЯ 4: НОРМАЛІЗАЦІЯ (1-3 НФ)
-- ============================================================================

-- а) Виявлення порушення атомарності - розділяємо full_name на окремі поля
-- Проблема: full_name_type вже є композитним, але для нормалізації можна розділити
-- (залишаємо композитний тип, бо він зручніший для використання)

-- б) Виявлення однакових доменів - об'єднуємо описи в окрему таблицю
-- Проблема: description є в багатьох таблицях з однаковою структурою
CREATE TABLE IF NOT EXISTS descriptions (
    description_id SERIAL PRIMARY KEY,
    entity_type VARCHAR(50) NOT NULL,  -- 'world', 'character', 'work', 'location'
    entity_id INTEGER NOT NULL,
    content TEXT NOT NULL,
    language VARCHAR(10) DEFAULT 'uk',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_entity_description UNIQUE (entity_type, entity_id, language)
);

-- в) Виявлення функціональних залежностей
-- Проблема: character_count в worlds залежить від characters, але не є частиною PK
-- Рішення: залишаємо для денормалізації (швидші запити), але додаємо тригер для синхронізації

-- ============================================================================
-- ЗАВДАННЯ 5: ДЕНОРМАЛІЗАЦІЯ ДЛЯ ОПТИМІЗАЦІЇ
-- ============================================================================

-- а) Додаємо денормалізовані поля для швидких запитів
-- average_rating та total_ratings вже додано в завданні 1

-- б) Додаємо поле для зберігання кількості коментарів
ALTER TABLE works 
ADD COLUMN IF NOT EXISTS comment_count INTEGER DEFAULT 0;

-- в) Створюємо допоміжну таблицю для статистики світів (дублювання інформації)
CREATE TABLE IF NOT EXISTS world_statistics (
    world_id INTEGER PRIMARY KEY REFERENCES worlds(world_id) ON DELETE CASCADE,
    total_characters INTEGER DEFAULT 0,
    total_works INTEGER DEFAULT 0,
    total_locations INTEGER DEFAULT 0,
    total_events INTEGER DEFAULT 0,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- ЗАВДАННЯ 6: КОМПОЗИТНІ ТИПИ ДАНИХ
-- ============================================================================

-- Композитні типи вже створені на початку:
-- - address_type для адрес локацій
-- - full_name_type для ПІБ користувачів

-- Додаємо використання композитного типу для адреси
-- (вже додано в завданні 3)

-- Додаємо композитний тип для координат локації (якщо потрібно)
-- (вже включено в address_type як POINT)

-- ============================================================================
-- ЗАВДАННЯ 7: МІГРАЦІЯ ДАНИХ
-- ============================================================================

-- а) Перенесення даних description в нову таблицю descriptions
-- (опціонально, якщо потрібна нормалізація)

-- б) Оновлення денормалізованих полів на основі існуючих даних
-- Оновлюємо average_rating та total_ratings (якщо є дані)
UPDATE works w
SET 
    average_rating = COALESCE((
        SELECT AVG(rating_value::DECIMAL)
        FROM ratings r
        WHERE r.work_id = w.work_id
    ), 0.00),
    total_ratings = COALESCE((
        SELECT COUNT(*)
        FROM ratings r
        WHERE r.work_id = w.work_id
    ), 0);

-- Оновлюємо comment_count
UPDATE works w
SET comment_count = COALESCE((
    SELECT COUNT(*)
    FROM comments c
    WHERE c.work_id = w.work_id AND c.is_deleted = FALSE
), 0);

-- Оновлюємо world_statistics
INSERT INTO world_statistics (world_id, total_characters, total_works, total_locations, total_events)
SELECT 
    w.world_id,
    (SELECT COUNT(*) FROM characters c WHERE c.world_id = w.world_id),
    (SELECT COUNT(*) FROM works wo WHERE wo.world_id = w.world_id),
    (SELECT COUNT(*) FROM locations l WHERE l.world_id = w.world_id),
    (SELECT COUNT(*) FROM events e 
     JOIN timelines t ON e.timeline_id = t.timeline_id 
     WHERE t.world_id = w.world_id)
FROM worlds w
ON CONFLICT (world_id) DO UPDATE SET
    total_characters = EXCLUDED.total_characters,
    total_works = EXCLUDED.total_works,
    total_locations = EXCLUDED.total_locations,
    total_events = EXCLUDED.total_events,
    last_updated = CURRENT_TIMESTAMP;

-- Оновлюємо character_count в worlds (денормалізація)
UPDATE worlds w
SET character_count = (
    SELECT COUNT(*)
    FROM characters c
    WHERE c.world_id = w.world_id
);

-- ============================================================================
-- ЗАВДАННЯ 8: ІНДЕКСИ ТА ОБМЕЖЕННЯ
-- ============================================================================

-- Створення індексів для нових таблиць
CREATE INDEX IF NOT EXISTS idx_comments_work_id ON comments(work_id);
CREATE INDEX IF NOT EXISTS idx_comments_user_id ON comments(user_id);
CREATE INDEX IF NOT EXISTS idx_comments_parent_id ON comments(parent_comment_id);
CREATE INDEX IF NOT EXISTS idx_comments_created_at ON comments(created_at);

CREATE INDEX IF NOT EXISTS idx_ratings_work_id ON ratings(work_id);
CREATE INDEX IF NOT EXISTS idx_ratings_user_id ON ratings(user_id);
CREATE INDEX IF NOT EXISTS idx_ratings_value ON ratings(rating_value);

CREATE INDEX IF NOT EXISTS idx_work_history_work_id ON work_history(work_id);
CREATE INDEX IF NOT EXISTS idx_work_history_changed_at ON work_history(changed_at);

CREATE INDEX IF NOT EXISTS idx_character_locations_character_id ON character_locations(character_id);
CREATE INDEX IF NOT EXISTS idx_character_locations_location_id ON character_locations(location_id);

CREATE INDEX IF NOT EXISTS idx_descriptions_entity ON descriptions(entity_type, entity_id);

-- Додаткові обмеження цілісності (виконуються останніми)
-- Перевірка, що parent_comment_id належить тому ж work_id
CREATE OR REPLACE FUNCTION check_comment_parent()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.parent_comment_id IS NOT NULL THEN
        IF (SELECT work_id FROM comments WHERE comment_id = NEW.parent_comment_id) != NEW.work_id THEN
            RAISE EXCEPTION 'Parent comment must belong to the same work';
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_check_comment_parent
BEFORE INSERT OR UPDATE ON comments
FOR EACH ROW
EXECUTE FUNCTION check_comment_parent();

-- ============================================================================
-- ЗАВДАННЯ 8: ТРИГЕРИ ДЛЯ СИНХРОНІЗАЦІЇ ДЕНОРМАЛІЗОВАНИХ ДАНИХ
-- ============================================================================

-- Тригер для оновлення average_rating та total_ratings при додаванні/зміні оцінки
CREATE OR REPLACE FUNCTION update_work_rating_stats()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE works
    SET 
        average_rating = (
            SELECT AVG(rating_value::DECIMAL)
            FROM ratings
            WHERE work_id = COALESCE(NEW.work_id, OLD.work_id)
        ),
        total_ratings = (
            SELECT COUNT(*)
            FROM ratings
            WHERE work_id = COALESCE(NEW.work_id, OLD.work_id)
        )
    WHERE work_id = COALESCE(NEW.work_id, OLD.work_id);
    
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_work_rating_stats
AFTER INSERT OR UPDATE OR DELETE ON ratings
FOR EACH ROW
EXECUTE FUNCTION update_work_rating_stats();

-- Тригер для оновлення comment_count
CREATE OR REPLACE FUNCTION update_work_comment_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        IF NEW.is_deleted = FALSE THEN
            UPDATE works
            SET comment_count = comment_count + 1
            WHERE work_id = NEW.work_id;
        END IF;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        IF OLD.is_deleted = FALSE THEN
            UPDATE works
            SET comment_count = GREATEST(comment_count - 1, 0)
            WHERE work_id = OLD.work_id;
        END IF;
        RETURN OLD;
    ELSIF TG_OP = 'UPDATE' THEN
        -- Якщо коментар був видалений або відновлений
        IF OLD.is_deleted != NEW.is_deleted THEN
            IF NEW.is_deleted = TRUE THEN
                -- Коментар видалено
                UPDATE works
                SET comment_count = GREATEST(comment_count - 1, 0)
                WHERE work_id = NEW.work_id;
            ELSE
                -- Коментар відновлено
                UPDATE works
                SET comment_count = comment_count + 1
                WHERE work_id = NEW.work_id;
            END IF;
        END IF;
        RETURN NEW;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_work_comment_count
AFTER INSERT OR UPDATE OR DELETE ON comments
FOR EACH ROW
EXECUTE FUNCTION update_work_comment_count();

-- Тригер для оновлення character_count в worlds
CREATE OR REPLACE FUNCTION update_world_character_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE worlds
        SET character_count = character_count + 1
        WHERE world_id = NEW.world_id;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE worlds
        SET character_count = GREATEST(character_count - 1, 0)
        WHERE world_id = OLD.world_id;
        RETURN OLD;
    ELSIF TG_OP = 'UPDATE' AND OLD.world_id != NEW.world_id THEN
        UPDATE worlds
        SET character_count = GREATEST(character_count - 1, 0)
        WHERE world_id = OLD.world_id;
        UPDATE worlds
        SET character_count = character_count + 1
        WHERE world_id = NEW.world_id;
        RETURN NEW;
    END IF;
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_world_character_count
AFTER INSERT OR UPDATE OR DELETE ON characters
FOR EACH ROW
EXECUTE FUNCTION update_world_character_count();

-- Тригер для оновлення world_statistics для characters
CREATE OR REPLACE FUNCTION update_world_statistics_characters()
RETURNS TRIGGER AS $$
DECLARE
    v_world_id INTEGER;
BEGIN
    IF TG_OP = 'DELETE' THEN
        v_world_id := OLD.world_id;
    ELSIF TG_OP = 'UPDATE' AND OLD.world_id != NEW.world_id THEN
        -- Оновлюємо обидва світи
        v_world_id := OLD.world_id;
        PERFORM update_single_world_stats(v_world_id);
        v_world_id := NEW.world_id;
    ELSE
        v_world_id := NEW.world_id;
    END IF;
    
    PERFORM update_single_world_stats(v_world_id);
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- Тригер для оновлення world_statistics для works
CREATE OR REPLACE FUNCTION update_world_statistics_works()
RETURNS TRIGGER AS $$
DECLARE
    v_world_id INTEGER;
BEGIN
    IF TG_OP = 'DELETE' THEN
        v_world_id := OLD.world_id;
    ELSIF TG_OP = 'UPDATE' AND OLD.world_id != NEW.world_id THEN
        v_world_id := OLD.world_id;
        PERFORM update_single_world_stats(v_world_id);
        v_world_id := NEW.world_id;
    ELSE
        v_world_id := NEW.world_id;
    END IF;
    
    PERFORM update_single_world_stats(v_world_id);
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- Тригер для оновлення world_statistics для locations
CREATE OR REPLACE FUNCTION update_world_statistics_locations()
RETURNS TRIGGER AS $$
DECLARE
    v_world_id INTEGER;
BEGIN
    IF TG_OP = 'DELETE' THEN
        v_world_id := OLD.world_id;
    ELSIF TG_OP = 'UPDATE' AND OLD.world_id != NEW.world_id THEN
        v_world_id := OLD.world_id;
        PERFORM update_single_world_stats(v_world_id);
        v_world_id := NEW.world_id;
    ELSE
        v_world_id := NEW.world_id;
    END IF;
    
    PERFORM update_single_world_stats(v_world_id);
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- Допоміжна функція для оновлення статистики одного світу
CREATE OR REPLACE FUNCTION update_single_world_stats(p_world_id INTEGER)
RETURNS VOID AS $$
BEGIN
    INSERT INTO world_statistics (world_id, total_characters, total_works, total_locations, total_events, last_updated)
    SELECT 
        p_world_id,
        (SELECT COUNT(*) FROM characters c WHERE c.world_id = p_world_id),
        (SELECT COUNT(*) FROM works wo WHERE wo.world_id = p_world_id),
        (SELECT COUNT(*) FROM locations l WHERE l.world_id = p_world_id),
        (SELECT COUNT(*) FROM events e 
         JOIN timelines t ON e.timeline_id = t.timeline_id 
         WHERE t.world_id = p_world_id),
        CURRENT_TIMESTAMP
    ON CONFLICT (world_id) DO UPDATE SET
        total_characters = EXCLUDED.total_characters,
        total_works = EXCLUDED.total_works,
        total_locations = EXCLUDED.total_locations,
        total_events = EXCLUDED.total_events,
        last_updated = CURRENT_TIMESTAMP;
END;
$$ LANGUAGE plpgsql;

-- Тригери для різних таблиць
CREATE TRIGGER trigger_update_world_statistics_characters
AFTER INSERT OR UPDATE OR DELETE ON characters
FOR EACH ROW
EXECUTE FUNCTION update_world_statistics_characters();

CREATE TRIGGER trigger_update_world_statistics_works
AFTER INSERT OR UPDATE OR DELETE ON works
FOR EACH ROW
EXECUTE FUNCTION update_world_statistics_works();

CREATE TRIGGER trigger_update_world_statistics_locations
AFTER INSERT OR UPDATE OR DELETE ON locations
FOR EACH ROW
EXECUTE FUNCTION update_world_statistics_locations();

-- ============================================================================
-- ЗАВДАННЯ 8: ТРИГЕР ДЛЯ ІСТОРІЇ ЗМІН
-- ============================================================================

-- Тригер для автоматичного запису історії змін творів
CREATE OR REPLACE FUNCTION log_work_history()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO work_history (work_id, changed_by, change_type, new_value, description)
        VALUES (NEW.work_id, NULL, 'created', NEW.title, 'Work created');
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
        IF OLD.title != NEW.title THEN
            INSERT INTO work_history (work_id, changed_by, change_type, old_value, new_value, description)
            VALUES (NEW.work_id, NULL, 'updated', OLD.title, NEW.title, 'Title changed');
        END IF;
        IF OLD.status != NEW.status THEN
            INSERT INTO work_history (work_id, changed_by, change_type, old_value, new_value, description)
            VALUES (NEW.work_id, NULL, 'status_changed', OLD.status, NEW.status, 'Status changed');
        END IF;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO work_history (work_id, changed_by, change_type, old_value, description)
        VALUES (OLD.work_id, NULL, 'deleted', OLD.title, 'Work deleted');
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_log_work_history
AFTER INSERT OR UPDATE OR DELETE ON works
FOR EACH ROW
EXECUTE FUNCTION log_work_history();

-- ============================================================================
-- КОМЕНТАРІ ДО ЗМІН
-- ============================================================================

COMMENT ON TABLE users IS 'Користувачі системи (новий бізнес-процес)';
COMMENT ON TABLE comments IS 'Коментарі до творів (новий бізнес-процес)';
COMMENT ON TABLE ratings IS 'Оцінки творів (новий бізнес-процес)';
COMMENT ON TABLE work_history IS 'Історія змін творів (виправлення логічного недоліку)';
COMMENT ON TABLE character_locations IS 'Зв''язок many-to-many між персонажами та локаціями (виправлення структурного недоліку)';
COMMENT ON TABLE descriptions IS 'Централізоване зберігання описів (нормалізація)';
COMMENT ON TABLE world_statistics IS 'Денормалізована статистика світів (денормалізація для оптимізації)';

COMMENT ON TYPE address_type IS 'Композитний тип для адреси локації';
COMMENT ON TYPE full_name_type IS 'Композитний тип для ПІБ користувача';
COMMENT ON TYPE chapter_stage_type IS 'Тип для стадій виконання розділів';

COMMENT ON COLUMN works.average_rating IS 'Денормалізоване поле для швидкого доступу до середньої оцінки';
COMMENT ON COLUMN works.total_ratings IS 'Денормалізоване поле для швидкого доступу до кількості оцінок';
COMMENT ON COLUMN works.comment_count IS 'Денормалізоване поле для швидкого доступу до кількості коментарів';
COMMENT ON COLUMN works.is_archived IS 'Поле для відстеження актуальності даних';
COMMENT ON COLUMN chapters.stage IS 'Детальна стадія виконання розділу (виправлення логічного недоліку)';

-- ============================================================================
-- ПЕРЕВІРКА РЕЗУЛЬТАТІВ
-- ============================================================================

-- Перевірка створених таблиць
SELECT table_name, table_type 
FROM information_schema.tables 
WHERE table_schema = 'public' 
ORDER BY table_name;

-- Перевірка створених типів
SELECT typname, typtype 
FROM pg_type 
WHERE typnamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public')
AND typtype IN ('c', 'e')
ORDER BY typname;

-- Перевірка індексів
SELECT indexname, tablename 
FROM pg_indexes 
WHERE schemaname = 'public' 
ORDER BY tablename, indexname;

-- ============================================================================
-- КІНЕЦЬ СКРИПТУ
-- ============================================================================

