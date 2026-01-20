###### **Сколько месяцев между самой ранней и самой поздней датами бронирования**



SELECT
&nbsp;&nbsp;&nbsp;&nbsp;EXTRACT(YEAR  FROM AGE(max(book\_date), min(book\_date))) \* 12 +
&nbsp;&nbsp;&nbsp;&nbsp;EXTRACT(MONTH FROM AGE(max(book\_date), min(book\_date))) AS "DiffMonths"
FROM bookings.bookings;



|**DiffMonths**|
|-|
|11|

###### 



###### **Самая ранняя и самая поздняя даты бронирования**



SELECT
&nbsp;&nbsp;&nbsp;&nbsp;MIN(CAST(book\_date AS DATE)) AS "MinBookDate"
&nbsp;&nbsp;, MAX(CAST(book\_date AS DATE)) AS "MaxBookDate"
FROM bookings.bookings;



|**MinBookDate**|**MaxBookDate**|
|-|-|
|2025-09-01|2026-08-31|

###### 



###### **Распределение данных по месяцам**



SELECT
&nbsp;&nbsp;&nbsp;&nbsp;EXTRACT(YEAR FROM book\_date)::text || '-' || LPAD(EXTRACT(MONTH FROM book\_date)::text, 2, '0') AS "Section"
&nbsp;&nbsp;, COUNT() AS "Rows"
&nbsp;&nbsp;, MIN(book\_date) AS "MinBookDate"
&nbsp;&nbsp;, MAX(book\_date) AS "MaxBookDate"
FROM bookings.bookings
GROUP BY EXTRACT(YEAR FROM book\_date)::text || '-' || LPAD(EXTRACT(MONTH FROM book\_date)::text, 2, '0')
ORDER BY 1;



|**Section**|**Rows**|**MinBookDate**|**MaxBookDate**|
|-|-|-|-|
|2025-09|448064|2025-09-01 00:00:06.265219+00|2025-09-30 23:59:58.026243+00|
|2025-10|434159|2025-10-01 00:00:08.899725+00|2025-10-31 23:59:53.263233+00|
|2025-11|410670|2025-11-01 00:00:01.790251+00|2025-11-30 23:59:28.616825+00|
|2025-12|410796|2025-12-01 00:00:00.372488+00|2025-12-31 23:59:40.191846+00|
|2026-01|412036|2026-01-01 00:00:01.314353+00|2026-01-31 23:59:54.499781+00|
|2026-02|370985|2026-02-01 00:00:19.902319+00|2026-02-28 23:59:58.993676+00|
|2026-03|408667|2026-03-01 00:00:08.455494+00|2026-03-31 23:59:58.526315+00|
|2026-04|383124|2026-04-01 00:00:12.949237+00|2026-04-30 23:59:31.125808+00|
|2026-05|399596|2026-05-01 00:00:23.516073+00|2026-05-31 23:59:48.496859+00|
|2026-06|403237|2026-06-01 00:00:10.49019+00|2026-06-30 23:59:59.951396+00|
|2026-07|411392|2026-07-01 00:00:06.299438+00|2026-07-31 23:59:54.689055+00|
|2026-08|412512|2026-08-01 00:00:08.873243+00|2026-08-31 23:59:58.283465+00|



Видим, что данные внутри месячных диапазонов распределены равномерно,
поэтому выбор одного месяца в качестве диапазона для секции видится оправданным



###### **Создадим схему для секционированной таблицы**



DROP SCHEMA IF EXISTS bookings\_copy CASCADE;
CREATE SCHEMA bookings\_copy;



###### **В новой схеме создадим секционированную таблицу по диапазону дат бронирования (book\_date)**



CREATE TABLE IF NOT EXISTS bookings\_copy.bookings
&nbsp;&nbsp;( book\_ref character(6) COLLATE pg\_catalog."default" NOT NULL
&nbsp;&nbsp;, book\_date timestamp with time zone NOT NULL
&nbsp;&nbsp;, total\_amount numeric(10,2) NOT NULL
&nbsp;&nbsp;, CONSTRAINT bookings\_pkey PRIMARY KEY (book\_ref, book\_date)
&nbsp;&nbsp;) PARTITION BY RANGE (book\_date);



###### **Создадим секции из расчета одна секция на месяц**



