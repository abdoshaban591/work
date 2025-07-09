/* Formatted on 09/07/2025 05:06:30 م (QP5 v5.256.13226.35510) */
--PROCEDURE account_imported_invoices(pin_invoice_id   IN  NUMBER,
--                                      pov_err_message OUT VARCHAR2
--                                      )
--  IS

DECLARE
   pin_invoice_id     NUMBER;
   pov_err_message    VARCHAR2 (4000);

   CURSOR cur_imp_invoices
   IS
      SELECT *
        FROM ap_invoices_all xlpi
       WHERE     xlpi.invoice_id = 255036
             AND ap_invoices_pkg.get_posting_status (xlpi.invoice_id) = 'N';

   -- This condition is to pick invoices which are un accounted

   ln_processed_cnt   NUMBER DEFAULT 0;
   ln_failed_cnt      NUMBER DEFAULT 0;
   lv_error_buf       VARCHAR2 (500);
   ln_retcode         NUMBER;
BEGIN
   FOR rec_imp_inv IN cur_imp_invoices
   LOOP
      BEGIN
      MO_GLOBAL.INIT('SQLAP');
         ln_retcode := NULL;
         lv_error_buf := NULL;

         ap_drilldown_pub_pkg.invoice_online_accounting (
            p_invoice_id         => rec_imp_inv.invoice_id,
            p_accounting_mode    => 'F',
            p_errbuf             => lv_error_buf,
            p_retcode            => ln_retcode,
            p_calling_sequence   =>'text'
            );

         IF ln_retcode = 0
         THEN
            DBMS_OUTPUT.put_line (
               rec_imp_inv.invoice_num || '- Invoice Accounted Sucessfully');
            ln_processed_cnt := ln_processed_cnt + 1;
         ELSIF ln_retcode = 1
         THEN
            DBMS_OUTPUT.put_line (
                  rec_imp_inv.invoice_num
               || '- 1Invoice Accounting ended in WARNING. Errbuf : '
               || lv_error_buf);
            ln_processed_cnt := ln_processed_cnt + 1;
         ELSIF ln_retcode = 2
         THEN
            DBMS_OUTPUT.put_line (
                  rec_imp_inv.invoice_num
               || '- 2Invoice Accounting ended in ERROR. Errbuf : '
               || lv_error_buf);
            ln_failed_cnt := ln_failed_cnt + 1;
         ELSE
            DBMS_OUTPUT.put_line (
                  rec_imp_inv.invoice_num
               || '- 3Invoice Accounting ended in ERROR. Errbuf : '
               || lv_error_buf
               || ' Retcode: '
               || ln_retcode);
            ln_failed_cnt := ln_failed_cnt + 1;
         END IF;

         COMMIT;
      EXCEPTION
         WHEN OTHERS
         THEN
            DBMS_OUTPUT.put_line (
                  rec_imp_inv.invoice_num
               || ' Invoice Validation failed with unhandled exception.Error:'
               || SQLERRM);
            ln_failed_cnt := ln_failed_cnt + 1;
      END;
   END LOOP;

   pov_err_message :=
      'PROCESSED: ' || ln_processed_cnt || ' FAILED: ' || ln_failed_cnt;
END;