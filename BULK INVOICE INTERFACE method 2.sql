/* Formatted on 22/05/2025 05:55:12 ã (QP5 v5.256.13226.35510) */
DECLARE
   L_VENDOR_ID        NUMBER;
   L_VENDOR_SITE_ID   NUMBER;
   L_AMOUNT           NUMBER;
   v_request_id       NUMBER;
   l_boolean          BOOLEAN;
   l_phase            VARCHAR2 (200);
   l_status           VARCHAR2 (200);
   l_dev_phase        VARCHAR2 (200);
   l_dev_status       VARCHAR2 (200);
   l_message          VARCHAR2 (200);
   V_SEQ              NUMBER:=0;
   V_NUM              NUMBER ;
BEGIN
FOR I IN (
SELECT asa.VENDOR_ID l_vendor_id,
                 asa.PARTY_ID l_party_id,
                 assa.PARTY_SITE_ID l_party_site_id,
                 assa.vendor_site_id l_vendor_site_id,
                 asa.vendor_name,
                 xao.*
            FROM xx_ap_ob_20250415 xao,
                 ap_suppliers asa,
                 AP_SUPPLIER_SITES_ALL assa
           WHERE     1 = 1
                 AND TRIM (asa.vendor_name) = TRIM (xao.SUPPLIER_NAME)
                 AND line_TYPE = 'HEADER'              /* check with ahmed */
                 --                   AND id = 6772
                 AND assa.VENDOR_ID = asa.VENDOR_ID)
LOOP

   INSERT INTO AP_INVOICES_INTERFACE (invoice_id,
                                      invoice_num,
                                      vendor_id,
                                      vendor_site_id,
                                      invoice_amount,
                                      INVOICE_CURRENCY_CODE,
                                      PAYMENT_CURRENCY_CODE,
                                      invoice_date,
                                      DESCRIPTION,
                                      --PAY_GROUP_LOOKUP_CODE,
                                      source,
                                      org_id,
                                      po_NUMBER,
                                      PAYMENT_METHOD_CODE,
                                      exchange_rate,
                                      CALC_TAX_DURING_IMPORT_FLAG
                                      ,ADD_TAX_TO_INV_AMT_FLAG)
        VALUES (ap_invoices_interface_s.NEXTVAL,
                I.INVOICE_NUM ||'+HA20',      --P_PO_NUMBER
                I.l_vendor_id ,--4004,
                I.l_vendor_site_id,--4008,
                I.INVOICE_AMOUNT,                                             --L_AMOUNT,--
                'SAR',--I.INVOICE_CURRENCY_CODE
                'SAR',--I.PAYMENT_CURRENCY_CODE
               I.INVOICE_DATE ,-- TO_DATE ('01/01/2024', 'dd/mm/yyyy'), --fnd_conc_date.string_to_date(P_GL_DATE),
                'Opening Balance',
                -- 'WUFS SUPPLIER',
                'MANUAL INVOICE ENTRY',
                222,
                NULL,
                'CHECK',
                1,
                'N'
                ,'Y');
             V_NUM :=ap_invoices_interface_s.CURRVAL ;
             UPDATE  xx_ap_ob_20250415
             SET INVOICE_ID =ap_invoices_interface_s.CURRVAL 
