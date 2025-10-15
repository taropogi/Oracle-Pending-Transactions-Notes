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
Prompt This script will attempt to delete transactions stuck in rcv_transactions_interface
Prompt
accept interface_txn_id num prompt 'Enter transaction ID: '
Prompt

spool &interface_txn_id

declare

  l_lin_id            NUMBER := &interface_txn_id;

begin

  dbms_output.put_line('Deleting records for the Transaction ID: '||l_lin_id);

  delete rcv_transactions_interface 
    where interface_transaction_id = l_lin_id;
    
  delete rcv_lots_interface 
    where interface_transaction_id = l_lin_id;

  delete mtl_transaction_lots_interface
    where product_transaction_id = l_lin_id;

  delete mtl_transaction_lots_temp
    where product_transaction_id = l_lin_id;

  delete rcv_serials_interface
    where interface_transaction_id = l_lin_id;

  delete mtl_serial_numbers_interface
    where product_transaction_id = l_lin_id;

  delete mtl_serial_numbers_temp
    where product_transaction_id = l_lin_id;
	
Commit;

end;
/

spool off;


