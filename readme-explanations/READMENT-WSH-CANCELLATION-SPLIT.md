# Purpose

This script is used to **manually cancel a specific delivery detail** in Oracle E-Business Suite’s Shipping Execution (WSH) module. It is especially useful for cases where an order line has been split into multiple shipment lines (e.g., 1.1, 1.2, 1.3), and you need to cancel only one of those split lines.

# What the Script Does

## Prompts for Input

- Asks the user to enter a **DELIVERY DETAIL ID** (not an order line ID, despite the variable name).

## Updates Delivery Assignments

- Sets `delivery_id` and `parent_delivery_detail_id` to `NULL` in `wsh_delivery_assignments` for the given delivery detail.
- Updates audit columns (`last_updated_by`, `last_update_date`).

## Updates Delivery Details

- Sets the delivery detail’s `released_status` to `'D'` (cancelled).
- Sets all quantity fields (requested, shipped, picked, etc.) to zero.
- Sets flags (`inv_interfaced_flag`, `oe_interfaced_flag`) to `'X'` (typically meaning "not interfaced").
- Clears subinventory, locator, lot/serial numbers, and other related fields.
- Only updates if the source is Order Entry (`source_code = 'OE'`) and the line is not already cancelled.

## Commits the Changes

- Saves the updates to the database.

## Spools Output

- Saves the output to a file named after the entered delivery detail ID.

# When to Use

- When a delivery detail (including split lines like 1.1, 1.2, 1.3) is stuck in a pending state due to a cancelled order line.
- When automated cancellation or cleanup processes have failed.
- As a support/maintenance tool for data correction in Oracle EBS Shipping.
- When you need to cancel **only a specific split shipment line** without affecting other splits or the entire order line.

# In Summary

This script is a corrective tool to manually cancel and clean up **individual delivery details** in Oracle EBS Shipping, ensuring that stuck or pending shipment lines (including split lines) are properly marked as cancelled and do not interfere with further processing.
