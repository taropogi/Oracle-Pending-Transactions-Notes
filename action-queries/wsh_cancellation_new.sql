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
accept order_line_id num prompt 'Enter LINE_ID of the delivery details to Cancel: '
Prompt

spool &order_line_id

declare

  l_lin_id            NUMBER := &order_line_id;

  cursor line_check is
  select line_id
  from   oe_order_lines_all  
  where  line_id = l_lin_id
  and    cancelled_flag = 'Y';

  -- Cursors to fetch details and their Serial Number(s) 
  cursor wdd is
  select delivery_detail_id, transaction_temp_id, serial_number, inventory_item_id, to_serial_number
  from   wsh_delivery_details
  where  source_line_id = l_lin_id
  and    source_code = 'OE'
  and    released_status in ('Y','C');

  cursor msnt(txn_temp_id number) is
  select fm_serial_number, to_serial_number
  from   mtl_serial_numbers_temp
  where  transaction_temp_id = txn_temp_id;

  l_line_check        NUMBER;
  l_wms_org           VARCHAR2(1);
  l_otm_installed     VARCHAR2(1);
  l_otm_enabled       VARCHAR2(1);
  l_cursor            INTEGER;                
  l_stmt              VARCHAR2(4000);
  l_up_cursor         INTEGER;                
  l_up_stmt           VARCHAR2(4000);
  l_ignore            NUMBER;
  l_ship_from_org_id  NUMBER;
  l_opm_enabled       BOOLEAN;
  l_fm_serial         VARCHAR2(30);
  l_to_serial         VARCHAR2(30);
  l_heading           VARCHAR2(1) := 'N';
  Line_Cannot_Be_Updated EXCEPTION;

 cursor wsh_ifaced
  is
  select
    substr(wdd.source_line_number, 1, 15) line_num
  , substr(wdd.item_description, 1, 30) item_name
  , wdd.shipped_quantity
  , wdd.source_line_id line_id
  from  wsh_delivery_details wdd, oe_order_lines_all oel
  where wdd.inv_interfaced_flag     = 'Y'
  and   nvl(wdd.shipped_quantity,0) > 0
  and   oel.line_id                 = wdd.source_line_id
  and   oel.open_flag               = 'N'
  and   oel.ordered_quantity        = 0
  and   wdd.source_code             = 'OE'
  and   oel.line_id                 = l_lin_id
  and   exists
      ( select 'x'
        from  mtl_material_transactions mmt
        where wdd.delivery_detail_id   = mmt.picking_line_id
        and   mmt.trx_source_line_id   = wdd.source_line_id
        and   mmt.transaction_source_type_id in ( 2,8 ));