CREATE TABLE bookings\_copy.bookings\_2025\_09 PARTITION OF bookings\_copy.bookings FOR VALUES FROM ('2025-09-01') TO ('2025-10-01');
CREATE TABLE bookings\_copy.bookings\_2025\_10 PARTITION OF bookings\_copy.bookings FOR VALUES FROM ('2025-10-01') TO ('2025-11-01');
CREATE TABLE bookings\_copy.bookings\_2025\_11 PARTITION OF bookings\_copy.bookings FOR VALUES FROM ('2025-11-01') TO ('2025-12-01');
CREATE TABLE bookings\_copy.bookings\_2025\_12 PARTITION OF bookings\_copy.bookings FOR VALUES FROM ('2025-12-01') TO ('2026-01-01');
CREATE TABLE bookings\_copy.bookings\_2026\_01 PARTITION OF bookings\_copy.bookings FOR VALUES FROM ('2026-01-01') TO ('2026-02-01');
CREATE TABLE bookings\_copy.bookings\_2026\_02 PARTITION OF bookings\_copy.bookings FOR VALUES FROM ('2026-02-01') TO ('2026-03-01');
CREATE TABLE bookings\_copy.bookings\_2026\_03 PARTITION OF bookings\_copy.bookings FOR VALUES FROM ('2026-03-01') TO ('2026-04-01');
CREATE TABLE bookings\_copy.bookings\_2026\_04 PARTITION OF bookings\_copy.bookings FOR VALUES FROM ('2026-04-01') TO ('2026-05-01');
CREATE TABLE bookings\_copy.bookings\_2026\_05 PARTITION OF bookings\_copy.bookings FOR VALUES FROM ('2026-05-01') TO ('2026-06-01');
CREATE TABLE bookings\_copy.bookings\_2026\_06 PARTITION OF bookings\_copy.bookings FOR VALUES FROM ('2026-06-01') TO ('2026-07-01');
CREATE TABLE bookings\_copy.bookings\_2026\_07 PARTITION OF bookings\_copy.bookings FOR VALUES FROM ('2026-07-01') TO ('2026-08-01');
CREATE TABLE bookings\_copy.bookings\_2026\_08 PARTITION OF bookings\_copy.bookings FOR VALUES FROM ('2026-08-01') TO ('2026-09-01');



###### **Создадим секцию по умолчанию для дат, не попадающих ни в одну секцию**



CREATE TABLE bookings\_copy.bookings\_other PARTITION OF bookings\_copy.bookings DEFAULT;



###### **Посмотрим только что созданные секции**



SELECT table\_catalog, table\_schema, table\_name, table\_type
FROM information\_schema.tables
WHERE table\_schema = 'bookings\_copy'
ORDER BY table\_name;



|**table\_catalog**|**table\_schema**|**table\_name**|**table\_type**|
|-|-|-|-|
|demo|bookings\_copy|bookings|BASE TABLE|
|demo|bookings\_copy|bookings\_2025\_09|BASE TABLE|
|demo|bookings\_copy|bookings\_2025\_10|BASE TABLE|
|demo|bookings\_copy|bookings\_2025\_11|BASE TABLE|
|demo|bookings\_copy|bookings\_2025\_12|BASE TABLE|
|demo|bookings\_copy|bookings\_2026\_01|BASE TABLE|
|demo|bookings\_copy|bookings\_2026\_02|BASE TABLE|
|demo|bookings\_copy|bookings\_2026\_03|BASE TABLE|
|demo|bookings\_copy|bookings\_2026\_04|BASE TABLE|
|demo|bookings\_copy|bookings\_2026\_05|BASE TABLE|
|demo|bookings\_copy|bookings\_2026\_06|BASE TABLE|
|demo|bookings\_copy|bookings\_2026\_07|BASE TABLE|
|demo|bookings\_copy|bookings\_2026\_08|BASE TABLE|
|demo|bookings\_copy|bookings\_other|BASE TABLE|

###### 

###### **Копируем данные**



INSERT INTO bookings\_copy.bookings
SELECT \* FROM bookings.bookings;



###### **Сделаем очистку и соберем статистику для оптимизатора**



VACUUM ANALYZE bookings\_copy.bookings;



###### **Посмотрим данные в секциях**



