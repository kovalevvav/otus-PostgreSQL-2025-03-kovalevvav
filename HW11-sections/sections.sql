-- посмотрим сколько месяцев между самой ранней и самой поздней датами бронирования
SELECT
    EXTRACT(YEAR FROM AGE(max(book_date), min(book_date))) * 12 +
    EXTRACT(MONTH FROM AGE(max(book_date), min(book_date))) AS "DiffMonths"
FROM bookings.bookings;
/*
DiffMonths
11
*/

-- посмотрим самую раннюю и самую позднюю даты бронирования
SELECT
    MIN(CAST(book_date AS DATE)) AS "MinBookDate"
  , MAX(CAST(book_date AS DATE)) AS "MaxBookDate"
FROM bookings.bookings;
/*
MinBookDate	MaxBookDate
2025-09-01	2026-08-31
*/

-- посмотрим распределение данных по месяцам
SELECT
    EXTRACT(YEAR FROM book_date)::text || '-' || LPAD(EXTRACT(MONTH FROM book_date)::text, 2, '0') AS "Section"
  , COUNT(*) AS "Rows"
  , MIN(book_date) AS "MinBookDate"
  , MAX(book_date) AS "MaxBookDate"
FROM bookings.bookings
GROUP BY EXTRACT(YEAR FROM book_date)::text || '-' || LPAD(EXTRACT(MONTH FROM book_date)::text, 2, '0')
ORDER BY 1;
/*
Section	Rows	  MinBookDate	                  MaxBookDate
2025-09	448064	2025-09-01 00:00:06.265219+00	2025-09-30 23:59:58.026243+00
2025-10	434159	2025-10-01 00:00:08.899725+00	2025-10-31 23:59:53.263233+00
2025-11	410670	2025-11-01 00:00:01.790251+00	2025-11-30 23:59:28.616825+00
2025-12	410796	2025-12-01 00:00:00.372488+00	2025-12-31 23:59:40.191846+00
2026-01	412036	2026-01-01 00:00:01.314353+00	2026-01-31 23:59:54.499781+00
2026-02	370985	2026-02-01 00:00:19.902319+00	2026-02-28 23:59:58.993676+00
2026-03	408667	2026-03-01 00:00:08.455494+00	2026-03-31 23:59:58.526315+00
2026-04	383124	2026-04-01 00:00:12.949237+00	2026-04-30 23:59:31.125808+00
2026-05	399596	2026-05-01 00:00:23.516073+00	2026-05-31 23:59:48.496859+00
2026-06	403237	2026-06-01 00:00:10.49019+00	2026-06-30 23:59:59.951396+00
2026-07	411392	2026-07-01 00:00:06.299438+00	2026-07-31 23:59:54.689055+00
2026-08	412512	2026-08-01 00:00:08.873243+00	2026-08-31 23:59:58.283465+00

Видим, что данные внутри месячных диапазонов распределены равномерно,
поэтому выбор одного месяца в качестве диапазона для секции видится оправданным
*/

-- создадим схему для секционированной таблицы
DROP SCHEMA IF EXISTS bookings_copy CASCADE;
CREATE SCHEMA bookings_copy;

-- в новой схеме создадим секционированную таблицу по диапазону дат бронирования (book_date)
CREATE TABLE IF NOT EXISTS bookings_copy.bookings
( book_ref character(6) COLLATE pg_catalog."default" NOT NULL
, book_date timestamp with time zone NOT NULL
, total_amount numeric(10,2) NOT NULL
, CONSTRAINT bookings_pkey PRIMARY KEY (book_ref, book_date)
) PARTITION BY RANGE (book_date);

