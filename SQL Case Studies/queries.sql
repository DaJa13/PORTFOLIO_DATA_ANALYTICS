
-- 1. Общая сумма платежей по компаниям
SELECT
    c.id,
    c.name,
    SUM(p.amount) AS total_payments
FROM crm_company c
JOIN crm_payments p
    ON p.company__id = c.id
GROUP BY c.id, c.name
ORDER BY total_payments DESC;


-- 2. Средний платеж по компаниям
SELECT
    c.id,
    c.name,
    AVG(p.amount) AS avg_payment
FROM crm_company c
JOIN crm_payments p
    ON p.company__id = c.id
GROUP BY c.id, c.name
ORDER BY avg_payment DESC;


-- 3. Количество платежей по компаниям
SELECT
    c.id,
    c.name,
    COUNT(p.id) AS payments_count
FROM crm_company c
JOIN crm_payments p
    ON p.company__id = c.id
GROUP BY c.id, c.name
ORDER BY payments_count DESC;


-- 4. Активность компаний (выручка + количество + средний чек)
SELECT
    c.id,
    c.name,
    COUNT(p.id) AS payments_count,
    COALESCE(SUM(p.amount), 0) AS total_payments,
    COALESCE(AVG(p.amount), 0) AS avg_payment
FROM crm_company c
LEFT JOIN crm_payments p
    ON p.company__id = c.id
GROUP BY c.id, c.name
ORDER BY total_payments DESC;


-- 5. Количество компаний по месяцам,
SELECT
    TO_CHAR(date_issue, 'YYYY-MM') AS month,
    COUNT(*) AS companies
FROM crm_company
GROUP BY TO_CHAR(date_issue, 'YYYY-MM')
ORDER BY month;

-- 6. Количество контактов по компаниям
SELECT
    c.id,
    c.name,
    COUNT(ct.id) AS contacts_count
FROM crm_company c
LEFT JOIN crm_contact ct
    ON ct.company__id = c.id
GROUP BY c.id, c.name
ORDER BY contacts_count DESC;


-- 7. Количество напоминаний по компаниям
SELECT
    c.id,
    c.name,
    COUNT(r.id) AS reminders_count
FROM crm_company c
LEFT JOIN crm_reminder r
    ON r.company__id = c.id
GROUP BY c.id, c.name
ORDER BY reminders_count DESC;


-- 8. Сегментация выручки (VIP / Средний / Низкий)
SELECT
    c.id,
    c.name,
    COALESCE(SUM(p.amount), 0) AS total_payments,
    CASE
        WHEN COALESCE(SUM(p.amount), 0) >= 90000 THEN 'VIP'
        WHEN COALESCE(SUM(p.amount), 0) > 10000 THEN 'Средний'
        ELSE 'Низкий'
    END AS segment
FROM crm_company c
LEFT JOIN crm_payments p
    ON p.company__id = c.id
GROUP BY c.id, c.name
ORDER BY total_payments DESC;


-- 9. Постоянные клиенты (2+ платежа)
SELECT
    c.id,
    c.name,
    COUNT(p.id) AS payments_count,
    SUM(p.amount) AS revenue
FROM crm_company c
LEFT JOIN crm_payments p
    ON p.company__id = c.id
GROUP BY c.id, c.name
HAVING COUNT(p.id) >= 2
ORDER BY revenue DESC;


-- 10. Клиенты с низкой активностью (1 платеж)

SELECT
    c.id,
    c.name,
    COUNT(p.id) AS payments_count
FROM crm_company c
JOIN crm_payments p
    ON p.company__id = c.id
GROUP BY c.name
HAVING COUNT(p.id) = 1;

-- 11. Последний платеж клиента (по id как прокси времени)

WITH ranked_payments AS (
    SELECT
        company__id,
        amount,
        id,
        ROW_NUMBER() OVER (
            PARTITION BY company__id
            ORDER BY id DESC
        ) AS rn
    FROM crm_payments
)
SELECT
    c.id,
    c.name,
    rp.amount,
    rp.id AS payment_id
FROM crm_company c
JOIN ranked_payments rp
    ON rp.company__id = c.id
WHERE rp.rn = 1
ORDER BY rp.id DESC;

-- 12. Прибыльность сертификатов
SELECT
    vc.name AS certificate,
    COUNT(DISTINCT c.id) AS companies,
    COALESCE(SUM(p.amount), 0) AS revenue
FROM crm_company c
LEFT JOIN crm_view_certificate vc
    ON vc.id = c.view_certificate__id
LEFT JOIN crm_payments p
    ON p.company__id = c.id
GROUP BY vc.name
ORDER BY revenue DESC;


-- 13. Сертификаты с истечением в ближайшие 30 дней
SELECT
    c.id,
    c.name,
    vc.name AS certificate,
    c.date_end,
    COUNT(r.id) AS reminders_count
FROM crm_company c
LEFT JOIN crm_view_certificate vc
    ON vc.id = c.view_certificate__id
LEFT JOIN crm_reminder r
    ON r.company__id = c.id
WHERE c.date_end BETWEEN CURRENT_DATE
                      AND CURRENT_DATE + INTERVAL '30 days'
GROUP BY c.id, c.name, vc.name, c.date_end
ORDER BY c.date_end;


-- 14. Выгрузка email всех компаний
SELECT
    c.id,
    c.name,
    c.email
FROM crm_company c
WHERE c.email IS NOT NULL
AND c.email <> ''
ORDER BY c.name;


-- 154. Email-выгрузка по типам сертификатов
SELECT
    vc.name AS certificate_type,
    c.id,
    c.name,
    c.email
FROM crm_company c
JOIN crm_view_certificate vc
    ON vc.id = c.view_certificate__id
WHERE c.email IS NOT NULL
AND c.email <> ''
ORDER BY vc.name, c.name;
