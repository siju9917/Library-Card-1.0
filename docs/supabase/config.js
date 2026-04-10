// ============================================================
// LIBRARY CARD — Supabase Config
// ============================================================
// 1. Create a free Supabase project at https://supabase.com
// 2. In your project, go to Settings → API
// 3. Copy your "Project URL" and "anon public" key into the strings below
// 4. Commit and push this file to GitHub
//
// SAFETY NOTE: the anon key is *meant* to be public — it only allows
// what your Row Level Security policies allow. Never paste the
// "service_role" key here; that one is admin-level.
// ============================================================

window.LC_CONFIG = {
  SUPABASE_URL: '',  // e.g. 'https://abcdefgh.supabase.co'
  SUPABASE_ANON_KEY: '',  // e.g. 'eyJhbGciOiJIUzI1NiIs...'
};

// When both fields above are filled in, the app will switch from
// demo mode to real cloud mode automatically. Until then, the app
// runs as a local-only demo on each device.
window.LC_CLOUD_ENABLED = !!(window.LC_CONFIG.SUPABASE_URL && window.LC_CONFIG.SUPABASE_ANON_KEY);