-- создадим секции из расчета одна секция на месяц
CREATE TABLE bookings_copy.bookings_2025_09 PARTITION OF bookings_copy.bookings FOR VALUES FROM ('2025-09-01') TO ('2025-10-01');
CREATE TABLE bookings_copy.bookings_2025_10 PARTITION OF bookings_copy.bookings FOR VALUES FROM ('2025-10-01') TO ('2025-11-01');
CREATE TABLE bookings_copy.bookings_2025_11 PARTITION OF bookings_copy.bookings FOR VALUES FROM ('2025-11-01') TO ('2025-12-01');
CREATE TABLE bookings_copy.bookings_2025_12 PARTITION OF bookings_copy.bookings FOR VALUES FROM ('2025-12-01') TO ('2026-01-01');
CREATE TABLE bookings_copy.bookings_2026_01 PARTITION OF bookings_copy.bookings FOR VALUES FROM ('2026-01-01') TO ('2026-02-01');
CREATE TABLE bookings_copy.bookings_2026_02 PARTITION OF bookings_copy.bookings FOR VALUES FROM ('2026-02-01') TO ('2026-03-01');
CREATE TABLE bookings_copy.bookings_2026_03 PARTITION OF bookings_copy.bookings FOR VALUES FROM ('2026-03-01') TO ('2026-04-01');
CREATE TABLE bookings_copy.bookings_2026_04 PARTITION OF bookings_copy.bookings FOR VALUES FROM ('2026-04-01') TO ('2026-05-01');
CREATE TABLE bookings_copy.bookings_2026_05 PARTITION OF bookings_copy.bookings FOR VALUES FROM ('2026-05-01') TO ('2026-06-01');
CREATE TABLE bookings_copy.bookings_2026_06 PARTITION OF bookings_copy.bookings FOR VALUES FROM ('2026-06-01') TO ('2026-07-01');
CREATE TABLE bookings_copy.bookings_2026_07 PARTITION OF bookings_copy.bookings FOR VALUES FROM ('2026-07-01') TO ('2026-08-01');
CREATE TABLE bookings_copy.bookings_2026_08 PARTITION OF bookings_copy.bookings FOR VALUES FROM ('2026-08-01') TO ('2026-09-01');

-- создадим секцию по умолчанию для дат, не попадающих ни в одну секцию
CREATE TABLE bookings_copy.bookings_other PARTITION OF bookings_copy.bookings DEFAULT;

-- посмотрим только что созданные секции
SELECT table_catalog, table_schema, table_name, table_type
FROM information_schema.tables
WHERE table_schema = 'bookings_copy'
ORDER BY table_name;
/*
table_catalog	table_schema	table_name	      table_type
demo	        bookings_copy	bookings	        BASE TABLE
demo	        bookings_copy	bookings_2025_09	BASE TABLE
demo	        bookings_copy	bookings_2025_10	BASE TABLE
demo	        bookings_copy	bookings_2025_11	BASE TABLE
demo	        bookings_copy	bookings_2025_12	BASE TABLE
demo	        bookings_copy	bookings_2026_01	BASE TABLE
demo	        bookings_copy	bookings_2026_02	BASE TABLE
demo	        bookings_copy	bookings_2026_03	BASE TABLE
demo	        bookings_copy	bookings_2026_04	BASE TABLE
demo	        bookings_copy	bookings_2026_05	BASE TABLE
demo	        bookings_copy	bookings_2026_06	BASE TABLE
demo	        bookings_copy	bookings_2026_07	BASE TABLE
demo	        bookings_copy	bookings_2026_08	BASE TABLE
demo	        bookings_copy	bookings_other	  BASE TABLE
*/

-- копируем данные
INSERT INTO bookings_copy.bookings
SELECT * FROM bookings.bookings;

-- сделаем очистку и соберем статистику для оптимизатора
VACUUM ANALYZE bookings_copy.bookings;

