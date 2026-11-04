const fs = require('fs');
const path = require('path');

const envPath = path.join('X:/Users/Default/.agents/skills/claude-vision-skill', '.env');
const env = {};
for (const line of fs.readFileSync(envPath, 'utf8').split(/\r?\n/)) {
  const m = line.match(/^([A-Z_]+)=(.*)$/);
  if (m) env[m[1]] = m[2].trim();
}

const [, , imgPath, ...promptParts] = process.argv;
const prompt = promptParts.join(' ') || '用中文详细描述这张图片的内容';

(async () => {
  const buf = fs.readFileSync(imgPath);
  const ext = path.extname(imgPath).slice(1).toLowerCase();
  const mime = ext === 'png' ? 'image/png' : 'image/jpeg';
  const dataUrl = `data:${mime};base64,${buf.toString('base64')}`;

  const res = await fetch(`${env.DASHSCOPE_BASE_URL}/chat/completions`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${env.DASHSCOPE_API_KEY}`,
    },
    body: JSON.stringify({
      model: env.VISION_MODEL,
      messages: [
        {
          role: 'user',
          content: [
            { type: 'image_url', image_url: { url: dataUrl } },
            { type: 'text', text: prompt },
          ],
        },
      ],
      max_tokens: 2048,
    }),
  });

  const json = await res.json();
  if (!res.ok) {
    console.error('HTTP', res.status, JSON.stringify(json).slice(0, 500));
    process.exit(1);
  }
  console.log(json.choices?.[0]?.message?.content ?? JSON.stringify(json).slice(0, 500));
})();
