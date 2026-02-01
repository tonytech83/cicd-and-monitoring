const express = require('express');
const app      = express();
const PORT     = 5000;

let count = 0;

app.get('/', (req, res) => {
  count += 1;
  const msg = `Hello! This Node app has been viewed ${count} times.\n`;
  res.type('text/plain').send(msg);
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`Server listening on http://0.0.0.0:${PORT}`);
});