select transaction_header_id, transaction_temp_id, transaction_mode, inventory_item_id, subinventory_code, locator_id, transaction_quantity, transaction_uom, transaction_type_id, transaction_source_id, transaction_source_name, transaction_date, 
    transaction_reference, trx_source_line_id, transfer_subinventory, transfer_to_location, process_flag, error_explanation, pick_slip_number
from mtl_material_transactions_temp
where process_flag = 'E' and organization_id = 121
order by transaction_date