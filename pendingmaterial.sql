select
    transaction_header_id,
    source_line_id,
    source_header_id,
    inventory_item_id,
    transaction_quantity,
    transaction_uom,
    subinventory_code,
    transaction_source_id,
    transaction_type_id,
    transaction_reference,
    trx_source_line_id,
    ship_to_location_id,
    transfer_subinventory,
    error_explanation
from
    mtl_transactions_interface
where
    process_flag = 3
order by
    transaction_date