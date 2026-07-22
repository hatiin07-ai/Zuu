-- ═══════════════════════════════════════════════════════
--  쮸(Zuu) 프로필 — 전용 Supabase 세팅 v2 (멱등 · 전체 RUN)
--  프로젝트: ebenkpehcdlifzysvcad
--  v2: songs · upbo · gallery · site_settings · Storage 추가
-- ═══════════════════════════════════════════════════════

-- ── 1) 일정 (schedules) ──────────────────────────────
CREATE TABLE IF NOT EXISTS public.schedules (
  id bigserial PRIMARY KEY,
  event_date date NOT NULL,
  event_time time,                          -- NULL 허용 (휴방)
  title text NOT NULL,
  description text,
  event_type text DEFAULT 'broadcast',      -- broadcast/rest/event/collab/tournament/other
  color text,
  is_hidden boolean DEFAULT false,
  created_at timestamptz DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_schedules_date ON public.schedules(event_date);
ALTER TABLE public.schedules ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "public read schedules" ON public.schedules;
DROP POLICY IF EXISTS "auth all schedules" ON public.schedules;
CREATE POLICY "public read schedules" ON public.schedules
  FOR SELECT USING (is_hidden = false);
CREATE POLICY "auth all schedules" ON public.schedules
  FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- ── 2) VOD 클립 (vod_clips) ──────────────────────────
CREATE TABLE IF NOT EXISTS public.vod_clips (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  vod_id text NOT NULL,
  thumb_url text,
  sort_order int DEFAULT 0,
  created_at timestamptz DEFAULT now()
);
ALTER TABLE public.vod_clips ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "public read vod" ON public.vod_clips;
DROP POLICY IF EXISTS "auth all vod" ON public.vod_clips;
CREATE POLICY "public read vod" ON public.vod_clips FOR SELECT USING (true);
CREATE POLICY "auth all vod" ON public.vod_clips
  FOR ALL TO authenticated USING (true) WITH CHECK (true);

INSERT INTO public.vod_clips (title, vod_id, sort_order)
SELECT * FROM (VALUES
  ('큐피 - Antifreeze Cover', '199270475', 0),
  ('HONEYZ - 사랑 받을 준비완료', '194780409', 1),
  ('VAUNDY - 踊り子 (무희)', '194575887', 2)
) AS v(title, vod_id, sort_order)
WHERE NOT EXISTS (SELECT 1 FROM public.vod_clips);

-- ── 3) 문의 (inquiries) ──────────────────────────────
CREATE TABLE IF NOT EXISTS public.inquiries (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text,
  contact text,
  message text NOT NULL,
  is_read boolean DEFAULT false,
  created_at timestamptz DEFAULT now()
);
ALTER TABLE public.inquiries ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "public insert inquiry" ON public.inquiries;
DROP POLICY IF EXISTS "auth all inquiry" ON public.inquiries;
CREATE POLICY "public insert inquiry" ON public.inquiries
  FOR INSERT WITH CHECK (true);
CREATE POLICY "auth all inquiry" ON public.inquiries
  FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- ── 4) 노래책 (songs · 두미 스키마) ───────────────────
CREATE TABLE IF NOT EXISTS public.songs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  artist text NOT NULL,
  title text NOT NULL,
  genre text DEFAULT 'etc',                 -- kpop | jpop | pop | etc
  level int DEFAULT 0,                      -- 0~5 숙련도
  memo text,
  sort_order int DEFAULT 0,
  created_at timestamptz DEFAULT now()
);
ALTER TABLE public.songs ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "public read songs" ON public.songs;
DROP POLICY IF EXISTS "auth all songs" ON public.songs;
CREATE POLICY "public read songs" ON public.songs FOR SELECT USING (true);
CREATE POLICY "auth all songs" ON public.songs
  FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- ── 5) 업보 (두미 스키마) ─────────────────────────────
CREATE TABLE IF NOT EXISTS public.upbo_task_types (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  category text DEFAULT 'normal',           -- normal | event
  sort_order int DEFAULT 0,
  is_active boolean DEFAULT true,
  created_at timestamptz DEFAULT now()
);
CREATE TABLE IF NOT EXISTS public.upbo_members (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  nickname text NOT NULL,
  user_id text,                             -- SOOP 아이디 (프사·닉 연동)
  memo text,
  is_hidden boolean DEFAULT false,
  sort_order int DEFAULT 0,
  coins int DEFAULT 0,
  created_at timestamptz DEFAULT now()
);
CREATE TABLE IF NOT EXISTS public.upbo_tasks (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  member_id uuid REFERENCES public.upbo_members(id) ON DELETE CASCADE,
  type_id uuid REFERENCES public.upbo_task_types(id) ON DELETE CASCADE,
  quantity int DEFAULT 1,
  memo text,
  is_prepared boolean DEFAULT false,
  created_at timestamptz DEFAULT now()
);
CREATE TABLE IF NOT EXISTS public.upbo_settings ( key text PRIMARY KEY, value text );

