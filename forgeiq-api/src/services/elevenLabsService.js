// ElevenLabsService — server-side proxy for ElevenLabs TTS
// API key lives here only; iOS never talks to ElevenLabs directly

const ELEVEN_LABS_BASE_URL = 'https://api.elevenlabs.io/v1';

async function synthesise(text, voiceId) {
  if (!process.env.ELEVEN_LABS_API_KEY) {
    const err = new Error('ElevenLabs API key not configured');
    err.statusCode = 500;
    throw err;
  }

  const response = await fetch(`${ELEVEN_LABS_BASE_URL}/text-to-speech/${voiceId}`, {
    method: 'POST',
    headers: {
      'xi-api-key': process.env.ELEVEN_LABS_API_KEY,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      text,
      model_id: 'eleven_multilingual_v2',
      voice_settings: {
        stability: 0.5,
        similarity_boost: 0.75
      }
    })
  });

  if (!response.ok) {
    const errorText = await response.text();
    console.error('ElevenLabs API error:', response.status, errorText);
    const err = new Error('ElevenLabs API error');
    err.statusCode = response.status;
    throw err;
  }

  return response;
}

module.exports = { synthesise };
