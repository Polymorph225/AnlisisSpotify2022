
-- Berikut digunakan untuk mengekstrak artis yang tampil dan membuat kolom baru yang dinamai 'featured_artist'.
ALTER TABLE [spotifytopsong22].[dbo].[spotify22]
ADD featured_artist AS CASE
		WHEN song LIKE '%(%' THEN SUBSTRING(song, CHARINDEX('(', song), LEN(song) - CHARINDEX('(', song) + 1)
		END;

-- Buat kolom bernama 'featured'
ALTER TABLE [spotifytopsong22].[dbo].[spotify22]
ADD featured NVARCHAR(100) DEFAULT NULL;

-- Mengidentifikasi apakah 'song' memiliki artis yang tampil atau tidak, yang kemudian dimasukan kedalam kolom 'featured'
UPDATE [spotifytopsong22].[dbo].[spotify22]
SET featured = CASE
		WHEN featured_artist IS NOT NULL THEN 1
		ELSE 0
		END;
		
-- Ekstrak hanya judul lagu dari kolom 'song' dan meletakkan judul yang diekstrak tersebut ke dalam kolom baru yang dinamai 'title'
ALTER TABLE [spotifytopsong22].[dbo].[spotify22]
ADD title AS CASE
			WHEN CHARINDEX('(', song) > 0 
			THEN LEFT(song, CHARINDEX('(', song) - 2)
			ELSE song 
			END; 
			
-- Buat kolom bernama 'track'
ALTER TABLE [spotifytopsong22].[dbo].[spotify22]
ADD track NVARCHAR(100);

-- Mengubah penulisan huruf pada kolom 'title' agar konsisten, lalu mengisinya ke dalam kolom 'track'
UPDATE [spotifytopsong22].[dbo].[spotify22]
SET track = LOWER(title);

-- Buat kolom bernama 'artists_cleaned'
ALTER TABLE [spotifytopsong22].[dbo].[spotify22]
ADD artists_cleaned NVARCHAR(255) DEFAULT NULL;

-- Mengubah penulisan huruf pada kolom 'artist' agar konsisten, lalu mengisinya ke dalam kolom 'artists_cleaned'
UPDATE [spotifytopsong22].[dbo].[spotify22]
SET artists_cleaned = LOWER(artist);

-- Buat kolom bernama 'featured_artist_cleaned'
ALTER TABLE [spotifytopsong22].[dbo].[spotify22]
ADD featured_artist_cleaned NVARCHAR(255) DEFAULT NULL;

-- Mengubah penulisan huruf pada kolom 'featured_artist' agar konsisten, lalu mengisinya ke dalam kolom 'featured_artist_cleaned'
UPDATE [spotifytopsong22].[dbo].[spotify22]
SET featured_artist_cleaned = LOWER(featured_artist);

-- /*Catatan: Saya membuat kolom 'featured_artist' untuk memisahkan artis yang terdapat dalam tanda kurung dari judul lagu. Saya memindah dan mengubah kembali 'featured_artist' ke 'featured_artist_cleaned' karena 'featured_artist' merupakan kolom yang tidak dapat diubah. Jadi, saya membuat 'featured_artist_cleaned' sebagai kolom kosong untuk kemudian diisi dengan value yang telah diubah penulisannya 'featured_artist'

--------------------------------------------------------------------------------------------------------------
-- Mengubah waktu untuk mendapatkan insight yang lebih selama analisis.

-- Mengubah detik dari 'duration_ms (ms berarti mili detik)' dan masukkan ke dalam kolom yang diberi label 'duration_s (s berarti detik)'.
ALTER TABLE [spotifytopsong22].[dbo].[spotify22]
ADD duration_s AS (duration_ms / 1000);

-- Mengubah ke menit dari 'duration_s' dan masukkan ke dalam kolom 'duration_m (m berarti menit)'.
ALTER TABLE [spotifytopsong22].[dbo].[spotify22]
ADD duration_m AS CAST(ROUND(((duration_ms / 1000.0) / 60.0), 2) 
				AS DECIMAL(4,2));
				
--------------------------------------------------------------------------------------------------------------
-- Membuat tabel baru 'topspotify22_cleaned' dan memuat isi tabel lama ke dalamnya.
SELECT * INTO topspotify22_cleaned
FROM [spotifytopsong22].[dbo].[spotify22];

-- Menghapus kolom yang tidak diperlukan dari tabel baru.
ALTER TABLE [spotifytopsong22].[dbo].[topspotify22_cleaned]
DROP COLUMN song, artist, featured_artist, title;

-- Mengubah kolom 'key' menjadi 'song_key' agar nama kolom kunci tidak bentrok dengan kata kunci 'key'.
EXEC sp_rename 'topspotify22_cleaned.key', 'song_key', 'COLUMN';

--------------------------------------------------------------------------------------------------------------
/* Artist Analysis */