-- посмотрим данные в секциях
SELECT '2025-09' AS "Section", COUNT(*) AS "Rows", MIN(book_date) AS "MinBookDate", MAX(book_date) AS "MaxBookDate" FROM bookings_copy.bookings_2025_09 UNION ALL
SELECT '2025-10' AS "Section", COUNT(*) AS "Rows", MIN(book_date) AS "MinBookDate", MAX(book_date) AS "MaxBookDate" FROM bookings_copy.bookings_2025_10 UNION ALL
SELECT '2025-11' AS "Section", COUNT(*) AS "Rows", MIN(book_date) AS "MinBookDate", MAX(book_date) AS "MaxBookDate" FROM bookings_copy.bookings_2025_11 UNION ALL
SELECT '2025-12' AS "Section", COUNT(*) AS "Rows", MIN(book_date) AS "MinBookDate", MAX(book_date) AS "MaxBookDate" FROM bookings_copy.bookings_2025_12 UNION ALL
SELECT '2026-01' AS "Section", COUNT(*) AS "Rows", MIN(book_date) AS "MinBookDate", MAX(book_date) AS "MaxBookDate" FROM bookings_copy.bookings_2026_01 UNION ALL
SELECT '2026-02' AS "Section", COUNT(*) AS "Rows", MIN(book_date) AS "MinBookDate", MAX(book_date) AS "MaxBookDate" FROM bookings_copy.bookings_2026_02 UNION ALL
SELECT '2026-03' AS "Section", COUNT(*) AS "Rows", MIN(book_date) AS "MinBookDate", MAX(book_date) AS "MaxBookDate" FROM bookings_copy.bookings_2026_03 UNION ALL
SELECT '2026-04' AS "Section", COUNT(*) AS "Rows", MIN(book_date) AS "MinBookDate", MAX(book_date) AS "MaxBookDate" FROM bookings_copy.bookings_2026_04 UNION ALL
SELECT '2026-05' AS "Section", COUNT(*) AS "Rows", MIN(book_date) AS "MinBookDate", MAX(book_date) AS "MaxBookDate" FROM bookings_copy.bookings_2026_05 UNION ALL
SELECT '2026-06' AS "Section", COUNT(*) AS "Rows", MIN(book_date) AS "MinBookDate", MAX(book_date) AS "MaxBookDate" FROM bookings_copy.bookings_2026_06 UNION ALL
SELECT '2026-07' AS "Section", COUNT(*) AS "Rows", MIN(book_date) AS "MinBookDate", MAX(book_date) AS "MaxBookDate" FROM bookings_copy.bookings_2026_07 UNION ALL
SELECT '2026-08' AS "Section", COUNT(*) AS "Rows", MIN(book_date) AS "MinBookDate", MAX(book_date) AS "MaxBookDate" FROM bookings_copy.bookings_2026_08 ORDER BY 1;
/*
Section	Rows	  MinBookDate	                  MaxBookDate
2025-09	448064	2025-09-01 00:00:06.265219+00	2025-09-30 23:59:58.026243+00
2025-10	434159	2025-10-01 00:00:08.899725+00	2025-10-31 23:59:53.263233+00
2025-11	410670	2025-11-01 00:00:01.790251+00	2025-11-30 23:59:28.616825+00
2025-12	410796	2025-12-01 00:00:00.372488+00	2025-12-31 23:59:40.191846+00
2026-01	412036	2026-01-01 00:00:01.314353+00	2026-01-31 23:59:54.499781+00
2026-02	370985	2026-02-01 00:00:19.902319+00	2026-02-28 23:59:58.993676+00
2026-03	408667	2026-03-01 00:00:08.455494+00	2026-03-31 23:59:58.526315+00
2026-04	383124	2026-04-01 00:00:12.949237+00	2026-04-30 23:59:31.125808+00
2026-05	399596	2026-05-01 00:00:23.516073+00	2026-05-31 23:59:48.496859+00
2026-06	403237	2026-06-01 00:00:10.49019+00	2026-06-30 23:59:59.951396+00
2026-07	411392	2026-07-01 00:00:06.299438+00	2026-07-31 23:59:54.689055+00
2026-08	412512	2026-08-01 00:00:08.873243+00	2026-08-31 23:59:58.283465+00

Видим, что данные перенеслись корректно
*/
 
