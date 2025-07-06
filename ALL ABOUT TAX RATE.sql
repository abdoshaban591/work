SELECT hou.organization_id,
       hou.set_of_books_id,
       hou.default_legal_context_id,
       hou.short_code,
       hou.NAME,
       zru.first_pty_org_id party_tax_profile_id,
       zru.tax_regime_id,
       zru.tax_regime_code,
       zxr.tax,
       zxr.tax_status_code,
       zxr.tax_rate_code,
       zxr.tax_jurisdiction_code,
       zxr.rate_type_code,
       zxr.recovery_type_code,
       zxr.percentage_rate,
       zxr.tax_rate_id,
       zxr.effective_from,
       zxr.effective_to,
       zxr.active_flag,
       zxr.attribute3,
       zxr.offset_tax,
       zxr.offset_status_code,
       zxr.offset_tax_rate_code
  FROM zx_party_tax_profile      ptp,
       zx_subscription_details   zsd,
       hr_operating_units        hou,    
       zx_regimes_usages         zru,
       zx_rates_vl               zxr
 WHERE zxr.tax_regime_code         = zru.tax_regime_code  
   AND ptp.party_type_code         = 'OU'  
   AND ptp.party_id                = hou.organization_id
   AND zru.first_pty_org_id        = ptp.party_tax_profile_id

   AND zru.first_pty_org_id        = zsd.first_pty_org_id

   AND zsd.tax_regime_code         = ZRU.TAX_REGIME_CODE
   AND zsd.parent_first_pty_org_id = -99
   AND SYSDATE BETWEEN zsd.effective_from AND NVL(zsd.effective_to,SYSDATE);
--Below query is to list down the tax account based on Operating Unit,
SELECT hou.organization_id,
       hou.NAME,
       tax_account_ccid,
       zxr.tax,
       zxr.tax_status_code,
       zxr.tax_regime_code,
       zxr.tax_rate_code,
       zxr.tax_jurisdiction_code,
       zxr.rate_type_code,
       zxr.percentage_rate,
       zxr.tax_rate_id,
       zxr.effective_from,
       zxr.effective_to,
       zxr.active_flag
  FROM zx_rates_vl        zxr,
       zx_accounts        b,
       hr_operating_units hou
 WHERE b.internal_organization_id = hou.organization_id
   AND b.tax_account_entity_code = 'RATES'
   AND b.tax_account_entity_id = zxr.tax_rate_id
   AND zxr.active_flag = 'Y'
   AND SYSDATE BETWEEN zxr.effective_from AND nvl(zxr.effective_to, SYSDATE);


select * from AP_TAX_CODES_ALL