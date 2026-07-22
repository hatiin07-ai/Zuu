const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type"
};

export async function onRequestGet({ request }) {
  const url = new URL(request.url);
  const id = url.searchParams.get("id");

  if (!id) {
    return new Response(JSON.stringify({ error: "id required" }), {
      status: 400, headers: { ...CORS, "Content-Type": "application/json" }
    });
  }

  try {
    const res = await fetch(`https://chapi.sooplive.co.kr/api/${encodeURIComponent(id)}/station`, {
      headers: { "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36" },
      cf: { cacheTtl: 60, cacheEverything: true }
    });
    const j = await res.json();
    // broad 필드가 null이 아니면 방송 중 (실제 JSON 구조로 파싱 경로 검증 필요)
    const live = !!(j && j.broad);
    const nick = (j && j.station && j.station.user_nick) || null;

    return new Response(JSON.stringify({ live, nick }), {
      headers: { ...CORS, "Content-Type": "application/json", "Cache-Control": "public, max-age=60" }
    });
  } catch (e) {
    return new Response(JSON.stringify({ live: false, error: e.message }), {
      status: 200, headers: { ...CORS, "Content-Type": "application/json" }
    });
  }
}

export async function onRequestOptions() {
  return new Response(null, { headers: CORS });
}
