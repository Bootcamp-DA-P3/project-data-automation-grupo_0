-- GRANO: una fila = una linea de pedido entregado (linea_id)
-- PAPEL: TABLA DE HECHOS. Mide. Es el centro del modelo:
--         las otras cuatro se unen a ella por su clave.
--
-- Esta es la TABLA DE HECHOS del modelo. No agrega nada: order_items ya viene
-- al grano de linea. Lo que anade son las claves foraneas que permiten
-- relacionarla con las otras cuatro tablas dentro de Excel y de Power BI.
--
-- Sin esta tabla las otras cuatro son islas: ninguna comparte clave con otra.
--
-- No lleva payment_value a proposito. Los pagos estan al grano de PEDIDO, no
-- de linea: meterlos aqui multiplicaria el importe por el numero de lineas.
-- La facturacion de esta tabla es precio + flete.

SELECT
    CONCAT(i.order_id, '-', i.order_item_id) AS linea_id,
    i.order_id,
    c.customer_unique_id,
    i.product_id,
    i.seller_id,
    DATE(o.order_purchase_timestamp) AS fecha_compra,
    i.price                   AS precio,
    i.freight_value           AS flete,
    i.price + i.freight_value AS importe_linea
FROM order_items i
JOIN orders o
    ON o.order_id = i.order_id
JOIN customers c
    ON c.customer_id = o.customer_id
-- Mismo filtro que entregas_retrasos, para que las dos tablas encajen fila a fila.
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
