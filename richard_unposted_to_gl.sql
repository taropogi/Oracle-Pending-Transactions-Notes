SELECT
    *
FROM
    ar_adjustments_all
WHERE
    gl_posted_date IS NULL;

-- explanation
-- This query retrieves all records from the AR adjustments table where the GL posted date is null,
-- indicating that these adjustments have not yet been posted to the General Ledger.
-- This is related to error when closing A/R period due to unposted adjustments. 
-- Error shows: APP-AR-11332: You must post all transactions in this period before you close it.