SELECT '2025-09' AS "Section", COUNT() AS "Rows", MIN(book\_date) AS "MinBookDate", MAX(book\_date) AS "MaxBookDate" FROM bookings\_copy.bookings\_2025\_09
UNION ALL
SELECT '2025-10' AS "Section", COUNT() AS "Rows", MIN(book\_date) AS "MinBookDate", MAX(book\_date) AS "MaxBookDate" FROM bookings\_copy.bookings\_2025\_10
UNION ALL
SELECT '2025-11' AS "Section", COUNT() AS "Rows", MIN(book\_date) AS "MinBookDate", MAX(book\_date) AS "MaxBookDate" FROM bookings\_copy.bookings\_2025\_11
UNION ALL
SELECT '2025-12' AS "Section", COUNT() AS "Rows", MIN(book\_date) AS "MinBookDate", MAX(book\_date) AS "MaxBookDate" FROM bookings\_copy.bookings\_2025\_12
UNION ALL
SELECT '2026-01' AS "Section", COUNT() AS "Rows", MIN(book\_date) AS "MinBookDate", MAX(book\_date) AS "MaxBookDate" FROM bookings\_copy.bookings\_2026\_01
UNION ALL
SELECT '2026-02' AS "Section", COUNT() AS "Rows", MIN(book\_date) AS "MinBookDate", MAX(book\_date) AS "MaxBookDate" FROM bookings\_copy.bookings\_2026\_02
UNION ALL
SELECT '2026-03' AS "Section", COUNT() AS "Rows", MIN(book\_date) AS "MinBookDate", MAX(book\_date) AS "MaxBookDate" FROM bookings\_copy.bookings\_2026\_03
UNION ALL
SELECT '2026-04' AS "Section", COUNT() AS "Rows", MIN(book\_date) AS "MinBookDate", MAX(book\_date) AS "MaxBookDate" FROM bookings\_copy.bookings\_2026\_04
UNION ALL
SELECT '2026-05' AS "Section", COUNT() AS "Rows", MIN(book\_date) AS "MinBookDate", MAX(book\_date) AS "MaxBookDate" FROM bookings\_copy.bookings\_2026\_05
UNION ALL
SELECT '2026-06' AS "Section", COUNT() AS "Rows", MIN(book\_date) AS "MinBookDate", MAX(book\_date) AS "MaxBookDate" FROM bookings\_copy.bookings\_2026\_06
UNION ALL
SELECT '2026-07' AS "Section", COUNT() AS "Rows", MIN(book\_date) AS "MinBookDate", MAX(book\_date) AS "MaxBookDate" FROM bookings\_copy.bookings\_2026\_07
UNION ALL
SELECT '2026-08' AS "Section", COUNT() AS "Rows", MIN(book\_date) AS "MinBookDate", MAX(book\_date) AS "MaxBookDate" FROM bookings\_copy.bookings\_2026\_08
ORDER BY 1;


|**Section**|**Rows**|**MinBookDate**|**MaxBookDate**|
|-|-|-|-|
|2025-09|448064|2025-09-01 00:00:06.265219+00|2025-09-30 23:59:58.026243+00|
|2025-10|434159|2025-10-01 00:00:08.899725+00|2025-10-31 23:59:53.263233+00|
|2025-11|410670|2025-11-01 00:00:01.790251+00|2025-11-30 23:59:28.616825+00|
|2025-12|410796|2025-12-01 00:00:00.372488+00|2025-12-31 23:59:40.191846+00|
|2026-01|412036|2026-01-01 00:00:01.314353+00|2026-01-31 23:59:54.499781+00|
|2026-02|370985|2026-02-01 00:00:19.902319+00|2026-02-28 23:59:58.993676+00|
|2026-03|408667|2026-03-01 00:00:08.455494+00|2026-03-31 23:59:58.526315+00|
|2026-04|383124|2026-04-01 00:00:12.949237+00|2026-04-30 23:59:31.125808+00|
|2026-05|399596|2026-05-01 00:00:23.516073+00|2026-05-31 23:59:48.496859+00|
|2026-06|403237|2026-06-01 00:00:10.49019+00|2026-06-30 23:59:59.951396+00|
|2026-07|411392|2026-07-01 00:00:06.299438+00|2026-07-31 23:59:54.689055+00|
|2026-08|412512|2026-08-01 00:00:08.873243+00|2026-08-31 23:59:58.283465+00|


Видим, что данные перенеслись корректно


###### **Посмотрим время извлечения данных из монолитной таблицы**


VACUUM ANALYZE bookings.bookings;
EXPLAIN ANALYZE
SELECT \* FROM bookings.bookings WHERE book\_date BETWEEN '2025-10-01' AND '2025-10-30';


