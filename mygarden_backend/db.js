const sqlite3 = require('sqlite3').verbose();
const path = require('path');

const dbPath = path.join(__dirname, 'mygarden.db');
const db = new sqlite3.Database(dbPath);

function initDb() {
  db.serialize(() => {
    // Użytkownicy (na razie prosty model)
    db.run(`
      CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    `);

    // Pokoje
    db.run(`
      CREATE TABLE IF NOT EXISTS rooms (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id)
      )
    `);

    // Sekcje
    db.run(`
      CREATE TABLE IF NOT EXISTS sections (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        room_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        FOREIGN KEY (room_id) REFERENCES rooms(id)
      )
    `);

    // Rośliny
    db.run(`
      CREATE TABLE IF NOT EXISTS plants (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        section_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        species TEXT,
        FOREIGN KEY (section_id) REFERENCES sections(id)
      )
    `);

    // Urządzenia
    db.run(`
      CREATE TABLE IF NOT EXISTS devices (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        section_id INTEGER,
        plant_id INTEGER,
        -- ustawienia światła (prosto w tabeli)
        light_start_time TEXT,
        light_end_time TEXT,
        light_sunrise_minutes INTEGER,
        light_sunset_minutes INTEGER,
        light_max_power REAL,
        FOREIGN KEY (section_id) REFERENCES sections(id),
        FOREIGN KEY (plant_id) REFERENCES plants(id)
      )
    `);

    db.get('SELECT COUNT(*) as count FROM users', (err, row) => {
      if (err) {
        console.error('DB error:', err);
        return;
      }
      if (row.count === 0) {
        console.log('Seeding initial data...');
        seedData();
      }
    });
  });
}

function seedData() {
  db.serialize(() => {
    db.run(
      `INSERT INTO users (email, password) VALUES (?, ?)`,
      ['test@test.com', 'test'],
      function (err) {
        if (err) {
          console.error('Error seeding user:', err);
          return;
        }
        const userId = this.lastID;

        db.run(
          `INSERT INTO rooms (user_id, name) VALUES (?, ?)`,
          [userId, 'Salon'],
          function (err) {
            if (err) return console.error(err);
            const salonId = this.lastID;

            db.run(
              `INSERT INTO sections (room_id, name) VALUES (?, ?)`,
              [salonId, 'Półka przy oknie wschodnim'],
              function (err) {
                if (err) return console.error(err);
                const sec1 = this.lastID;

                db.run(
                  `INSERT INTO sections (room_id, name) VALUES (?, ?)`,
                  [salonId, 'Nad fotelem'],
                  function (err) {
                    if (err) return console.error(err);
                    const sec2 = this.lastID;

                    db.run(
                      `INSERT INTO plants (section_id, name, species) VALUES (?, ?, ?)`,
                      [sec1, 'Monstera deliciosa', 'Monstera'],
                    );
                    db.run(
                      `INSERT INTO plants (section_id, name, species) VALUES (?, ?, ?)`,
                      [sec1, 'Fikus benjamina', 'Fikus'],
                    );

                    db.run(
                      `INSERT INTO devices
                      (name, type, section_id, light_start_time, light_end_time,
                       light_sunrise_minutes, light_sunset_minutes, light_max_power)
                      VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
                      [
                        'Sterownik światła salon półka',
                        'lightController',
                        sec1,
                        '08:00',
                        '20:00',
                        30,
                        30,
                        80,
                      ],
                    );

                    db.run(
                      `INSERT INTO devices (name, type, section_id)
                       VALUES (?, ?, ?)`,
                      ['Czujnik powietrza salon', 'airSensor', sec1],
                    );

                    db.run(
                      `INSERT INTO devices (name, type, plant_id)
                       VALUES (?, ?, ?)`,
                      ['Czujnik wilgotności Monstera', 'soilMoistureSensor', 1],
                    );
                  },
                );
              },
            );
          },
        );

        db.run(
          `INSERT INTO rooms (user_id, name) VALUES (?, ?)`,
          [userId, 'Sypialnia'],
        );
      },
    );
  });
}

module.exports = {
  db,
  initDb,
};