begin

  dbms_output.put_line('Updating Delivery details for the Line ID: '||l_lin_id);

  -- Check if line is already canceled 
  open line_check ;
  fetch line_check into l_line_check ;
  if line_check%notfound then 
     close line_check;
     dbms_output.put_line('Line is not cancelled');
     raise Line_Cannot_Be_Updated;
  end if;
  close line_check;
 
  -- Check if line belongs to WMS Org 
  begin
    select WSH_UTIL_VALIDATE.CHECK_WMS_ORG(ship_from_org_id), ship_from_org_id
    into   l_wms_org, l_ship_from_org_id
    from   oe_order_lines_all
    where  line_id = l_lin_id;
  exception 
    when no_data_found then
         dbms_output.put_line('Unable to get the Organization');
         raise Line_Cannot_Be_Updated;
  end;
  if l_wms_org = 'Y' then
     dbms_output.put_line('This line belongs to a WMS Organization');
     raise Line_Cannot_Be_Updated;
  end if;

  -- Check if OTM is installed or OTM is enabled for the Organization
  --{
  l_otm_installed := NVL(FND_PROFILE.VALUE('WSH_OTM_INSTALLED'), 'N');
  begin
    l_cursor := dbms_sql.open_cursor;
    l_stmt   := 'select wsp.otm_enabled from wsh_shipping_parameters wsp, oe_order_lines_all ol '||
                'where wsp.organization_id = ol.ship_from_org_id '||
                'and   ol.line_id = :line_id ';

    dbms_sql.parse(l_cursor, l_stmt, dbms_sql.v7);
    dbms_sql.define_column(l_cursor, 1, l_otm_enabled, 1);
    dbms_sql.bind_variable(l_cursor, ':line_id', l_lin_id);
    l_ignore := dbms_sql.execute(l_cursor);
    if dbms_sql.fetch_rows(l_cursor) > 0 then
       dbms_sql.column_value(l_cursor, 1, l_otm_enabled);
       --dbms_output.put_line('l_otm_enabled '||l_otm_enabled);
    end if;
    dbms_sql.close_cursor(l_cursor);
  exception
    when others then
      if dbms_sql.is_open(l_cursor) then
         dbms_sql.close_cursor(l_cursor);
      end if;
      if l_otm_installed in ('Y','O') then
         dbms_output.put_line('l_otm_installed '||l_otm_installed);
         dbms_output.put_line('OTM: Integration Enabled is enabled for Order Management');
         raise Line_Cannot_Be_Updated;
      end if;
  end;
  if NVL(l_otm_enabled, 'N') = 'Y' and l_otm_installed in ('Y','O') then
     dbms_output.put_line('l_otm_installed '||l_otm_installed||' , l_otm_enabled '||l_otm_enabled);
     dbms_output.put_line('OTM: Integration Enabled is enabled for Organization for which this Line belongs');
     raise Line_Cannot_Be_Updated;
  end if;
  --}
        
 for wsh_ifaced_rec in wsh_ifaced loop
    if l_heading = 'N' then
      dbms_output.put_line(' ');
      dbms_output.put_line('Following Cancelled Lines have already been Interfaced to Inventory.');
      dbms_output.put_line('Onhand Qty must be manually adjusted for these Items and Quantities.');
      dbms_output.put_line(' ');
      dbms_output.put_line('+---------------+------------------------------+---------------+---------------+');
      dbms_output.put_line('|Line No.       |Item Name                     |    Shipped Qty|        Line Id|');
      dbms_output.put_line('+---------------+------------------------------+---------------+---------------+');
      l_heading := 'Y';
    end if;
    dbms_output.put_line('|'||rpad(wsh_ifaced_rec.line_num, 15)||
                         '|'||rpad(wsh_ifaced_rec.item_name, 30)||
                         '|'||lpad(to_char(wsh_ifaced_rec.shipped_quantity), 15)||
                           '|'||lpad(to_char(wsh_ifaced_rec.line_id), 15)||'|');
  end loop;

  update wsh_delivery_assignments 
  set    delivery_id               = null
  ,      parent_delivery_detail_id = null
  ,      last_updated_by           = -1
  ,      last_update_date          = sysdate
  where  delivery_detail_id        in 
        (select wdd.delivery_detail_id
         from   wsh_delivery_details wdd, oe_order_lines_all oel
         where  wdd.source_line_id   = oel.line_id
          and   wdd.source_code      = 'OE'
          and   oel.cancelled_flag   = 'Y'
          and   oel.line_id          = l_lin_id
          and   released_status      <> 'D');

  -- Check if Org is an OPM or Inventory Org
  l_opm_enabled := INV_GMI_RSV_BRANCH.PROCESS_BRANCH(p_organization_id => l_ship_from_org_id);

  if not l_opm_enabled then 
  --{
     -- Inventory Org
     -- Updating Move Order lines for Released To Warehouse details as 'Cancelled by Source'
     update mtl_txn_request_lines
     set    line_status = 9
     where  line_id in ( select move_order_line_id
                         from   wsh_delivery_details 
                         where  source_line_id = l_lin_id
                         and    released_status = 'S'
                         and    source_code = 'OE' );

     -- Removing Serial Number(s) and Unmarking them
     for rec in wdd loop
     --{
         if rec.serial_number is not null then
            update mtl_serial_numbers
            set    group_mark_id = null,
                   line_mark_id = null,
                   lot_line_mark_id = null
            where  inventory_item_id = rec.inventory_item_id
            and    serial_number  between rec.serial_number and NVL(rec.to_serial_number, rec.serial_number);
         elsif rec.transaction_temp_id is not null then
         --{
            for msnt_rec in msnt(rec.transaction_temp_id) loop
                update mtl_serial_numbers
                set    group_mark_id = null,
                       line_mark_id = null,
                       lot_line_mark_id = null
                where  inventory_item_id = rec.inventory_item_id
                and    serial_number  between msnt_rec.fm_serial_number and NVL(msnt_rec.to_serial_number, msnt_rec.fm_serial_number);
            end loop;
            delete from mtl_serial_numbers_temp
            where  transaction_temp_id = rec.transaction_temp_id;
            begin
            --{
              l_cursor := dbms_sql.open_cursor;
              l_stmt   := 'select fm_serial_number, to_serial_number '||
                          'from   wsh_serial_numbers '||
                          'where  delivery_detail_id = :delivery_detail_id ';
              dbms_sql.parse(l_cursor, l_stmt, dbms_sql.v7);
              dbms_sql.define_column(l_cursor, 1, l_fm_serial, 1);
              dbms_sql.define_column(l_cursor, 2, l_to_serial, 1);
              dbms_sql.bind_variable(l_cursor, ':delivery_detail_id', rec.delivery_detail_id);
              l_ignore := dbms_sql.execute(l_cursor);
              loop
                if dbms_sql.fetch_rows(l_cursor) > 0 then
                   dbms_sql.column_value(l_cursor, 1, l_fm_serial);
                   dbms_sql.column_value(l_cursor, 2, l_to_serial);
                   l_up_cursor := dbms_sql.open_cursor;
                   l_up_stmt   := 'update mtl_serial_numbers msn '||
                                  'set    msn.group_mark_id    = null,  '||
                                  '       msn.line_mark_id     = null,  '||
                                  '       msn.lot_line_mark_id = null   '||
                                  'where  msn.inventory_item_id = :inventory_item_id '||
                                  'and    msn.serial_number between :fm_serial and :to_serial ';
                   dbms_sql.parse(l_up_cursor, l_up_stmt, dbms_sql.v7);
                   dbms_sql.bind_variable(l_up_cursor, ':inventory_item_id', rec.inventory_item_id);
                   dbms_sql.bind_variable(l_up_cursor, ':fm_serial', l_fm_serial);
                   dbms_sql.bind_variable(l_up_cursor, ':to_serial', NVL(l_to_serial, l_fm_serial));
                   l_ignore := dbms_sql.execute(l_up_cursor);
                   dbms_sql.close_cursor(l_up_cursor);
                else
                  exit;
                end if;
              end loop;
              dbms_sql.close_cursor(l_cursor);
              l_cursor := dbms_sql.open_cursor;
              l_stmt   := 'delete from wsh_serial_numbers '||
                          'where delivery_detail_id = :delivery_detail_id ';
              dbms_sql.parse(l_cursor, l_stmt, dbms_sql.v7);
              dbms_sql.bind_variable(l_cursor, ':delivery_detail_id', rec.delivery_detail_id);
              l_ignore := dbms_sql.execute(l_cursor);
              dbms_sql.close_cursor(l_cursor);
            exception
              when others then
                if dbms_sql.is_open(l_up_cursor) then
                   dbms_sql.close_cursor(l_up_cursor);
                end if;
                if dbms_sql.is_open(l_cursor) then
                   dbms_sql.close_cursor(l_cursor);
                end if;
            --}
            end;
         --}
         end if;
     --}
     end loop;
  --}
  else
     --{
     -- OPM Org 
     update ic_txn_request_lines 
     set    line_status = 9
     where  line_id in ( select move_order_line_id
                         from   wsh_delivery_details 
                         where  source_line_id  = l_lin_id
                         and    released_status = 'S'
                         and    source_code     = 'OE' );
                    
     update ic_tran_pnd
     set    delete_mark   = 1
     where  line_id       = l_lin_id
     and    doc_type      = 'OMSO'
     and    trans_qty     < 0
     and    delete_mark   = 0
     and    completed_ind = 0;
     --}
  end if;

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
  where source_line_id   = l_lin_id
  and   source_code      = 'OE'
  and   released_status  <> 'D'
  and   exists  
       (select 'x'
        from   oe_order_lines_all oel
        where  source_line_id       = oel.line_id
        and    oel.cancelled_flag   = 'Y');

  Exception
    when Line_Cannot_Be_Updated then
      rollback;
      dbms_output.put_line('Line is not cancelled');
      dbms_output.put_line('Script cannot cancel the details for this Order Line, as order line is not in eligible state');
    when others then
      rollback;
      dbms_output.put_line(substr(sqlerrm, 1, 240));

Commit;
end;
/
spool off;