|**QUERY PLAN**|
|-|
|Gather  (cost=1000.00..103637.14 rows=406994 width=21) (actual time=30.944..314.811 rows=407769.00 loops=1)|
|&nbsp;&nbsp;Workers Planned: 2|
|&nbsp;&nbsp;Workers Launched: 2|
|&nbsp;&nbsp;Buffers: shared hit=3 read=31277|
|&nbsp;&nbsp;->  Parallel Seq Scan on bookings  (cost=0.00..61937.74 rows=169581 width=21) (actual time=15.520..277.306 rows=135923.00 loops=3)|
|&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Filter: ((book\_date >= '2025-10-01 00:00:00+00'::timestamp with time zone) AND (book\_date <= '2025-10-30 00:00:00+00'::timestamp with time zone))|
|&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Rows Removed by Filter: 1499156|
|&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Buffers: shared hit=3 read=31277|
|Planning Time: 0.073 ms|
|JIT:|
|&nbsp;&nbsp;Functions: 6|
|&nbsp;&nbsp;Options: Inlining false, Optimization false, Expressions true, Deforming true|
|&nbsp;&nbsp;Timing: Generation 1.026 ms (Deform 0.153 ms), Inlining 0.000 ms, Optimization 3.529 ms, Emission 41.953 ms, Total 46.508 ms|
|Execution Time: 480.203 ms|

###### 

**Посмотрим время извлечения данных из секциониированной таблицы**


VACUUM ANALYZE bookings\_copy.bookings;
EXPLAIN ANALYZE
SELECT \* FROM bookings\_copy.bookings WHERE book\_date BETWEEN '2025-10-01' AND '2025-10-30';


|**QUERY PLAN**|
|-|
|Seq Scan on bookings\_2025\_10 bookings  (cost=0.00..9278.38 rows=407842 width=21) (actual time=0.381..30.611 rows=407769.00 loops=1)|
|&nbsp;&nbsp;Filter: ((book\_date >= '2025-10-01 00:00:00+00'::timestamp with time zone) AND (book\_date <= '2025-10-30 00:00:00+00'::timestamp with time zone))|
|&nbsp;&nbsp;Rows Removed by Filter: 26390|
|&nbsp;&nbsp;Buffers: shared read=2766|
|Planning:|
|&nbsp;&nbsp;Buffers: shared hit=174 read=11|
|Planning Time: 5.812 ms|
|Execution Time: 42.177 ms|


Видим, что время извлечения данных уменьшилось на порядок!


###### **Посмотрим время извлечения данных из монолитной таблицы при помощи индекса**


DROP INDEX IF EXISTS bookings.ix\_bookings\_\_book\_date;
CREATE INDEX IF NOT EXISTS ix\_bookings\_\_book\_date ON bookings.bookings USING btree (book\_date);
VACUUM ANALYZE bookings.bookings;
EXPLAIN ANALYZE
SELECT book\_date FROM bookings.bookings WHERE book\_date BETWEEN '2025-10-01' AND '2025-10-21';


|**QUERY PLAN**|
|-|
|Index Only Scan using ix\_bookings\_\_book\_date on bookings  (cost=0.43..8532.01 rows=275379 width=8) (actual time=0.115..19.854 rows=285669.00 loops=1)|
|&nbsp;&nbsp;Index Cond: ((book\_date >= '2025-10-01 00:00:00+00'::timestamp with time zone) AND (book\_date <= '2025-10-21 00:00:00+00'::timestamp with time zone))|
|&nbsp;&nbsp;Heap Fetches: 0|
|&nbsp;&nbsp;Index Searches: 1|
|&nbsp;&nbsp;Buffers: shared read=784|
|Planning Time: 0.077 ms|
|Execution Time: 26.548 ms|

###### 

###### **Посмотрим время извлечения данных из секциониированной таблицы при помощи индекса на всю таблицу**


DROP INDEX IF EXISTS bookings\_copy.ix\_bookings\_copy\_\_book\_date;
CREATE INDEX IF NOT EXISTS ix\_bookings\_copy\_\_book\_date ON bookings\_copy.bookings USING btree (book\_date);
VACUUM ANALYZE bookings\_copy.bookings;
EXPLAIN ANALYZE
SELECT book\_date FROM bookings\_copy.bookings WHERE book\_date BETWEEN '2025-10-01' AND '2025-10-21';


|**QUERY PLAN**|
|-|
|Index Only Scan using bookings\_2025\_10\_book\_date\_idx on bookings\_2025\_10 bookings  (cost=0.42..8858.34 rows=285696 width=8) (actual time=0.011..18.664 rows=285669.00 loops=1)|
|&nbsp;&nbsp;Index Cond: ((book\_date >= '2025-10-01 00:00:00+00'::timestamp with time zone) AND (book\_date <= '2025-10-21 00:00:00+00'::timestamp with time zone))|
|&nbsp;&nbsp;Heap Fetches: 0|
|&nbsp;&nbsp;Index Searches: 1|
|&nbsp;&nbsp;Buffers: shared hit=4 read=780|
|Planning:|
|&nbsp;&nbsp;Buffers: shared hit=25 read=3|
|Planning Time: 0.220 ms|
|Execution Time: 27.686 ms|


