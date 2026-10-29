// Vercel serverless function: Gemini key server-e thake, browser e jay na
module.exports = async (req, res) => {
  if (req.method !== 'POST') return res.status(405).json({ error: 'POST only' });
  try {
    const { image, mime } = req.body || {};
    if (!image) return res.status(400).json({ error: 'No image' });
    const r = await fetch('https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'x-goog-api-key': process.env.GEMINI_API_KEY },
      body: JSON.stringify({
        contents: [{ parts: [
          { text: 'This is a doctor prescription (may be handwritten). Extract every medicine name. Return JSON: {"medicines":[{"name":"brand or generic name in English letters","dose":"strength/frequency if visible"}]}. Only medicines, no other text.' },
          { inlineData: { mimeType: mime || 'image/jpeg', data: image } }
        ] }],
        generationConfig: { responseMimeType: 'application/json' }
      })
    });
    const j = await r.json();
    const text = j?.candidates?.[0]?.content?.parts?.[0]?.text || '{"medicines":[]}';
    res.status(200).json(JSON.parse(text));
  } catch (e) {
    res.status(500).json({ error: String(e) });
  }
};
