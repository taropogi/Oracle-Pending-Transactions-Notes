SELECT wdd.source_header_id,
       ooh.order_number,
       wnd.delivery_id,
       wnd.name,
       wdd.delivery_detail_id,
       wdd.source_line_id,
       wdl.pick_up_stop_id,
       wdd.inv_interfaced_flag,
       wdd.oe_interfaced_flag,
       wdd.released_status
FROM wsh_delivery_details wdd,
     wsh_delivery_assignments wda,
     wsh_new_deliveries wnd,
     wsh_delivery_legs wdl,
     wsh_trip_stops wts,
     oe_order_headers_all ooh,
     oe_order_lines_all ool
WHERE wdd.source_code = 'OE'
  AND wdd.released_status = 'C'
  AND wdd.inv_interfaced_flag IN ('N', 'P')
  AND wdd.organization_id = &organization_id
  AND wda.delivery_detail_id = wdd.delivery_detail_id
  AND wnd.delivery_id = wda.delivery_id
  AND wnd.status_code IN ('CL', 'IT')
  AND wdl.delivery_id = wnd.delivery_id
  AND TRUNC(wts.actual_departure_date) BETWEEN '&period_start_date' AND '&period_end_date'
  AND wdl.pick_up_stop_id = wts.stop_id
  AND wdd.source_header_id = ooh.header_id
  AND wdd.source_line_id = ool.line_id;