# Panduan online Pilkades Watumalang (Supabase)

Supabase dipakai untuk database, login, dan penyimpanan foto. Supabase tidak menampilkan halaman HTML, jadi `index.html` ditaruh di hosting statis gratis (langkah 5).

1. Buat project di supabase.com.
2. Buka **SQL Editor**, tempel isi `supabase.sql`, lalu **Run**.
3. Buka **Authentication > Users > Add user**, buat akun panitia (email + kata sandi, centang Auto Confirm). Di **Authentication > Sign In / Providers**, matikan **Allow new users to sign up**.
4. Jadikan akun itu admin. Di SQL Editor jalankan (ganti emailnya):
   `insert into public.admins select id from auth.users where email = 'panitia@contoh.com';`
5. Buka **Project Settings > API**, salin **Project URL** dan **anon public key**. Tempel ke dua baris paling atas `<script>` di `index.html` (`SUPABASE_URL` dan `SUPABASE_KEY`). Anon key aman dipublikasikan karena akses dibatasi aturan di database.
6. Upload `index.html` ke hosting statis: Netlify Drop (app.netlify.com/drop), Cloudflare Pages, Vercel, atau GitHub Pages.

Cara kerja: warga membuka link dan langsung melihat Dashboard dan Rekapitulasi yang diperbarui otomatis. Admin masuk lewat tab **Masuk admin** untuk input suara, ubah data TPS/calon, dan unggah foto.

Sebelum konfigurasi diisi, `index.html` tetap bisa dibuka dalam mode lokal (data hanya di browser) untuk uji coba.
