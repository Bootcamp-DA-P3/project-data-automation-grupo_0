-- GRANO: una fila = un pedido entregado (order_id)
--
-- orders y customers van 1 a 1 (customer_id es clave primaria en customers),
-- asi que ese JOIN no multiplica. Las resenas si lo harian: se agregan antes.
-- dias_desvio es negativo cuando la entrega llega antes de lo estimado.

WITH nota_por_pedido AS (
    SELECT
        order_id,
        AVG(review_score) AS nota
    FROM order_reviews
    GROUP BY order_id
)
SELECT
    o.order_id,
    c.customer_state AS estado,
    DATE(o.order_purchase_timestamp)      AS fecha_compra,
    DATE(o.order_delivered_customer_date) AS fecha_entrega,
    DATE(o.order_estimated_delivery_date) AS fecha_estimada,
    DATEDIFF(o.order_delivered_customer_date, o.order_purchase_timestamp)    AS dias_entrega,
    DATEDIFF(o.order_delivered_customer_date, o.order_estimated_delivery_date) AS dias_desvio,
    CASE
        WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date THEN 'retrasado'
        ELSE 'a tiempo'
    END AS cumplimiento,
    ROUND(n.nota, 2) AS nota
FROM orders o
JOIN customers c
    ON c.customer_id = o.customer_id
LEFT JOIN nota_por_pedido n
    ON n.order_id = o.order_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
ORDER BY dias_desvio DESC
