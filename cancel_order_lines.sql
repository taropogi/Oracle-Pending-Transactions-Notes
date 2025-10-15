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
Prompt This script will attempt to update shipping interfaced flag to N, so that we can cancel this line
Prompt
accept order_line_id num prompt 'Enter LINE_ID of the order line: '
Prompt

spool &order_line_id

declare

  l_lin_id            NUMBER := &order_line_id;

begin

  update oe_order_lines_all
  set    shipping_interfaced_flag = 'N'
  ,      last_updated_by         = -1
  ,      last_update_date        = sysdate
  where line_id   = l_lin_id;

Commit;
end;
/
spool off;