Видим, что индекс на всю таблицу ix\_bookings\_copy\_\_book\_date не используется,
вместо него оптимизатор взял индекс на секции bookings\_2025\_10\_book\_date\_idx


###### **Попробуем построить индекс прямо на секции**


DROP INDEX IF EXISTS bookings\_copy.ix\_bookings\_copy\_2025\_10\_\_book\_date;
CREATE INDEX IF NOT EXISTS ix\_bookings\_copy\_2025\_10\_\_book\_date ON bookings\_copy.bookings\_2025\_10 USING btree (book\_date);
VACUUM ANALYZE bookings\_copy.bookings\_2025\_10;
EXPLAIN ANALYZE
SELECT book\_date FROM bookings\_copy.bookings WHERE book\_date BETWEEN '2025-10-01' AND '2025-10-21';


|**QUERY PLAN**|
|-|
|Index Only Scan using ix\_bookings\_copy\_2025\_10\_\_book\_date on bookings\_2025\_10 bookings  (cost=0.42..8879.02 rows=286330 width=8) (actual time=0.014..18.204 rows=285669.00 loops=1)|
|&nbsp;&nbsp;Index Cond: ((book\_date >= '2025-10-01 00:00:00+00'::timestamp with time zone) AND (book\_date <= '2025-10-21 00:00:00+00'::timestamp with time zone))|
|&nbsp;&nbsp;Heap Fetches: 0|
|&nbsp;&nbsp;Index Searches: 1|
|&nbsp;&nbsp;Buffers: shared hit=4 read=780|
|Planning:|
|&nbsp;&nbsp;Buffers: shared hit=17 read=3|
|Planning Time: 0.270 ms|
|Execution Time: 24.587 ms|


В этот раз используется наш индекс


###### **Попробуем поменять какую-нибудь дату бронирования**


SELECT \* FROM bookings\_copy.bookings\_2025\_10 WHERE book\_ref = 'LI06OY';


|**book\_ref**|**book\_date**|**total\_amount**|
|-|-|-|
|LI06OY|2025-10-01 00:11:31.311662+00|7475.00|



SELECT \* FROM bookings\_copy.bookings\_2025\_11 WHERE book\_ref = 'LI06OY';


|**book\_ref**|**book\_date**|**total\_amount**|
|-|-|-|



UPDATE bookings\_copy.bookings SET book\_date = '2025-11-01 00:11:31.311662+00' WHERE book\_ref = 'LI06OY';


SELECT \* FROM bookings\_copy.bookings\_2025\_10 WHERE book\_ref = 'LI06OY';


|**book\_ref**|**book\_date**|**total\_amount**|
|-|-|-|


SELECT \* FROM bookings\_copy.bookings\_2025\_11 WHERE book\_ref = 'LI06OY';


|**book\_ref**|**book\_date**|**total\_amount**|
|-|-|-|
|LI06OY|2025-11-01 00:11:31.311662+00|7475.00|


Все верно, так как дату изменили с 1 октября на 1 ноября,
запись переместилась из секции 2025\_10 в секцию 2025\_11


###### **Попробуем вставить новую запис**ь


SELECT \* FROM bookings\_copy.bookings\_2025\_12 WHERE book\_ref = 'YI06OY';


|**book\_ref**|**book\_date**|**total\_amount**|
|-|-|-|


INSERT INTO bookings\_copy.bookings(book\_ref, book\_date, total\_amount)
VALUES ('YI06OY', '2025-12-12', 1111.00);


SELECT \* FROM bookings\_copy.bookings\_2025\_12 WHERE book\_ref = 'YI06OY';


|**book\_ref**|**book\_date**|**total\_amount**|
|-|-|-|
|YI06OY|2025-12-12 00:00:00+00|1111.00|


Как и ожидалось, находим нашу новую запись в секции 2025\_12


###### **Вывод**


&nbsp;&nbsp;Секционирование улучшает производительность в случае если запросы работают с данными
&nbsp;&nbsp;умещающимися внутрь одной секции (то есть в фильтре используется поле разбиения),
&nbsp;&nbsp;в противном случае секционирование даже вредно.
&nbsp;&nbsp;Поэтому очень важно продумать стратегию разбиения данных.

