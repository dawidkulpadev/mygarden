const express = require('express');
const cors = require('cors');
const { db, initDb } = require('./db');

const app = express();

const PORT = process.env.PORT || 3000;

const FRONTEND_ORIGINS = [
  'http://localhost:3000',
  'http://localhost:4200',
  'http://localhost:8080',
  'http://127.0.0.1:5500',
  'https://dawidkulpa.pl',
  'https://www.dawidkulpa.pl',
];

const BASE_PATH = process.env.BASE_PATH || '/sggw/mygarden';

app.use(cors());

app.use(express.json());

initDb();

const router = express.Router();

router.get('/health', (req, res) => {
  res.json({ status: 'ok' });
});

router.post('/login', (req, res) => {
  const { email, password } = req.body;

  db.get(
    'SELECT id, email FROM users WHERE email = ? AND password = ?',
    [email, password],
    (err, row) => {
      if (err) {
        console.error(err);
        return res.status(500).json({ error: 'DB error' });
      }
      if (!row) {
        return res.status(401).json({ error: 'Invalid credentials' });
      }
      res.json({ userId: row.id, email: row.email });
    },
  );
});

router.get('/rooms', (req, res) => {
  const userId = req.query.userId || 1;

  db.all(
    'SELECT id, name FROM rooms WHERE user_id = ? ORDER BY id',
    [userId],
    (err, rows) => {
      if (err) {
        console.error(err);
        return res.status(500).json({ error: 'DB error' });
      }
      res.json(rows);
    },
  );
});

router.get('/rooms/:roomId/full', (req, res) => {
  const roomId = req.params.roomId;

  db.all(
    'SELECT id, name FROM sections WHERE room_id = ? ORDER BY id',
    [roomId],
    (err, sectionRows) => {
      if (err) {
        console.error(err);
        return res.status(500).json({ error: 'DB error' });
      }

      if (sectionRows.length === 0) {
        return res.json({ sections: [] });
      }

      const sectionIds = sectionRows.map((s) => s.id);

      db.all(
        `SELECT id, section_id, name, species
         FROM plants
         WHERE section_id IN (${sectionIds.map(() => '?').join(',')})
         ORDER BY id`,
        sectionIds,
        (err, plantRows) => {
          if (err) {
            console.error(err);
            return res.status(500).json({ error: 'DB error' });
          }

          db.all(
            `SELECT *
             FROM devices
             WHERE (section_id IN (${sectionIds.map(() => '?').join(',')})
               OR plant_id IN (
                 SELECT id FROM plants WHERE section_id IN (${sectionIds
                   .map(() => '?')
                   .join(',')})
               ))`,
            [...sectionIds, ...sectionIds],
            (err, deviceRows) => {
              if (err) {
                console.error(err);
                return res.status(500).json({ error: 'DB error' });
              }

              const sections = sectionRows.map((s) => {
                const sPlants = plantRows.filter((p) => p.section_id === s.id);
                const sectionDevices = deviceRows.filter(
                  (d) =>
                    d.section_id === s.id && d.type !== 'soilMoistureSensor',
                );

                const plantsWithSensors = sPlants.map((p) => {
                  const sensor = deviceRows.find(
                    (d) =>
                      d.type === 'soilMoistureSensor' && d.plant_id === p.id,
                  );
                  return {
                    ...p,
                    moistureSensor: sensor || null,
                  };
                });

                return {
                  id: s.id,
                  name: s.name,
                  plants: plantsWithSensors,
                  devices: sectionDevices,
                };
              });

              res.json({ sections });
            },
          );
        },
      );
    },
  );
});

router.post('/rooms', (req, res) => {
  const { userId, name } = req.body;
  if (!userId || !name) {
    return res.status(400).json({ error: 'userId i name są wymagane' });
  }

  db.run(
    `INSERT INTO rooms (user_id, name) VALUES (?, ?)`,
    [userId, name],
    function (err) {
      if (err) {
        console.error(err);
        return res.status(500).json({ error: 'DB error' });
      }
      res.status(201).json({ id: this.lastID, name });
    },
  );
});


router.post('/sections', (req, res) => {
  const { roomId, name } = req.body;
  if (!roomId || !name) {
    return res.status(400).json({ error: 'roomId i name są wymagane' });
  }

  db.run(
    `INSERT INTO sections (room_id, name) VALUES (?, ?)`,
    [roomId, name],
    function (err) {
      if (err) {
        console.error(err);
        return res.status(500).json({ error: 'DB error' });
      }
      res.status(201).json({ id: this.lastID, name });
    },
  );
});

router.post('/plants', (req, res) => {
  const { sectionId, name, species } = req.body;
  if (!sectionId || !name) {
    return res.status(400).json({ error: 'sectionId i name są wymagane' });
  }

  db.run(
    `INSERT INTO plants (section_id, name, species) VALUES (?, ?, ?)`,
    [sectionId, name, species || null],
    function (err) {
      if (err) {
        console.error(err);
        return res.status(500).json({ error: 'DB error' });
      }
      res.status(201).json({
        id: this.lastID,
        section_id: sectionId,
        name,
        species: species || null,
      });
    },
  );
});

router.post('/devices', (req, res) => {
  const {
    name,
    type,
    sectionId,
    plantId,
    light_start_time,
    light_end_time,
    light_sunrise_minutes,
    light_sunset_minutes,
    light_max_power,
  } = req.body;

  if (!name || !type) {
    return res.status(400).json({ error: 'name i type są wymagane' });
  }

  db.run(
    `INSERT INTO devices
     (name, type, section_id, plant_id, light_start_time, light_end_time,
      light_sunrise_minutes, light_sunset_minutes, light_max_power)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
    [
      name,
      type,
      sectionId || null,
      plantId || null,
      light_start_time || null,
      light_end_time || null,
      light_sunrise_minutes || null,
      light_sunset_minutes || null,
      light_max_power || null,
    ],
    function (err) {
      if (err) {
        console.error(err);
        return res.status(500).json({ error: 'DB error' });
      }
      res.status(201).json({
        id: this.lastID,
        name,
        type,
        section_id: sectionId || null,
        plant_id: plantId || null,
        light_start_time,
        light_end_time,
        light_sunrise_minutes,
        light_sunset_minutes,
        light_max_power,
      });
    },
  );
});

router.put('/devices/:id', (req, res) => {
  const id = req.params.id;
  const { name } = req.body;

  if (!name) {
    return res.status(400).json({ error: 'name jest wymagane' });
  }

  db.run(
    `UPDATE devices SET name = ? WHERE id = ?`,
    [name, id],
    function (err) {
      if (err) {
        console.error(err);
        return res.status(500).json({ error: 'DB error' });
      }
      if (this.changes === 0) {
        return res.status(404).json({ error: 'Device not found' });
      }

      db.get(
        `SELECT * FROM devices WHERE id = ?`,
        [id],
        (err, row) => {
          if (err) {
            console.error(err);
            return res.status(500).json({ error: 'DB error' });
          }
          res.json(row);
        },
      );
    },
  );
});


router.delete('/devices/:id', (req, res) => {
  const id = req.params.id;
  db.run(`DELETE FROM devices WHERE id = ?`, [id], function (err) {
    if (err) {
      console.error(err);
      return res.status(500).json({ error: 'DB error' });
    }
    if (this.changes === 0) {
      return res.status(404).json({ error: 'Device not found' });
    }
    res.status(204).end();
  });
});

app.use(BASE_PATH, router);

app.listen(PORT, () => {
  console.log(`IoT Garden backend running on port ${PORT}`);
});