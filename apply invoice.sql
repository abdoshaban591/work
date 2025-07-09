DECLARE
  -- Input
  l_invoice_number       VARCHAR2(50) := 'INV123456'; -- Replace with your invoice number

  -- Resolved Data
  l_customer_trx_id      RA_CUSTOMER_TRX_ALL.customer_trx_id%TYPE;
  l_bill_to_customer_id  RA_CUSTOMER_TRX_ALL.bill_to_customer_id%TYPE;
  l_trx_balance          RA_CUSTOMER_TRX_ALL.amount_due_original%TYPE;
  l_cash_receipt_id      AR_CASH_RECEIPTS_ALL.cash_receipt_id%TYPE;

  -- API Output
  l_return_status        VARCHAR2(1);
  l_msg_count            NUMBER;
  l_msg_data             VARCHAR2(2000);

BEGIN
  -- Step 1: Get invoice ID, customer, and balance
  SELECT customer_trx_id,
         bill_to_customer_id,
         NVL(ra.get_customer_trx_balance(customer_trx_id), 0) AS trx_balance
    INTO l_customer_trx_id, l_bill_to_customer_id, l_trx_balance
    FROM ra_customer_trx_all
   WHERE trx_number = l_invoice_number
     AND ROWNUM = 1;

  -- Step 2: Get a valid unapplied receipt with enough balance
  SELECT acr.cash_receipt_id
    INTO l_cash_receipt_id
    FROM ar_cash_receipts_all acr
   WHERE acr.bill_to_customer_id = l_bill_to_customer_id
     AND acr.status = 'APP'
     AND (acr.amount - NVL(acr.amount_applied, 0)) >= l_trx_balance
     AND acr.org_id = (SELECT org_id FROM ra_customer_trx_all WHERE trx_number = l_invoice_number)
     AND ROWNUM = 1;

  -- Step 3: Apply receipt
  AR_RECEIPT_API_PUB.Apply(
    p_api_version         => 1.0,
    p_init_msg_list       => 'T',
    p_commit              => 'T',
    p_validation_level    => 100,
    x_return_status       => l_return_status,
    x_msg_count           => l_msg_count,
    x_msg_data            => l_msg_data,
    p_cash_receipt_id     => l_cash_receipt_id,
    p_customer_trx_id     => l_customer_trx_id,
    p_amount_applied      => l_trx_balance,
    p_apply_date          => SYSDATE,
    p_gl_date             => SYSDATE,
    p_apply_reason_code   => NULL,
    p_apply_comments      => 'Auto-apply full open amount',
    p_application_ref     => NULL
  );

  IF l_return_status = 'S' THEN
    DBMS_OUTPUT.put_line('✅ Applied ' || l_trx_balance || ' from receipt to invoice.');
  ELSE
    DBMS_OUTPUT.put_line('❌ Error applying receipt: ' || l_msg_data);
  END IF;

EXCEPTION
  WHEN NO_DATA_FOUND THEN
    DBMS_OUTPUT.put_line('❌ Invoice or unapplied receipt not found.');
  WHEN OTHERS THEN
    DBMS_OUTPUT.put_line('❌ Unexpected error: ' || SQLERRM);
END;
