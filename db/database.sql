
CREATE TABLE users (
  id SERIAL PRIMARY KEY,
  username VARCHAR(255) NOT NULL,
  password_digest VARCHAR(255),
  session_token VARCHAR(255)
);

CREATE TABLE bands (
  id SERIAL PRIMARY KEY,
  name VARCHAR(255) NOT NULL
);

CREATE TABLE albums (
  id SERIAL PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  band_id INTEGER NOT NULL,
  year INTEGER NOT NULL,
  live BOOLEAN NOT NULL DEFAULT false,

  FOREIGN KEY(band_id) REFERENCES bands (id) ON DELETE CASCADE
);


CREATE TABLE notes (
  id SERIAL PRIMARY KEY,
  content TEXT NOT NULL,
  track_id INTEGER NOT NULL,
  user_id INTEGER NOT NULL,

  FOREIGN KEY(track_id) REFERENCES tracks (id) ON DELETE CASCADE,
  FOREIGN KEY(user_id) REFERENCES users (id) ON DELETE CASCADE
);

CREATE TABLE tracks (
  id SERIAL PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  album_id INTEGER NOT NULL,
  ord INTEGER NOT NULL,
  bonus BOOLEAN NOT NULL DEFAULT false,
  lyrics TEXT NOT NULL,

  FOREIGN KEY(album_id) REFERENCES albums (id) ON DELETE CASCADE
);


-- INSERT INTO
--   bands (id, name )
-- VALUES
--   (1, "the little a's"), (2, "THE BIG A's");

-- INSERT INTO
--   users (id, username, house_id)
-- VALUES
--   (1, "Devon", 1),
--   (2, "Matt", 1),
--   (3, "Ned", 2),
--   (4, "Catless", NULL);

-- INSERT INTO
--   cats (id, name, owner_id)
-- VALUES
--   (1, "Breakfast", 1),
--   (2, "Earl", 2),
--   (3, "Haskell", 3),
--   (4, "Markov", 3),
--   (5, "Stray Cat", NULL);
