SELECT
    mr.reservation_id,
    mr.demand_source_line_id,
    mr.inventory_item_id,
    mr.organization_id,
    mr.reservation_quantity,
    mr.primary_reservation_quantity
FROM
    mtl_reservations mr
WHERE
    NOT EXISTS (
        SELECT
            1
        FROM
            oe_order_lines_all ool
        WHERE
            ool.line_id = mr.demand_source_line_id
    );