-- посмотрим время извлечения данных из монолитной таблицы:
VACUUM ANALYZE bookings.bookings;
EXPLAIN ANALYZE
SELECT * FROM bookings.bookings WHERE book_date BETWEEN '2025-10-01' AND '2025-10-30';
/*
Gather  (cost=1000.00..103637.14 rows=406994 width=21) (actual time=30.944..314.811 rows=407769.00 loops=1)
  Workers Planned: 2
  Workers Launched: 2
  Buffers: shared hit=3 read=31277
  ->  Parallel Seq Scan on bookings  (cost=0.00..61937.74 rows=169581 width=21) (actual time=15.520..277.306 rows=135923.00 loops=3)
        Filter: ((book_date >= '2025-10-01 00:00:00+00'::timestamp with time zone) AND (book_date <= '2025-10-30 00:00:00+00'::timestamp with time zone))
        Rows Removed by Filter: 1499156
        Buffers: shared hit=3 read=31277
Planning Time: 0.073 ms
JIT:
  Functions: 6
  Options: Inlining false, Optimization false, Expressions true, Deforming true
  Timing: Generation 1.026 ms (Deform 0.153 ms), Inlining 0.000 ms, Optimization 3.529 ms, Emission 41.953 ms, Total 46.508 ms
Execution Time: 480.203 ms
*/

-- посмотрим время извлечения данных из секциониированной таблицы:
VACUUM ANALYZE bookings_copy.bookings;
EXPLAIN ANALYZE
SELECT * FROM bookings_copy.bookings WHERE book_date BETWEEN '2025-10-01' AND '2025-10-30';
/*
Seq Scan on bookings_2025_10 bookings  (cost=0.00..9278.38 rows=407842 width=21) (actual time=0.381..30.611 rows=407769.00 loops=1)
  Filter: ((book_date >= '2025-10-01 00:00:00+00'::timestamp with time zone) AND (book_date <= '2025-10-30 00:00:00+00'::timestamp with time zone))
  Rows Removed by Filter: 26390
  Buffers: shared read=2766
Planning:
  Buffers: shared hit=174 read=11
Planning Time: 5.812 ms
Execution Time: 42.177 ms

Видим, что время извлечения данных уменьшилось на порядок!
*/

-- посмотрим время извлечения данных из монолитной таблицы при помощи индекса:
DROP INDEX IF EXISTS bookings.ix_bookings__book_date;
CREATE INDEX IF NOT EXISTS ix_bookings__book_date ON bookings.bookings USING btree (book_date);
VACUUM ANALYZE bookings.bookings;
EXPLAIN ANALYZE
SELECT book_date FROM bookings.bookings WHERE book_date BETWEEN '2025-10-01' AND '2025-10-21';
/*
Index Only Scan using ix_bookings__book_date on bookings  (cost=0.43..8532.01 rows=275379 width=8) (actual time=0.115..19.854 rows=285669.00 loops=1)
  Index Cond: ((book_date >= '2025-10-01 00:00:00+00'::timestamp with time zone) AND (book_date <= '2025-10-21 00:00:00+00'::timestamp with time zone))
  Heap Fetches: 0
  Index Searches: 1
  Buffers: shared read=784
Planning Time: 0.077 ms
Execution Time: 26.548 ms
*/

-- посмотрим время извлечения данных из секциониированной таблицы при помощи индекса на всю таблицу:
DROP INDEX IF EXISTS bookings_copy.ix_bookings_copy__book_date;
CREATE INDEX IF NOT EXISTS ix_bookings_copy__book_date ON bookings_copy.bookings USING btree (book_date);
VACUUM ANALYZE bookings_copy.bookings;
EXPLAIN ANALYZE
SELECT book_date FROM bookings_copy.bookings WHERE book_date BETWEEN '2025-10-01' AND '2025-10-21';
/*
Index Only Scan using bookings_2025_10_book_date_idx on bookings_2025_10 bookings  (cost=0.42..8858.34 rows=285696 width=8) (actual time=0.011..18.664 rows=285669.00 loops=1)
  Index Cond: ((book_date >= '2025-10-01 00:00:00+00'::timestamp with time zone) AND (book_date <= '2025-10-21 00:00:00+00'::timestamp with time zone))
  Heap Fetches: 0
  Index Searches: 1
  Buffers: shared hit=4 read=780
Planning:
  Buffers: shared hit=25 read=3
Planning Time: 0.220 ms
Execution Time: 27.686 ms
*/

