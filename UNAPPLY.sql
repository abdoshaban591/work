DECLARE
  -- Input: Provide the invoice ID (customer_trx_id)
  l_customer_trx_id      RA_CUSTOMER_TRX_ALL.customer_trx_id%TYPE := 123456; -- ← Replace with actual invoice ID

  -- Lookup values
  l_receivable_application_id  AR_RECEIVABLE_APPLICATIONS_ALL.receivable_application_id%TYPE;
  l_cash_receipt_id            AR_CASH_RECEIPTS_ALL.cash_receipt_id%TYPE;
  l_applied_amount             NUMBER;
  l_org_id                     NUMBER;

  -- API Output
  l_return_status              VARCHAR2(1);
  l_msg_count                  NUMBER;
  l_msg_data                   VARCHAR2(2000);

BEGIN
  -- Step 1: Find the receipt application to this invoice
  SELECT receivable_application_id,
         cash_receipt_id,
         applied_amount,
         org_id
    INTO l_receivable_application_id,
         l_cash_receipt_id,
         l_applied_amount,
         l_org_id
    FROM ar_receivable_applications_all
   WHERE customer_trx_id = l_customer_trx_id
     AND status = 'APP'
     AND ROWNUM = 1;

  -- Step 2: Unapply the receipt
  AR_RECEIPT_API_PUB.UNAPPLY(
    p_api_version_number        => 1.0,
    p_init_msg_list             => 'T',
    p_commit                    => 'T',
    p_validation_level          => 100,
    x_return_status             => l_return_status,
    x_msg_count                 => l_msg_count,
    x_msg_data                  => l_msg_data,
    p_receivable_application_id => l_receivable_application_id,
    p_cash_receipt_id           => l_cash_receipt_id,
    p_amount_to_unapply         => l_applied_amount,
    p_unapply_date              => SYSDATE,
    p_gl_date                   => SYSDATE,
    p_unapply_reason_code       => NULL,
    p_comments                  => 'Auto-unapplied by script'
  );

  IF l_return_status = 'S' THEN
    DBMS_OUTPUT.put_line('✅ Receipt unapplied successfully from invoice ID ' || l_customer_trx_id);
  ELSE
    DBMS_OUTPUT.put_line('❌ Error during unapply: ' || l_msg_data);
  END IF;

EXCEPTION
  WHEN NO_DATA_FOUND THEN
    DBMS_OUTPUT.put_line('❌ No applied receipt found for the given invoice.');
  WHEN OTHERS THEN
    DBMS_OUTPUT.put_line('❌ Unexpected error: ' || SQLERRM);
END;
