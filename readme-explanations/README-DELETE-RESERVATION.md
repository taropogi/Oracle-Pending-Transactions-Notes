Designed to clean up reservation-related data that's causing pending transaction issues in Oracle's inventory management system.

Purpose:

Removes orphaned or problematic inventory reservations that can cause pending transactions to get stuck in the Oracle inventory system.

How to know if reservation is problematic?

1.If its orphaned. Meaning the referenced line_id is gone. But the reservation still exists.

sample query: other-queries/orphaned-reservations.sql

2.If has unmatched qty demand and reserved.

sample query: other-queries/unmatched-qty-vs-demand.sql