ALTER TABLE public.upbo_task_types ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.upbo_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.upbo_tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.upbo_settings ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "public read task_types" ON public.upbo_task_types;
DROP POLICY IF EXISTS "auth all task_types" ON public.upbo_task_types;
CREATE POLICY "public read task_types" ON public.upbo_task_types FOR SELECT USING (true);
CREATE POLICY "auth all task_types" ON public.upbo_task_types
  FOR ALL TO authenticated USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "public read members" ON public.upbo_members;
DROP POLICY IF EXISTS "auth all members" ON public.upbo_members;
CREATE POLICY "public read members" ON public.upbo_members FOR SELECT USING (true);
CREATE POLICY "auth all members" ON public.upbo_members
  FOR ALL TO authenticated USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "public read tasks" ON public.upbo_tasks;
DROP POLICY IF EXISTS "auth all tasks" ON public.upbo_tasks;
CREATE POLICY "public read tasks" ON public.upbo_tasks FOR SELECT USING (true);
CREATE POLICY "auth all tasks" ON public.upbo_tasks
  FOR ALL TO authenticated USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "public read upbo_settings" ON public.upbo_settings;
DROP POLICY IF EXISTS "auth all upbo_settings" ON public.upbo_settings;
CREATE POLICY "public read upbo_settings" ON public.upbo_settings FOR SELECT USING (true);
CREATE POLICY "auth all upbo_settings" ON public.upbo_settings
  FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- ── 6) 갤러리 (gallery_items) ─────────────────────────
CREATE TABLE IF NOT EXISTS public.gallery_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  image_url text NOT NULL,
  caption text,
  storage_path text,                        -- Storage 업로드 파일이면 경로 저장
  sort_order int DEFAULT 0,
  created_at timestamptz DEFAULT now()
);
ALTER TABLE public.gallery_items ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "public read gallery" ON public.gallery_items;
DROP POLICY IF EXISTS "auth all gallery" ON public.gallery_items;
CREATE POLICY "public read gallery" ON public.gallery_items FOR SELECT USING (true);
CREATE POLICY "auth all gallery" ON public.gallery_items
  FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- ── 7) 사이트 설정 (site_settings · 프로필 문구) ───────
CREATE TABLE IF NOT EXISTS public.site_settings ( key text PRIMARY KEY, value text );
ALTER TABLE public.site_settings ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "public read site_settings" ON public.site_settings;
DROP POLICY IF EXISTS "auth all site_settings" ON public.site_settings;
CREATE POLICY "public read site_settings" ON public.site_settings FOR SELECT USING (true);
CREATE POLICY "auth all site_settings" ON public.site_settings
  FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- ── 8) Storage — 갤러리 버킷 (공개 읽기 · 인증 쓰기) ───
INSERT INTO storage.buckets (id, name, public)
VALUES ('gallery', 'gallery', true)
ON CONFLICT (id) DO NOTHING;

DROP POLICY IF EXISTS "public read gallery bucket" ON storage.objects;
DROP POLICY IF EXISTS "auth insert gallery bucket" ON storage.objects;
DROP POLICY IF EXISTS "auth update gallery bucket" ON storage.objects;
DROP POLICY IF EXISTS "auth delete gallery bucket" ON storage.objects;
CREATE POLICY "public read gallery bucket" ON storage.objects
  FOR SELECT USING (bucket_id = 'gallery');
CREATE POLICY "auth insert gallery bucket" ON storage.objects
  FOR INSERT TO authenticated WITH CHECK (bucket_id = 'gallery');
CREATE POLICY "auth update gallery bucket" ON storage.objects
  FOR UPDATE TO authenticated USING (bucket_id = 'gallery');
CREATE POLICY "auth delete gallery bucket" ON storage.objects
  FOR DELETE TO authenticated USING (bucket_id = 'gallery');

-- ── 9) 오늘 테스트용 샘플 일정 (원치 않으면 이 블록 건너뛰기) ──
INSERT INTO public.schedules (event_date, event_time, title, event_type)
SELECT (now() AT TIME ZONE 'Asia/Seoul')::date, '19:00', '노래방송', 'broadcast'
WHERE NOT EXISTS (SELECT 1 FROM public.schedules);