-- Artis yang memiliki lagu Top 100 terbanyak
SELECT artists_cleaned AS artist,
		COUNT(track) AS song_count,
		CAST(ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM topspotify22_cleaned),2) AS Decimal (4,2)) AS song_percentage
FROM topspotify22_cleaned
GROUP BY artists_cleaned
ORDER BY song_percentage DESC;

-- Lagu yang memiliki 'song_key' tertinggi berdasarkan artis
SELECT artists_cleaned AS artists,
		track AS song,
		MAX(song_key) AS highest_key
FROM topspotify22_cleaned
GROUP BY artists_cleaned, track
ORDER BY highest_key DESC;

-- Lagu yang memiliki 'song_key' terendah berdasarkan artis
SELECT artists_cleaned AS artists,
		track AS song,
		MAX(song_key) AS highest_key
FROM topspotify22_cleaned
GROUP BY artists_cleaned, track
ORDER BY highest_key ASC;

-- Artis yang memiliki tingkat danceability teratas (top 10)
SELECT TOP 10 artists_cleaned, track, 
		CAST(ROUND(danceability, 2) AS DECIMAL(4,2)) AS danceabilty,
		RANK() OVER(ORDER BY danceability DESC) AS ranked_danceablility
FROM topspotify22_cleaned
ORDER BY ranked_danceablility ASC;

/* Song Analysis */

-- Durasi lagu terpanjang dan terpendek dalam menit
SELECT MAX(duration_m) AS longest_song,
		MIN(duration_m) AS shortest_song
FROM topspotify22_cleaned;

-- Lagu yang memiliki durasi terpanjang dalam menit
SELECT TOP 5 artists_cleaned, track, duration_m,
	RANK() OVER(Order BY duration_m DESC) AS song_rank
FROM topspotify22_cleaned;

-- Lagu yang memiliki durasi terpendek dalam menit
SELECT TOP 5 artists_cleaned, track, duration_m,
	RANK() OVER(Order BY duration_m ASC) AS song_rank
FROM topspotify22_cleaned;

-- Lagu yang memiliki kolaborasi dengan artis lain
SELECT track AS song, artists_cleaned AS artitst, 
		featured_artist_cleaned AS featured_artist
FROM topspotify22_cleaned
WHERE featured = 1;

/* Rata-rata durasi lagu dengan atau tanpa kolaborasi artis lain dalam milidetik, detik, dan menit */
-- Lagu dengan kolaborasi artis lain yang tampil (1), lagu tanpa kolaborasi artis lain (0)
SELECT featured,
		AVG(duration_ms) AS avg_duration_milliseconds,
		AVG(duration_s) AS avg_duration_seconds,
		AVG(duration_m) AS avg_duration_minues
FROM topspotify22_cleaned
GROUP BY featured;

/* Lagu yang memiliki tingkat liveliness tertinggi*/
-- Liveliness ditentukan oleh (danceability sedang hingga tinggi, energy sedang hingga tinggi)
WITH liveliness AS (
SELECT artists_cleaned, track, danceability, energy, duration_m,
		(SELECT AVG(danceability)
		FROM topspotify22_cleaned) AS avg_danceability,
		(SELECT AVG(energy)
		FROM topspotify22_cleaned) AS avg_energy
FROM topspotify22_cleaned)
SELECT artists_cleaned, track, danceability, energy, duration_m
FROM liveliness 
WHERE danceability > avg_danceability
		AND energy > avg_energy
ORDER BY duration_m DESC,
		danceability DESC,
		energy DESC;

/* Lagu yang memiliki tingkat mellow tertinggi*/
-- Mellow ditentukan oleh (danceability sedang hingga rendah dan energy sedang hingga rendah)
WITH mellow AS (
SELECT artists_cleaned, track, danceability, energy, duration_m,
		(SELECT AVG(danceability)
		FROM topspotify22_cleaned) AS avg_danceability,
		(SELECT AVG(energy)
		FROM topspotify22_cleaned) AS avg_energy
FROM topspotify22_cleaned
)
SELECT artists_cleaned, track, danceability, energy, duration_m
FROM mellow 
WHERE danceability < avg_danceability
		AND energy < avg_energy
ORDER BY duration_m DESC,
		danceability ASC,
		energy ASC;

-- Lagu yang termasuk dalam kelompok tempo tertentu berdasarkan artis dan dengan tingkat danceability
WITH speed AS (
SELECT artists_cleaned, track, danceability,
		CASE WHEN tempo > 110.00 THEN 'high_tempo'
			WHEN tempo < 95.00 THEN 'low_tempo'
			ELSE 'mid_tempo'
			END AS music_speed
FROM topspotify22_cleaned)
SELECT artists_cleaned AS artists, track AS song, 
	CAST(ROUND(danceability, 2) AS DECIMAL(4,2)) AS danceability, music_speed,
	COUNT(artists_cleaned) OVER(PARTITION BY artists_cleaned, music_speed) AS song_count
FROM speed
ORDER BY song_count DESC;


