const express = require('express');
const mariadb = require('mariadb');

const pool = mariadb.createPool({
  host: 'mariadb',
  user: 'app_user',
  password: 'Parolka-12345',
  port: 3306,
  database: 'counters',
  connectionLimit: 5 // Allow up to 5 simultaneous connections
});

const app = express();
const PORT = 5000;

app.get('/', async (req, res) => {
  let conn;
  try {
    // connect to pool
    conn = await pool.getConnection();

    // incremant the counter
    await conn.query("INSERT INTO hits (seen_at) VALUES (NOW())");

    // count the rows to see how many hits we have
    const rows = await conn.query("SELECT COUNT(*) as total FROM hits");

    // convert array of objects to string
    const count = rows[0].total.toString();

    // show message
    const msg = `Hello! This Node app has been viewed ${count} times.\n`;
    res.type('text/plain').send(msg);

  } catch (err) {
    // log the error / HTML code 500 (Database error)
    console.error('Error handling request:', err);
    res.status(500).send('Database Error');
  } finally {
    // releas the connection
    if (conn) conn.release();
  }
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`Server listening on http://0.0.0.0:${PORT}`);
});