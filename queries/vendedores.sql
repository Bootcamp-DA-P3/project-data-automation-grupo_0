-- GRANO: una fila = un vendedor (seller_id)
--
-- Dos agregaciones previas, por el mismo motivo en los dos casos:
--   venta_por_vendedor: un vendedor tiene muchas lineas en order_items.
--   nota_por_pedido:    un pedido puede tener mas de una resena.
-- Unir cualquiera de las dos sin agregar antes multiplicaria las filas
-- y falsearia tanto los ingresos como la nota media.

WITH venta_por_vendedor AS (
    SELECT
        seller_id,
        COUNT(*)                 AS unidades,
        COUNT(DISTINCT order_id) AS pedidos,
        SUM(price)               AS ingresos,
        SUM(freight_value)       AS flete
    FROM order_items
    GROUP BY seller_id
),
pedido_de_vendedor AS (
    SELECT DISTINCT seller_id, order_id
    FROM order_items
),
nota_por_pedido AS (
    SELECT
        order_id,
        AVG(review_score) AS nota
    FROM order_reviews
    GROUP BY order_id
),
nota_por_vendedor AS (
    SELECT
        pv.seller_id,
        ROUND(AVG(n.nota), 2) AS nota_media,
        COUNT(*)              AS pedidos_valorados
    FROM pedido_de_vendedor pv
    JOIN nota_por_pedido n
        ON n.order_id = pv.order_id
    GROUP BY pv.seller_id
)
SELECT
    s.seller_id,
    s.seller_state AS estado,
    s.seller_city  AS ciudad,
    COALESCE(v.pedidos, 0)            AS pedidos,
    COALESCE(v.unidades, 0)           AS unidades,
    ROUND(COALESCE(v.ingresos, 0), 2) AS ingresos,
    ROUND(COALESCE(v.flete, 0), 2)    AS flete,
    n.nota_media,
    COALESCE(n.pedidos_valorados, 0)  AS pedidos_valorados
FROM sellers s
LEFT JOIN venta_por_vendedor v
    ON v.seller_id = s.seller_id
LEFT JOIN nota_por_vendedor n
    ON n.seller_id = s.seller_id
ORDER BY ingresos DESC
