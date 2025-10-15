SET VERIFY OFF;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
WHENEVER SQLERROR EXIT FAILURE ROLLBACK;

clear buffer;
set serveroutput on size 500000
rem set feed off
set pagesize 1000
set linesize 120
set underline '-'

Prompt
Prompt This script will attempt to cancel delivery details that belong to a Cancelled Order Line
Prompt
accept order_line_id num prompt 'Enter DELIVERY DETAIL ID you want to Cancel: '
Prompt

spool &order_line_id

declare

  l_lin_id            NUMBER := &order_line_id;

begin

  dbms_output.put_line('Updating Delivery details for the Line ID: '||l_lin_id);

  update wsh_delivery_assignments 
  set    delivery_id               = null
  ,      parent_delivery_detail_id = null
  ,      last_updated_by           = -1
  ,      last_update_date          = sysdate
  where  delivery_detail_id      = l_lin_id;

  update wsh_delivery_details
  set    released_status         = 'D'
  ,      src_requested_quantity  = 0
  ,      src_requested_quantity2 = decode(src_requested_quantity2,NULL,NULL,0)
  ,      requested_quantity      = 0
  ,      requested_quantity2     = decode(requested_quantity2,NULL,NULL,0) 
  ,      shipped_quantity        = 0
  ,      shipped_quantity2       = decode(shipped_quantity2,NULL,NULL,0) 
  ,      picked_quantity         = 0
  ,      picked_quantity2        = decode(picked_quantity2,NULL,NULL,0) 
  ,      cycle_count_quantity    = 0
  ,      cycle_count_quantity2   = decode(src_requested_quantity2,NULL,NULL,0) 
  ,      cancelled_quantity      = decode(requested_quantity,0,cancelled_quantity,requested_quantity)
  ,      cancelled_quantity2     = decode(requested_quantity2,NULL,NULL,0,cancelled_quantity2,requested_quantity2) 
  ,      subinventory            = null
  ,      locator_id              = null
  ,      lot_number              = null
  ,      serial_number           = null
  ,      to_serial_number        = null
  ,      transaction_temp_id     = null
  ,      revision                = null
  ,      ship_set_id             = null
  ,      inv_interfaced_flag     = 'X'
  ,      oe_interfaced_flag      = 'X'
  ,      last_updated_by         = -1
  ,      last_update_date        = sysdate
  where delivery_detail_id   = l_lin_id
  and   source_code      = 'OE'
  and   released_status  <> 'D';

Commit;
end;
/
spool off;


