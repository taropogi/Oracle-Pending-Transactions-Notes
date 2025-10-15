SELECT
    md.demand_id,
    md.demand_source_line,
    md.line_item_quantity demand_quantity,
    mr.reservation_id,
    mr.primary_reservation_quantity
FROM
    mtl_demand md,
    mtl_reservations mr
WHERE
    mr.demand_source_line_id (+) = md.demand_source_line
    and nvl (md.line_item_quantity, 0) != mr.primary_reservation_quantity
    AND md.reservation_type = 2;

-- 2 could mean sales order reservation, please verify in your system