--                 ,ERROR_STATUS1
             WHERE 1=1
             AND INVOICE_NUM = I.INVOICE_NUM
             AND SUPPLIER_NAME = I.SUPPLIER_NAME
             AND INVOICE_DATE = I.INVOICE_DATE
                                                   ;
                                                   
    V_SEQ :=0;
 FOR Y IN (
           SELECT asa.VENDOR_ID l_vendor_id,
                 asa.PARTY_ID l_party_id,
                 assa.PARTY_SITE_ID l_party_site_id,
                 assa.vendor_site_id l_vendor_site_id,
                 asa.vendor_name,
                 xao.*
            FROM xx_ap_ob_20250415 xao,
                 ap_suppliers asa,
                 AP_SUPPLIER_SITES_ALL assa
           WHERE     1 = 1
           AND  INVOICE_ID =V_NUM
                 AND TRIM (asa.vendor_name) = TRIM (xao.SUPPLIER_NAME)
                 AND line_TYPE IN('ITEM','TAX') --NOT IN  ('HEADER','TAX')              /* check with ahmed */
                 --                   AND id = 6772
                 AND assa.VENDOR_ID = asa.VENDOR_ID)       
     LOOP       
   --=====================================================================--
   V_SEQ:=V_SEQ+1;
       INSERT INTO AP_INVOICE_LINES_INTERFACE (
                                            invoice_id,
                                            invoice_line_id,
                                            line_number,
                                            line_type_lookup_code,
                                            amount,
                                            TAX_CLASSIFICATION_CODE,
                                            DIST_CODE_COMBINATION_ID
                                           ,LINE_GROUP_NUMBER
                                           ,AWT_GROUP_NAME
                                           ,PRORATE_ACROSS_FLAG
                                           ,TAX
                                           ,TAX_STATUS_CODE
                                           ,TAX_RATE_CODE
                                           ,TAX_REGIME_CODE
                                           )
        VALUES (ap_invoices_interface_s.CURRVAL,
                AP_INVOICE_LINES_INTERFACE_S.NEXTVAL,
                V_SEQ,
                Y.LINE_TYPE , --'ITEM',
                Y.INVOICE_AMOUNT ,--100,
                Y.TAX_CODE,--  'RS_15%',
                Y.ACCTS_PAY_ACCOUNT-- 14026
                ,Y.LINE_GROUP_NUMBER   --  ,ap_invoices_interface_s.CURRVAL
                ,Y.AWT_NAME_GROUP
                ,CASE WHEN Y.LINE_TYPE ='TAX' THEN 'Y' ELSE NULL END 
                ,Y.TAX
                ,Y.TAX_STATUS_CODE
                ,Y.TAX_RATE_CODE
                ,Y.TAX_REGIME_CODE
                );
   
        END LOOP ;
       
       
   END LOOP ;

   COMMIT;

   BEGIN
      mo_global.init ('SQLAP');
      MO_GLOBAL.set_policy_context ('S', 222);
      fnd_global.apps_initialize (0,
                                  50764,
                                  200,
                                  0,
                                  0);
      FND_REQUEST.SET_ORG_ID (222);
      v_request_id :=
         fnd_request.submit_request (APPLICATION   => 'SQLAP',
                                     PROGRAM       => 'APXIIMPT',
                                     DESCRIPTION   => '',
                                     START_TIME    => NULL,
                                     SUB_REQUEST   => FALSE,
                                     ARGUMENT1     => 222,
                                     ARGUMENT2     => 'MANUAL INVOICE ENTRY',
                                     ARGUMENT3     => NULL,
                                     ARGUMENT4     => NULL,
                                     ARGUMENT5     => NULL,
                                     ARGUMENT6     => NULL,
                                     ARGUMENT7     => NULL,
                                     ARGUMENT8     => 'N',
                                     ARGUMENT9     => 'Y');
   
      COMMIT;

      IF v_request_id > 0
      THEN
         l_boolean :=
            FND_CONCURRENT.WAIT_FOR_REQUEST (v_request_id --request_id IN number default NULL,
                                                         ,
                                             20 --Interval   IN number default 60, SECONDS
                                               ,
                                             0 --max_wait   IN number default 0,
                                              ,
                                             l_phase --phase      OUT varchar2,
                                                    ,
                                             l_status --status     OUT varchar2,
                                                     ,
                                             l_dev_phase --dev_phase  OUT varchar2,
                                                        ,
                                             l_dev_status --dev_status OUT varchar2,,
                                                         ,
                                             l_message --message    OUT varchar2) return boolean
                                                      );
      END IF;

      fnd_file.put_line (
         fnd_file.LOG,
            'Please see the output of Payables OPEN Invoice Import program request id :'
         || v_request_id);
      DBMS_OUTPUT.put_line ('success');
   EXCEPTION
      WHEN OTHERS
      THEN
         fnd_file.put_line (fnd_file.LOG, 'Error :' || SQLERRM);
         DBMS_OUTPUT.put_line ('Error :' || SQLERRM);
   END;

   fnd_file.put_line (fnd_file.LOG, 'SUCCESS');
EXCEPTION
   WHEN OTHERS
   THEN
      fnd_file.put_line (fnd_file.LOG, 'Error :' || SQLERRM);
      DBMS_OUTPUT.put_line ('Error :' || SQLERRM);
END;