-- Видим, что индекс на всю таблицу ix_bookings_copy__book_date не используется,
-- вместо него оптимизатор взял индекс на секции bookings_2025_10_book_date_idx
-- Попробуем построить индекс прямо на секции
DROP INDEX IF EXISTS bookings_copy.ix_bookings_copy_2025_10__book_date;
CREATE INDEX IF NOT EXISTS ix_bookings_copy_2025_10__book_date ON bookings_copy.bookings_2025_10 USING btree (book_date);
VACUUM ANALYZE bookings_copy.bookings_2025_10;
EXPLAIN ANALYZE
SELECT book_date FROM bookings_copy.bookings WHERE book_date BETWEEN '2025-10-01' AND '2025-10-21';
/*
Index Only Scan using ix_bookings_copy_2025_10__book_date on bookings_2025_10 bookings  (cost=0.42..8879.02 rows=286330 width=8) (actual time=0.014..18.204 rows=285669.00 loops=1)
  Index Cond: ((book_date >= '2025-10-01 00:00:00+00'::timestamp with time zone) AND (book_date <= '2025-10-21 00:00:00+00'::timestamp with time zone))
  Heap Fetches: 0
  Index Searches: 1
  Buffers: shared hit=4 read=780
Planning:
  Buffers: shared hit=17 read=3
Planning Time: 0.270 ms
Execution Time: 24.587 ms

В этот раз используется наш индекс
*/

-- попробуем поменять какую-нибудь дату бронирования
SELECT * FROM bookings_copy.bookings_2025_10 WHERE book_ref = 'LI06OY';
SELECT * FROM bookings_copy.bookings_2025_11 WHERE book_ref = 'LI06OY';
/*
book_ref	book_date	                    total_amount
LI06OY	  2025-10-01 00:11:31.311662+00	7475.00

book_ref	book_date	                    total_amount
*/
UPDATE bookings_copy.bookings SET book_date = '2025-11-01 00:11:31.311662+00' WHERE book_ref = 'LI06OY';
SELECT * FROM bookings_copy.bookings_2025_10 WHERE book_ref = 'LI06OY';
SELECT * FROM bookings_copy.bookings_2025_11 WHERE book_ref = 'LI06OY';
/*
book_ref	book_date	                    total_amount

book_ref	book_date	                    total_amount
LI06OY	  2025-11-01 00:11:31.311662+00	7475.00

Все верно, так как дату изменили с 1 октября на 1 ноября,
запись переместилась из секции 2025_10 в секцию 2025_11
*/

-- попробуем вставить новую запись
SELECT * FROM bookings_copy.bookings_2025_12 WHERE book_ref = 'YI06OY';
INSERT INTO bookings_copy.bookings(book_ref, book_date, total_amount)
VALUES ('YI06OY', '2025-12-12', 1111.00);
SELECT * FROM bookings_copy.bookings_2025_12 WHERE book_ref = 'YI06OY';
/*
book_ref	book_date	              total_amount

book_ref	book_date	              total_amount
YI06OY	  2025-12-12 00:00:00+00	1111.00

Как и ожидалось, находим нашу новую запись в секции 2025_12
*/

-- Вывод
-- Секционирование улучшает производительность в случае если запросы работают с данными
-- умещающимися внутрь одной секции (то есть в фильтре используется поле разбиения),
-- в противном случае секционирование даже вредно.
-- Поэтому очень важно продумать стратегию разбиения данных.