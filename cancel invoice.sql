DECLARE
  -- Input: your invoice id here
  v_invoice_id          NUMBER := 259037;

  -- Variables to hold values needed for AP_CANCEL_PKG
  v_last_updated_by            NUMBER;
  v_last_update_login          NUMBER;
  v_accounting_date            DATE;
  v_message_name               VARCHAR2(30) := 'Cancel Invoice';
  v_invoice_amount             NUMBER;
  v_base_amount                NUMBER;
  v_temp_cancelled_amount      NUMBER := 0;
  v_cancelled_by               NUMBER;
  v_cancelled_amount           NUMBER;
  v_cancelled_date             DATE := SYSDATE;
  v_last_update_date           DATE := SYSDATE;
  v_orig_prepay_amt            NUMBER := 0;
  v_pay_cur_inv_amt            NUMBER;
  v_token                      VARCHAR2(100) := NULL;

  v_cancel_return              boolean;
  v_boolean                    boolean ;
  v_error_code                 varchar2(4000);
  v_debug_info                  varchar2(4000);

BEGIN
  -- Fetch invoice amounts and user info
  
  fnd_global.APPS_INITIALIZE(user_id=>0,
 resp_id=>200,
 resp_appl_id=>20639);
 

DBMS_OUTPUT.put_line ('Calling API to check whetehr the Invoice is canellable ' );

v_boolean :=AP_CANCEL_PKG.IS_INVOICE_CANCELLABLE(
                P_invoice_id       => v_invoice_id,
                P_error_code       => v_error_code,   
                P_debug_info       => v_debug_info,
                P_calling_sequence => NULL);

IF v_boolean 
THEN
DBMS_OUTPUT.put_line ('Invoice '||v_invoice_id|| ' is cancellable' );
ELSE
DBMS_OUTPUT.put_line ('Invoice '||v_invoice_id|| ' is not cancellable :'|| v_error_code );
END IF;     

DBMS_OUTPUT.put_line ('Calling API to Cancel Invoice' );
  
  SELECT
    invoice_amount,
    base_amount,
--    pay_currency_invoice_amount,
    last_updated_by,
    last_update_login
  INTO
    v_invoice_amount,
    v_base_amount,
--    v_pay_cur_inv_amt,
    v_last_updated_by,
    v_last_update_login
  FROM
    ap_invoices_all
  WHERE
    invoice_id = v_invoice_id;

  -- Use last_updated_by also as cancelled_by (adjust as needed)
  v_cancelled_by := v_last_updated_by;

  -- Cancel the invoice
  v_cancel_return := AP_CANCEL_PKG.AP_CANCEL_SINGLE_INVOICE(
    p_invoice_id                 => v_invoice_id,
    p_last_updated_by            => v_last_updated_by,
    p_last_update_login          => v_last_update_login,
    p_accounting_date            => to_date('01/04/2024','dd/mm/yyyy'),         -- Or fetch your accounting date logic
    p_message_name               => v_message_name,
    p_invoice_amount             => v_invoice_amount,
    p_base_amount                => v_base_amount,
    p_temp_cancelled_amount      => v_temp_cancelled_amount,
    p_cancelled_by               => v_cancelled_by,
    p_cancelled_amount           => v_invoice_amount, -- Assuming full cancel
    p_cancelled_date             => v_cancelled_date,
    p_last_update_date           => v_last_update_date,
    p_original_prepayment_amount => v_orig_prepay_amt,
    p_pay_curr_invoice_amount    => v_pay_cur_inv_amt,
    P_Token                      => v_token,
    p_calling_sequence           => null
  );
 if v_cancel_return 
 then 
  DBMS_OUTPUT.PUT_LINE('Cancel status:suc ' ||v_message_name);
  else 
  DBMS_OUTPUT.PUT_LINE('Cancel status:fail '|| v_message_name);
  end if;

EXCEPTION
  WHEN NO_DATA_FOUND THEN
    DBMS_OUTPUT.PUT_LINE('Invoice ID ' || v_invoice_id || ' not found.');
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Error occurred: ' || SQLERRM);
END;
