-- H&M Müşteri ve Satış Analizi: temel SQL sorguları (DuckDB)

-- 1. FN boşluklarının anlamını çapraz doğrulama
SELECT FN, fashion_news_frequency, COUNT(*) AS musteri_sayisi
FROM customers
GROUP BY FN, fashion_news_frequency
ORDER BY musteri_sayisi DESC;

-- 2. Yaş dağılımı ve yüzdeler (pencere fonksiyonu)
SELECT
    CASE
        WHEN age < 25 THEN '16-24'
        WHEN age < 35 THEN '25-34'
        WHEN age < 45 THEN '35-44'
        WHEN age < 55 THEN '45-54'
        WHEN age < 65 THEN '55-64'
        WHEN age >= 65 THEN '65+'
        ELSE 'Bilinmiyor'
    END AS yas_grubu,
    COUNT(*) AS musteri_sayisi,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS yuzde
FROM customers
GROUP BY yas_grubu
ORDER BY yas_grubu;

-- 3. Yaş grubuna göre reyon tercihleri (üç tablonun birleştirilmesi)
SELECT
    CASE
        WHEN c.age < 25 THEN '16-24'
        WHEN c.age < 35 THEN '25-34'
        WHEN c.age < 45 THEN '35-44'
        WHEN c.age < 55 THEN '45-54'
        WHEN c.age < 65 THEN '55-64'
        WHEN c.age >= 65 THEN '65+'
        ELSE 'Bilinmiyor'
    END AS yas_grubu,
    COUNT(*) AS satis_sayisi,
    ROUND(100 * AVG(CASE WHEN a.index_group_name = 'Baby/Children' THEN 1 ELSE 0 END), 1) AS cocuk_yuzde,
    ROUND(100 * AVG(CASE WHEN a.index_group_name = 'Divided'       THEN 1 ELSE 0 END), 1) AS divided_yuzde,
    ROUND(100 * AVG(CASE WHEN a.index_group_name = 'Ladieswear'    THEN 1 ELSE 0 END), 1) AS kadin_yuzde
FROM transactions AS t
JOIN customers AS c ON t.customer_id = c.customer_id
JOIN articles  AS a ON t.article_id  = a.article_id
GROUP BY yas_grubu
ORDER BY yas_grubu;

-- 4. Yaş grubuna göre alışveriş sıklığı ve sepet büyüklüğü
SELECT
    CASE
        WHEN c.age < 25 THEN '16-24'
        WHEN c.age < 35 THEN '25-34'
        WHEN c.age < 45 THEN '35-44'
        WHEN c.age < 55 THEN '45-54'
        WHEN c.age < 65 THEN '55-64'
        WHEN c.age >= 65 THEN '65+'
        ELSE 'Bilinmiyor'
    END AS yas_grubu,
    COUNT(DISTINCT t.customer_id) AS aktif_musteri,
    ROUND(COUNT(DISTINCT t.customer_id || '-' || t.t_dat) / COUNT(DISTINCT t.customer_id), 1) AS musteri_basina_alisveris,
    ROUND(COUNT(*) / COUNT(DISTINCT t.customer_id || '-' || t.t_dat), 2) AS sepet_buyuklugu
FROM transactions AS t
JOIN customers AS c ON t.customer_id = c.customer_id
GROUP BY yas_grubu
ORDER BY yas_grubu;

-- 5. Aylık satışlar ve online payı (tarih fonksiyonu)
SELECT DATE_TRUNC('month', t_dat) AS ay,
       COUNT(*) AS satis_sayisi,
       ROUND(100 * AVG(CASE WHEN sales_channel_id = 2 THEN 1 ELSE 0 END), 1) AS online_yuzde
FROM transactions
GROUP BY ay
ORDER BY ay;

-- 6. Müşteri sadakati: müşteri ve satış payları (CTE + pencere fonksiyonu)
WITH musteri_ozet AS (
    SELECT customer_id,
           COUNT(DISTINCT t_dat) AS alisveris_gunu,
           COUNT(*)              AS urun_sayisi
    FROM transactions
    GROUP BY customer_id
)
SELECT
    CASE
        WHEN alisveris_gunu = 1   THEN '1 kez'
        WHEN alisveris_gunu <= 3  THEN '2-3 kez'
        WHEN alisveris_gunu <= 10 THEN '4-10 kez'
        ELSE '10+ kez'
    END AS alisveris_sikligi,
    ROUND(100.0 * COUNT(*)         / SUM(COUNT(*))         OVER (), 1) AS musteri_yuzde,
    ROUND(100.0 * SUM(urun_sayisi) / SUM(SUM(urun_sayisi)) OVER (), 1) AS satis_yuzde
FROM musteri_ozet
GROUP BY alisveris_sikligi
ORDER BY MIN(alisveris_gunu);
