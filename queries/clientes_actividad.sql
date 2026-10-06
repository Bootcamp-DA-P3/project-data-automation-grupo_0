-- GRANO: una fila = un cliente unico (customer_unique_id)
--
-- customer_id cambia en cada pedido; customer_unique_id es la persona.
-- Los pagos se agregan por pedido ANTES de unirlos, porque un pedido puede
-- tener varias filas en order_payments (tarjeta + voucher) y el JOIN directo
-- duplicaria el gasto.

WITH pago_por_pedido AS (
    SELECT
        order_id,
        SUM(payment_value) AS valor_pedido
    FROM order_payments
    GROUP BY order_id
)
SELECT
    c.customer_unique_id,
    -- Un cliente unico puede tener varias direcciones. Nos quedamos con una.
    MAX(c.customer_state) AS estado,
    MAX(c.customer_city)  AS ciudad,
    COUNT(DISTINCT o.order_id)                       AS pedidos,
    ROUND(SUM(p.valor_pedido), 2)                    AS gasto_total,
    ROUND(SUM(p.valor_pedido) / COUNT(DISTINCT o.order_id), 2) AS ticket_medio,
    DATE(MIN(o.order_purchase_timestamp))            AS primera_compra,
    DATE(MAX(o.order_purchase_timestamp))            AS ultima_compra
FROM customers c
JOIN orders o
    ON o.customer_id = c.customer_id
-- INNER JOIN: se descartan los pedidos sin pago registrado.
JOIN pago_por_pedido p
    ON p.order_id = o.order_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_unique_id
ORDER BY gasto_total DESC
