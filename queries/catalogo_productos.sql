-- GRANO: una fila = un producto (product_id)
-- PAPEL: dimension. Describe al producto.
--         Se une al hecho por product_id.
--
-- Las ventas se agregan por producto ANTES de unirlas al catalogo.
-- Si se uniera order_items directamente, un producto vendido 50 veces
-- apareceria en 50 filas.

WITH venta_por_producto AS (
    SELECT
        product_id,
        COUNT(*)                 AS unidades_vendidas,
        COUNT(DISTINCT order_id) AS pedidos,
        SUM(price)               AS ingresos,
        SUM(freight_value)       AS flete
    FROM order_items
    GROUP BY product_id
)
SELECT
    p.product_id,
    COALESCE(t.product_category_name_english, p.product_category_name, 'sin_categoria') AS categoria,
    p.product_weight_g   AS peso_g,
    p.product_photos_qty AS fotos,
    -- LEFT JOIN: hay productos en el catalogo que no se han vendido nunca.
    COALESCE(v.unidades_vendidas, 0)  AS unidades_vendidas,
    COALESCE(v.pedidos, 0)            AS pedidos,
    ROUND(COALESCE(v.ingresos, 0), 2) AS ingresos,
    ROUND(COALESCE(v.flete, 0), 2)    AS flete
FROM products p
-- Esta union es la que APLANA el copo de nieve.
-- En el origen, la categoria vive en su propia tabla de 71 filas: eso es una
-- rama de copo de nieve. Al unirla y quedarnos con el texto, la dimension pasa
-- a ser una sola tabla y el modelo queda en estrella.
LEFT JOIN categoria_traduccion t
    ON t.product_category_name = p.product_category_name
LEFT JOIN venta_por_producto v
    ON v.product_id = p.product_id
ORDER BY ingresos DESC
