// Ousud er nam theke Bangla nam, kaj, dam AI diye khuje ber kore. Shudhu approved staff use korte pabe.
const SUPA = 'https://pkxgolxjpvaorzacrgof.supabase.co';
const PUB = 'sb_publishable_8r9xgGOLU4GhSMsUA9zsKw__PCJSq1k';
module.exports = async (req, res) => {
  if (req.method !== 'POST') return res.status(405).json({ error: 'POST only' });
  try {
    const token = (req.headers.authorization || '').replace('Bearer ', '');
    const u = await fetch(SUPA + '/auth/v1/user', { headers: { apikey: PUB, Authorization: 'Bearer ' + token } });
    if (!u.ok) return res.status(401).json({ error: 'Login korte hobe' });
    const user = await u.json();
    const p = await fetch(`${SUPA}/rest/v1/profiles?select=approved&id=eq.${user.id}`, { headers: { apikey: PUB, Authorization: 'Bearer ' + token } });
    const pj = await p.json();
    if (!pj[0] || !pj[0].approved) return res.status(403).json({ error: 'Approval lagbe' });

    const name = String((req.body || {}).name || '').slice(0, 100);
    if (!name) return res.status(400).json({ error: 'Nam dao' });
    const prompt = `Medicine: "${name}" (sold in Bangladesh). Search the web (Medex, DGDA, Arogga, company sites) and return ONLY a JSON object, no other text:
{"name_en":"brand name with strength, e.g. Napa 500mg","name_bn":"brand name written in Bengali script","generic":"generic name","company":"manufacturer company in Bangladesh","strength":"e.g. 500 mg","form":"Tablet / Capsule / Syrup / Cream etc.","uses":"short Bangla description of what it is used for, max 20 words","side_effects":"short Bangla note on common side effects/cautions, max 25 words","price":number in BDT for ONE unit (one tablet/capsule, or one bottle/tube for syrup/cream) or null if not sure,"price_unit":"e.g. per tablet"}`;
    const r = await fetch('https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'x-goog-api-key': process.env.GEMINI_API_KEY },
      body: JSON.stringify({ contents: [{ parts: [{ text: prompt }] }], tools: [{ google_search: {} }] })
    });
    const j = await r.json();
    const text = (j?.candidates?.[0]?.content?.parts || []).map(x => x.text || '').join('');
    const m = text.match(/\{[\s\S]*\}/);
    if (!m) return res.status(502).json({ error: 'AI uttor dite parlo na' });
    try { res.status(200).json(JSON.parse(m[0])); } catch (e) { res.status(502).json({ error: 'AI uttor bujha gelo na' }); }
  } catch (e) {
    res.status(500).json({ error: String(e) });
  }
};
