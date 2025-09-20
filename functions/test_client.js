/*
 Simple test client for local/emulator testing.
 Run with: node test_client.js <FIREBASE_ID_TOKEN>
*/
const axios = require('axios');

const token = process.argv[2];
if (!token) {
  console.error('Usage: node test_client.js <FIREBASE_ID_TOKEN>');
  process.exit(1);
}

async function run() {
  try {
    const resp = await axios.post('http://localhost:5001/uacc-uacc/us-central1/geminiProxy', {transcript: 'Hello from test client'}, {
      headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' }
    });
    console.log('Response:', resp.data);
  } catch (e) {
    console.error('Error:', e.response && e.response.data ? e.response.data : e.message);
  }
}

run();
