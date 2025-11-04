SET VERIFY OFF;
WHENEVER OSERROR EXIT FAILURE ROLLBACK;
WHENEVER SQLERROR EXIT FAILURE ROLLBACK;

clear buffer;
set serveroutput on size 500000
rem set feed off
set pagesize 1000
set linesize 120
set underline '-'

PROMPT ** This gets rid reservations that you want to delete 
PROMPT
accept order_line_id num prompt 'Enter LINE_ID of the order line: '
PROMPT

spool &order_line_id

declare

  l_lin_id            NUMBER := &order_line_id;

begin

DELETE FROM MTL_RESERVATIONS WHERE
       DEMAND_SOURCE_LINE_ID = l_lin_id;

DELETE FROM MTL_DEMAND WHERE
    DEMAND_SOURCE_TYPE IN (2,8) -- 2= Sales Order, 8= Internal Sales Order
AND RESERVATION_TYPE=2      -- 2 means sales order reservation, please verify in your system
AND DEMAND_SOURCE_LINE = l_lin_id;

COMMIT;
end;
/
spool off;
