/*
-- создаем БД
CREATE DATABASE testdb;
*/
-- создаем схему
DROP SCHEMA IF EXISTS testnm CASCADE;
CREATE SCHEMA IF NOT EXISTS testnm;

-- даем пользователю postgres права на схему testnm
GRANT USAGE ON SCHEMA testnm TO postgres;

-- выставим порядок поиска по схемам, чтобы не писать схему
SET search_path = testnm, public;

-- создаем таблицу 1 со 100 автосгенерированными записями
DROP TABLE IF EXISTS product1;
CREATE TABLE product1(id INT PRIMARY KEY, code TEXT NOT NULL);
INSERT INTO product1(id, code)
SELECT generate_series as id, LPAD(generate_series::text, 3, '0') as code FROM generate_series(1,100); 
SELECT * FROM product1;

-- создаем таблицу 2 со 100 автосгенерированными записями
DROP TABLE IF EXISTS product2;
CREATE TABLE product2(id INT PRIMARY KEY, code TEXT NOT NULL);
INSERT INTO product2(id, code)
SELECT generate_series as id, LPAD(generate_series::text, 3, '0') || LPAD(generate_series::text, 3, '0') as code FROM generate_series(1,100); 
SELECT * FROM testnm.product2;
