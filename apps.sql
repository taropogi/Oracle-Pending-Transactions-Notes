select wdd.source_header_id, ooh.order_number,wnd.delivery_id, wnd.name, wdd.delivery_detail_id, wdd.source_line_id,
wdl.pick_up_stop_id, wdd.inv_interfaced_flag, wdd.oe_interfaced_flag, wdd.released_status
from wsh_delivery_details wdd, wsh_delivery_assignments wda,
wsh_new_deliveries wnd, wsh_delivery_legs wdl, wsh_trip_stops wts,
oe_order_headers_all ooh, oe_order_lines_all ool
where wdd.source_code = 'OE'
and wdd.released_status = 'C'
and wdd.inv_interfaced_flag in ('N' ,'P')
and wdd.organization_id = &organization_id
and wda.delivery_detail_id = wdd.delivery_detail_id
and wnd.delivery_id = wda.delivery_id
and wnd.status_code in ('CL','IT')
and wdl.delivery_id = wnd.delivery_id
and trunc(wts.actual_departure_date) between '&period_start_date'and '&period_end_date'
and wdl.pick_up_stop_id = wts.stop_id
and wdd.source_header_id = ooh.header_id
and wdd.source_line_id = ool.line_id