SELECT
    transaction_id,
    inventory_item_id,
    subinventory_code,
    transaction_type_id,
    transaction_source_id,
    transaction_quantity,
    transaction_uom,
    transaction_date,
    transaction_reference,
    invoiced_flag,
    trx_source_line_id,
    source_line_id,
    transfer_subinventory
FROM
    mtl_material_transactions
WHERE
    costed_flag = 'N'
    AND organization_id = 121
ORDER BY
    transaction_date;