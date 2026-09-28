import express from 'express';

const app = express();
const PORT = process.env.PORT || 3000;

app.get('/', (req, res) => {
  res.status(200).json({ status: 'ok', version: process.env.COMMIT_SHA || 'dev' });
});

app.get('/health', (req, res) => {
  res.status(200).send('OK', Date.now());
});

if (process.env.NODE_ENV !== 'test') {
  app.listen(PORT, () => {
    console.log(`Server active on port ${PORT}`);
  });
}

export default app;