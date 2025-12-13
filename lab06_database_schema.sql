-- ============================================================================
-- СХЕМА БАЗИ ДАНИХ ДЛЯ ЛАБОРАТОРНОЇ РОБОТИ №6
-- Система управління світами, творами та персонажами
-- ============================================================================

-- Примітка: Це прикладна схема. Адаптуйте під свою реальну структуру БД.

-- ============================================================================
-- ОСНОВНІ ТАБЛИЦІ
-- ============================================================================

-- Таблиця світів
CREATE TABLE IF NOT EXISTS worlds (
    world_id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL UNIQUE,
    genre VARCHAR(100),
    description TEXT,
    character_count INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Таблиця локацій
CREATE TABLE IF NOT EXISTS locations (
    location_id SERIAL PRIMARY KEY,
    world_id INTEGER NOT NULL REFERENCES worlds(world_id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    type VARCHAR(100),
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_location_per_world UNIQUE (world_id, name)
);

-- Таблиця таймлайнів
CREATE TABLE IF NOT EXISTS timelines (
    timeline_id SERIAL PRIMARY KEY,
    world_id INTEGER NOT NULL REFERENCES worlds(world_id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    start_year INTEGER,
    end_year INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Таблиця персонажів
CREATE TABLE IF NOT EXISTS characters (
    character_id SERIAL PRIMARY KEY,
    world_id INTEGER NOT NULL REFERENCES worlds(world_id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    role VARCHAR(100),
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Таблиця творів
CREATE TABLE IF NOT EXISTS works (
    work_id SERIAL PRIMARY KEY,
    world_id INTEGER NOT NULL REFERENCES worlds(world_id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    synopsis TEXT,
    status VARCHAR(50) DEFAULT 'draft' CHECK (status IN ('draft', 'in_progress', 'finished')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    finished_at TIMESTAMP
);

-- Таблиця розділів
CREATE TABLE IF NOT EXISTS chapters (
    chapter_id SERIAL PRIMARY KEY,
    work_id INTEGER NOT NULL REFERENCES works(work_id) ON DELETE CASCADE,
    number INTEGER NOT NULL,
    title VARCHAR(255) NOT NULL,
    content TEXT,
    status VARCHAR(50) DEFAULT 'draft' CHECK (status IN ('draft', 'in_progress', 'finished')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_chapter_number_per_work UNIQUE (work_id, number)
);

-- Таблиця участі персонажів у розділах
CREATE TABLE IF NOT EXISTS chapter_participation (
    participation_id SERIAL PRIMARY KEY,
    chapter_id INTEGER NOT NULL REFERENCES chapters(chapter_id) ON DELETE CASCADE,
    character_id INTEGER NOT NULL REFERENCES characters(character_id) ON DELETE CASCADE,
    location_id INTEGER REFERENCES locations(location_id) ON DELETE SET NULL,
    scene_role VARCHAR(50) DEFAULT 'participant',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Таблиця подій
CREATE TABLE IF NOT EXISTS events (
    event_id SERIAL PRIMARY KEY,
    timeline_id INTEGER NOT NULL REFERENCES timelines(timeline_id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    year INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Таблиця фракцій
CREATE TABLE IF NOT EXISTS factions (
    faction_id SERIAL PRIMARY KEY,
    world_id INTEGER NOT NULL REFERENCES worlds(world_id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_faction_per_world UNIQUE (world_id, name)
);

-- Таблиця зв'язків персонажів з фракціями
CREATE TABLE IF NOT EXISTS character_factions (
    character_faction_id SERIAL PRIMARY KEY,
    character_id INTEGER NOT NULL REFERENCES characters(character_id) ON DELETE CASCADE,
    faction_id INTEGER NOT NULL REFERENCES factions(faction_id) ON DELETE CASCADE,
    role VARCHAR(100),
    joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_character_faction UNIQUE (character_id, faction_id)
);

-- ============================================================================
-- ІНДЕКСИ ДЛЯ ПРОДУКТИВНОСТІ
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_characters_world_id ON characters(world_id);
CREATE INDEX IF NOT EXISTS idx_characters_name ON characters(name);
CREATE INDEX IF NOT EXISTS idx_locations_world_id ON locations(world_id);
CREATE INDEX IF NOT EXISTS idx_timelines_world_id ON timelines(world_id);
CREATE INDEX IF NOT EXISTS idx_works_world_id ON works(world_id);
CREATE INDEX IF NOT EXISTS idx_works_status ON works(status);
CREATE INDEX IF NOT EXISTS idx_chapters_work_id ON chapters(work_id);
CREATE INDEX IF NOT EXISTS idx_chapter_participation_chapter_id ON chapter_participation(chapter_id);
CREATE INDEX IF NOT EXISTS idx_chapter_participation_character_id ON chapter_participation(character_id);
CREATE INDEX IF NOT EXISTS idx_events_timeline_id ON events(timeline_id);
CREATE INDEX IF NOT EXISTS idx_events_year ON events(year);
CREATE INDEX IF NOT EXISTS idx_factions_world_id ON factions(world_id);
CREATE INDEX IF NOT EXISTS idx_character_factions_character_id ON character_factions(character_id);
CREATE INDEX IF NOT EXISTS idx_character_factions_faction_id ON character_factions(faction_id);

-- ============================================================================
-- ТЕСТОВІ ДАНІ (ОПЦІОНАЛЬНО)
-- ============================================================================

-- Вставка тестових даних для перевірки функцій
/*
INSERT INTO worlds (name, genre, description) VALUES
('Світ Фентезі', 'Фентезі', 'Магічний світ з драконами та чарівниками'),
('Наукова Фантастика', 'Sci-Fi', 'Майбутнє з космічними подорожями');

INSERT INTO characters (world_id, name, role) VALUES
(1, 'Арагорн', 'Король'),
(1, 'Гендальф', 'Чарівник'),
(2, 'Капітан Кірк', 'Капітан');

INSERT INTO works (world_id, title, status) VALUES
(1, 'Володар Перстенів', 'finished'),
(1, 'Новий Твір', 'in_progress');
*/

-- ============================================================================
-- КОМЕНТАРІ ДО СХЕМИ
-- ============================================================================

COMMENT ON TABLE worlds IS 'Світи, в яких розгортаються історії';
COMMENT ON TABLE characters IS 'Персонажі, що населяють світи';
COMMENT ON TABLE works IS 'Твори (книги, історії) у світах';
COMMENT ON TABLE chapters IS 'Розділи творів';
COMMENT ON TABLE chapter_participation IS 'Участь персонажів у розділах';
COMMENT ON TABLE locations IS 'Локації у світах';
COMMENT ON TABLE timelines IS 'Хронології подій у світах';
COMMENT ON TABLE events IS 'Події в таймлайнах';
COMMENT ON TABLE factions IS 'Фракції та організації у світах';
COMMENT ON TABLE character_factions IS 'Зв''язки персонажів з фракціями';

