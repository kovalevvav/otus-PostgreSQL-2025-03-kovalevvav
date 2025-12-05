-- Для создания таблиц и витрины вместо исходного скрипта hw_triggers.sql
-- использовался модифицированный скрипт hw_triggers-good-to-goods.sql,
-- в котором все good заменены на goods для удобства

-- выставим порядок поиска по схемам, чтобы не писать схему
SET search_path = pract_functions, testnm, public;

-- Для повышения производительности будем использовать уровень оператора

-- Создадим триггерную функцию для вставки
CREATE OR REPLACE FUNCTION fn_fill_goods_sum_mart_after_ins_sales() RETURNS TRIGGER AS $$ BEGIN
    WITH cte AS (
        SELECT g.goods_name AS goods_name, SUM(g.goods_price * s.sales_qty) AS sum_sale
        FROM goods g
        INNER JOIN sales s ON s.goods_id = g.goods_id
        WHERE g.goods_id  IN (SELECT goods_id FROM ins)
        GROUP BY g.goods_name)
    MERGE INTO goods_sum_mart AS t
    USING cte AS s ON s.goods_name = t.goods_name
    WHEN MATCHED THEN UPDATE SET
        sum_sale = s.sum_sale
    WHEN NOT MATCHED BY TARGET THEN
        INSERT (goods_name, sum_sale)
        VALUES (s.goods_name, s.sum_sale);
    RETURN NULL; -- Для триггеров AFTER на уровне оператора возвращаемое значение игнорируется
END;
$$ LANGUAGE plpgsql;
-- Создадим  триггер на таблице sales, после вставки
-- Так как триггер нужен для переноса данных, используем AFTER
CREATE OR REPLACE TRIGGER tg_after_ins_sales
AFTER INSERT ON sales -- Срабатывает в таблице sales после вставки
REFERENCING NEW TABLE AS ins -- доступ к Transition Tables
FOR EACH STATEMENT -- Выполняется для каждого оператора
EXECUTE FUNCTION fn_fill_goods_sum_mart_after_ins_sales();

-- Создадим триггерную функцию для обновления-удаления
CREATE OR REPLACE FUNCTION fn_fill_goods_sum_mart_after_upd_del_sales() RETURNS TRIGGER AS $$ BEGIN
    WITH cte AS (
        SELECT g.goods_name AS goods_name, SUM(g.goods_price * s.sales_qty) AS sum_sale
        FROM goods g
        INNER JOIN sales s ON s.goods_id = g.goods_id
        WHERE g.goods_id IN (SELECT goods_id FROM del)
        GROUP BY g.goods_name
        HAVING SUM(g.goods_price * s.sales_qty) > 0) -- вставляем-обновляем только с суммами > 0
    MERGE INTO goods_sum_mart AS t
    USING cte AS s ON s.goods_name = t.goods_name
    WHEN MATCHED THEN UPDATE SET
        sum_sale = s.sum_sale
    WHEN NOT MATCHED BY TARGET THEN
        INSERT (goods_name, sum_sale)
        VALUES (s.goods_name, s.sum_sale);

    WITH cte AS (
        SELECT g.goods_name AS goods_name, SUM(g.goods_price * s.sales_qty) AS sum_sale
        FROM goods g
        INNER JOIN sales s ON s.goods_id = g.goods_id
        WHERE g.goods_id IN (SELECT goods_id FROM del)
        GROUP BY g.goods_name
        HAVING SUM(g.goods_price * s.sales_qty) <= 0) -- удаляем все с 0
    DELETE FROM goods_sum_mart WHERE goods_name IN (SELECT goods_name FROM cte);
    RETURN NULL; -- Для триггеров AFTER на уровне оператора возвращаемое значение игнорируется
END;
$$ LANGUAGE plpgsql;
-- Создадим  триггер на таблице sales, после обновления
-- Так как триггер нужен для переноса данных, используем AFTER
CREATE OR REPLACE TRIGGER tg_after_upd_sales
AFTER UPDATE ON sales -- Срабатывает в таблице sales после обновления
REFERENCING OLD TABLE AS del -- доступ к Transition Tables
FOR EACH STATEMENT -- Выполняется для каждого оператора
EXECUTE FUNCTION fn_fill_goods_sum_mart_after_upd_del_sales();
-- Создадим  триггер на таблице sales, после удаления
-- Так как триггер нужен для переноса данных, используем AFTER
CREATE OR REPLACE TRIGGER tg_after_del_sales
AFTER DELETE ON sales -- Срабатывает в таблице sales после удаления
REFERENCING OLD TABLE AS del -- доступ к Transition Tables
FOR EACH STATEMENT -- Выполняется для каждого оператора
EXECUTE FUNCTION fn_fill_goods_sum_mart_after_upd_del_sales();

/*
-- Наполним витрину текущими данными, выполнив фиктивный update
SELECT * FROM goods_sum_mart;
UPDATE sales SET sales_qty = sales_qty;
SELECT * FROM goods_sum_mart;

-- Обновим данные продаж select * from sales;
UPDATE sales SET sales_qty = 2 * sales_qty;
-- отчет
SELECT g.goods_name, sum(g.goods_price * s.sales_qty)
FROM goods g
INNER JOIN sales s ON s.goods_id = g.goods_id
GROUP BY g.goods_name
ORDER BY goods_name;
-- витрина
SELECT * FROM goods_sum_mart ORDER BY goods_name;

-- Добавим новые строки
INSERT INTO sales (goods_id, sales_qty)
VALUES (2, 10), (2, 1), (2, 120), (1, 1);
-- отчет
SELECT g.goods_name, sum(g.goods_price * s.sales_qty)
FROM goods g
INNER JOIN sales s ON s.goods_id = g.goods_id
GROUP BY g.goods_name
ORDER BY goods_name;
-- витрина
SELECT * FROM goods_sum_mart ORDER BY goods_name;

-- Удалим строки
DELETE FROM sales WHERE sales_id > 4;
-- отчет
SELECT g.goods_name, sum(g.goods_price * s.sales_qty)
FROM goods g
INNER JOIN sales s ON s.goods_id = g.goods_id
GROUP BY g.goods_name
ORDER BY goods_name;
-- витрина
SELECT * FROM goods_sum_mart ORDER BY goods_name;

-- Чем такая схема (витрина+триггер) предпочтительнее отчета, создаваемого "по требованию" (кроме производительности)?
-- Подсказка: В реальной жизни возможны изменения цен.

тем, что при изменении цен и отсутствии продаж мы видим в витрине актуальную картину, тода как в отчете по требованию увидим сразу новые суммы

*/