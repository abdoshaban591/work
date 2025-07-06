---------Validating the AP invoice from backend by submitting concurrent program.
declare
v_request_id number;
        begin
 mo_global.init ('SQLAP');
 MO_GLOBAL.set_policy_context('S',443);
fnd_global.apps_initialize (26015,524410,200,0,0);
 FND_REQUEST.SET_ORG_ID(443);
            v_request_id :=fnd_request.submit_request (APPLICATION        => 'SQLAP',
                                                   PROGRAM            => 'APPRVL',
                                                   DESCRIPTION        => '',
                                                   START_TIME         => NULL,
                                                   SUB_REQUEST        => FALSE,
                                                   ARGUMENT1          => 443,
                                                   ARGUMENT2          =>'All',
                                                   ARGUMENT3          =>null,
                                                   ARGUMENT4          =>TO_CHAR(SYSDATE,'YYYY-MM-DD'),
                                                   ARGUMENT5          =>TO_CHAR(SYSDATE,'YYYY-MM-DD'),
                                                   ARGUMENT6          =>NULL,
                                                   ARGUMENT7          =>NULL,
                                                   ARGUMENT8          =>NULL, --or pass invoice id here remove dates
                                                   ARGUMENT9          =>NULL ,
                                                   ARGUMENT10          =>'N',
                                                   ARGUMENT11          =>1000                                            
                                                   );
        Commit;
dbms_output.put_line(v_request_id);        
end;