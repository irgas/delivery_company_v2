CREATE OR REPLACE PACKAGE pkg_delivery_company 
IS

TYPE words IS TABLE OF VARCHAR2(200 CHAR) index by binary_integer;

--function that encrypts the password    
    FUNCTION f_get_encrypt_password (
        pv_login      IN VARCHAR2,
        pv_password   IN VARCHAR2
    ) RETURN VARCHAR2;
--function that checks the user's identity    
    FUNCTION f_authentication (
        p_username   IN VARCHAR2,
        p_password IN OUT VARCHAR2
    ) RETURN BOOLEAN;
--procedure that add new client
    PROCEDURE p_add_client (
        pv_login          IN VARCHAR2,
        pv_password_io IN OUT VARCHAR2,
        pv_company_name   IN VARCHAR2,
        pv_nip_pesel      IN VARCHAR2,
        pv_last_name      IN VARCHAR2,
        pv_first_name     IN VARCHAR2,
        pv_country        IN VARCHAR2,
        pv_city           IN VARCHAR2,
        pv_postal_code    IN VARCHAR2,
        pv_street         IN VARCHAR2,
        pv_building_nr    IN VARCHAR2,
        pv_apartment_nr   IN VARCHAR2,
        pv_phone          IN VARCHAR2,
        pv_email          IN VARCHAR2
    );
--procedure that creating new delivery
    PROCEDURE p_creating_delivery (
        pv_sender_company_name      IN VARCHAR2,
        pv_sender_nip_pesel         IN VARCHAR2,
        pv_sender_last_name         IN VARCHAR2,
        pv_sender_first_name        IN VARCHAR2,
        pv_sender_country           IN VARCHAR2,
        pv_sender_city              IN VARCHAR2,
        pv_sender_postal_code       IN VARCHAR2,
        pv_sender_street            IN VARCHAR2,
        pv_sender_building_nr       IN VARCHAR2,
        pv_sender_apartment_nr      IN VARCHAR2,
        pv_sender_phone             IN VARCHAR2,
        pv_sender_email             IN VARCHAR2,
        pv_recipient_company_name   IN VARCHAR2,
        pv_recipient_nip_pesel      IN VARCHAR2,
        pv_recipient_last_name      IN VARCHAR2,
        pv_recipient_first_name     IN VARCHAR2,
        pv_recipient_country        IN VARCHAR2,
        pv_recipient_city           IN VARCHAR2,
        pv_recipient_postal_code    IN VARCHAR2,
        pv_recipient_street         IN VARCHAR2,
        pv_recipient_building_nr    IN VARCHAR2,
        pv_recipient_apartment_nr   IN VARCHAR2,
        pv_recipient_phone          IN VARCHAR2,
        pv_recipient_email          IN VARCHAR2,
        pv_payment_way              IN VARCHAR2,
        pv_payer_company_name       IN VARCHAR2,
        pv_payer_nip_pesel          IN VARCHAR2,
        pv_payer_last_name          IN VARCHAR2,
        pv_payer_first_name         IN VARCHAR2,
        pv_payer_country            IN VARCHAR2,
        pv_payer_city               IN VARCHAR2,
        pv_payer_postal_code        IN VARCHAR2,
        pv_payer_street             IN VARCHAR2,
        pv_payer_building_nr        IN VARCHAR2,
        pv_payer_apartment_nr       IN VARCHAR2,
        pv_payer_phone              IN VARCHAR2,
        pv_payer_email              IN VARCHAR2,
        pv_payer_bank_account_nr    IN VARCHAR2,
        pn_delivery_cost            IN NUMBER,
        pv_delivery_content         IN VARCHAR2,
        pv_delivery_comments        IN VARCHAR2
    );

--function that generate delivery number
    FUNCTION f_get_delivery_number RETURN VARCHAR2;
    
--function that draws kilometers for the delivery
    FUNCTION f_get_distance RETURN NUMBER;
    
--function that returns station
    FUNCTION f_get_station RETURN VARCHAR2;

--function that divide text and it get table with words
    FUNCTION f_divide_text(pv_text IN VARCHAR2) RETURN words;
    
--procedure that account verification 
    PROCEDURE p_account_verification(pv_login IN VARCHAR2,pv_link IN VARCHAR2);
--procedure that makes create task and create report
PROCEDURE p_creating_report_pdf(
    pv_delivery_nr          IN      VARCHAR2,
    pv_template_name        IN      VARCHAR2,
    pv_template_path        IN      VARCHAR2, 
    pv_report_path          IN      VARCHAR2,
    pv_host                 IN      VARCHAR2,                                       
    pn_port                 IN      NUMBER,                                       
    pv_jasper_login         IN      VARCHAR2,
    pv_jasper_password      IN      VARCHAR2
    );

PROCEDURE p_get_report(
  pv_file_name          IN VARCHAR2,
  pv_folder_path        IN VARCHAR2,
  pv_hostname           IN VARCHAR2, 
  pn_port               IN NUMBER, 
  pv_username           IN VARCHAR2, 
  pv_password           IN VARCHAR2
  );
  
END pkg_delivery_company;
/

CREATE OR REPLACE PACKAGE BODY pkg_delivery_company AS

--function that encrypts the password
    FUNCTION f_get_encrypt_password (
        pv_login      IN VARCHAR2,
        pv_password   IN VARCHAR2
    ) RETURN VARCHAR2 AS
        v_string   VARCHAR2(40 CHAR) := 'super secret password';
    BEGIN
        RETURN dbms_crypto.hash(utl_raw.cast_to_raw(pv_login||v_string||pv_password),dbms_crypto.hash_sh1);
    END;

--function that checks the user's identity
    FUNCTION f_authentication (
        p_username   IN VARCHAR2,
        p_password IN OUT VARCHAR2
    )RETURN BOOLEAN 
    AS

        v_verified   clients.verified%TYPE;
        v_blocked    clients.blocked%TYPE;
        v_password   clients.PASSWORD%TYPE;
        
    BEGIN
    
        p_password   := f_get_encrypt_password(pv_login => upper(p_username),pv_password => p_password);

        SELECT verified,blocked,password
            INTO v_verified,v_blocked,v_password
        FROM clients
            WHERE upper(login) LIKE upper(p_username);

        IF upper(p_password) != upper(v_password) THEN
            
            apex_util.set_session_state('LOGIN_ERROR','Podane has�o jest niepoprawne!');
            
            RETURN FALSE;
            
        END IF;

        IF v_verified = 'N' THEN
        
            apex_util.set_session_state('LOGIN_ERROR','Twoje konto nie zosta�o jeszcze zweryfikowane.');
        
            RETURN false;
        
        END IF;

        IF v_blocked = 'Y' THEN
        
            apex_util.set_session_state('LOGIN_ERROR','Twoje konto jest zablokowane!');
        
            RETURN false;
        
        END IF;

        RETURN TRUE;
        
    EXCEPTION
    
        WHEN no_data_found THEN
        
            apex_util.set_session_state('LOGIN_ERROR','U�ytkownik nie istnieje!');
           
            RETURN FALSE;
            
    END f_authentication;

--procedure that add new client
    PROCEDURE p_add_client (
        pv_login          IN VARCHAR2,
        pv_password_io IN OUT VARCHAR2,
        pv_company_name   IN VARCHAR2,
        pv_nip_pesel      IN VARCHAR2,
        pv_last_name      IN VARCHAR2,
        pv_first_name     IN VARCHAR2,
        pv_country        IN VARCHAR2,
        pv_city           IN VARCHAR2,
        pv_postal_code    IN VARCHAR2,
        pv_street         IN VARCHAR2,
        pv_building_nr    IN VARCHAR2,
        pv_apartment_nr   IN VARCHAR2,
        pv_phone          IN VARCHAR2,
        pv_email          IN VARCHAR2
    )
    IS
        v_link VARCHAR2(40);
        
    BEGIN
    
        pv_password_io   := f_get_encrypt_password(pv_login => UPPER(pv_login),pv_password => pv_password_io);

        INSERT INTO clients 
        (nr,login,password,company_name,nip_pesel,last_name,first_name,country,city,postal_code,street,building_nr,apartment_nr,phone,email,verified,blocked)
        VALUES 
        (seq_clients.NEXTVAL,pv_login,pv_password_io,pv_company_name,pv_nip_pesel,pv_last_name,pv_first_name,pv_country,pv_city,pv_postal_code,pv_street,pv_building_nr,pv_apartment_nr,pv_phone,pv_email,'N','N');

--generating a verification link and setting the element of the verification link in the application       
        SELECT f_get_encrypt_password(pv_login,dbms_random.STRING('A',10))
            INTO v_link
                FROM dual;
            
        INSERT INTO verifications(login,LINK)
            VALUES(pv_login,v_link);
            
        apex_util.set_session_state('VERIFICATION_LINK',v_link);
        
        COMMIT;
        
    EXCEPTION
    
        WHEN OTHERS THEN
        
            ROLLBACK;
            
    END p_add_client;
    
--procedure that creating new delivery
    PROCEDURE p_creating_delivery (
        pv_sender_company_name      IN VARCHAR2,
        pv_sender_nip_pesel         IN VARCHAR2,
        pv_sender_last_name         IN VARCHAR2,
        pv_sender_first_name        IN VARCHAR2,
        pv_sender_country           IN VARCHAR2,
        pv_sender_city              IN VARCHAR2,
        pv_sender_postal_code       IN VARCHAR2,
        pv_sender_street            IN VARCHAR2,
        pv_sender_building_nr       IN VARCHAR2,
        pv_sender_apartment_nr      IN VARCHAR2,
        pv_sender_phone             IN VARCHAR2,
        pv_sender_email             IN VARCHAR2,
        pv_recipient_company_name   IN VARCHAR2,
        pv_recipient_nip_pesel      IN VARCHAR2,
        pv_recipient_last_name      IN VARCHAR2,
        pv_recipient_first_name     IN VARCHAR2,
        pv_recipient_country        IN VARCHAR2,
        pv_recipient_city           IN VARCHAR2,
        pv_recipient_postal_code    IN VARCHAR2,
        pv_recipient_street         IN VARCHAR2,
        pv_recipient_building_nr    IN VARCHAR2,
        pv_recipient_apartment_nr   IN VARCHAR2,
        pv_recipient_phone          IN VARCHAR2,
        pv_recipient_email          IN VARCHAR2,
        pv_payment_way              IN VARCHAR2,
        pv_payer_company_name       IN VARCHAR2,
        pv_payer_nip_pesel          IN VARCHAR2,
        pv_payer_last_name          IN VARCHAR2,
        pv_payer_first_name         IN VARCHAR2,
        pv_payer_country            IN VARCHAR2,
        pv_payer_city               IN VARCHAR2,
        pv_payer_postal_code        IN VARCHAR2,
        pv_payer_street             IN VARCHAR2,
        pv_payer_building_nr        IN VARCHAR2,
        pv_payer_apartment_nr       IN VARCHAR2,
        pv_payer_phone              IN VARCHAR2,
        pv_payer_email              IN VARCHAR2,
        pv_payer_bank_account_nr    IN VARCHAR2,
        pn_delivery_cost            IN NUMBER,
        pv_delivery_content         IN VARCHAR2,
        pv_delivery_comments        IN VARCHAR2
    ) 
    IS

        v_delivery_nr   delivery.nr%TYPE;
        n_distance      delivery.distance%TYPE;
        v_station       stations.code%TYPE;
        n_exist         NUMBER;
        
        CURSOR cur_delivery_details 
        IS 
        SELECT c001,n001,n002,n003
            FROM apex_collections
                WHERE collection_name = 'PARCELS';

    BEGIN
        
        v_delivery_nr   := f_get_delivery_number;
        n_distance      := f_get_distance;
        
        SELECT COUNT(*)
            INTO n_exist
                FROM payers
                    WHERE nip_pesel = pv_payer_nip_pesel;
        
        IF n_exist = 0 THEN
        
        INSERT INTO payers 
        (company_name,nip_pesel,last_name,first_name,country,city,postal_code,street,building_nr,apartment_nr,phone,email,payer_bank_account_nr) 
        VALUES 
        (pv_payer_company_name,pv_payer_nip_pesel,pv_payer_last_name,pv_payer_first_name,pv_payer_country,pv_payer_city,pv_payer_postal_code,pv_payer_street,pv_payer_building_nr,pv_payer_apartment_nr,pv_payer_phone,pv_payer_email,pv_payer_bank_account_nr);
        
        END IF;
        
        INSERT INTO delivery 
        (nr,COST,CONTENT,comments,distance,payment_way,payment_status,
        sender_company_name,sender_nip_pesel,sender_last_name,sender_first_name,sender_country,sender_city,sender_postal_code,sender_street,sender_building_nr,sender_apartment_nr,sender_phone,sender_email,
        recipient_company_name,recipient_nip_pesel,recipient_last_name,recipient_first_name,recipient_country,recipient_city,recipient_postal_code,recipient_street,recipient_building_nr,recipient_apartment_nr,recipient_phone,recipient_email,
        payer_nip_pesel,transport_company_nip_pesel) 
        VALUES 
        (v_delivery_nr,pn_delivery_cost,pv_delivery_content,pv_delivery_comments,n_distance,pv_payment_way,'NIEZAP�ACONA',
        pv_sender_company_name,pv_sender_nip_pesel,pv_sender_last_name,pv_sender_first_name,pv_sender_country,pv_sender_city,pv_sender_postal_code,pv_sender_street,pv_sender_building_nr,pv_sender_apartment_nr,pv_sender_phone,pv_sender_email,
        pv_recipient_company_name,pv_recipient_nip_pesel,pv_recipient_last_name,pv_recipient_first_name,pv_recipient_country,pv_recipient_city,pv_recipient_postal_code,pv_recipient_street,pv_recipient_building_nr,pv_recipient_apartment_nr,pv_recipient_phone,pv_recipient_email,
        pv_payer_nip_pesel,'1118989321');
        

        FOR I IN cur_delivery_details LOOP
            
            INSERT INTO delivery_details 
            (delivery_nr,parcel_code,parcel_count,parcel_price,value)
            VALUES 
            (v_delivery_nr,i.c001,i.n001,i.n002,i.n003);

        END LOOP;

        v_station       := f_get_station;
        
        INSERT INTO statues 
        (date_time,delivery_nr,station_code,DESCRIPTION) 
        VALUES 
        (SYSDATE,v_delivery_nr,v_station,'Przesy�ka nadana. Czeka na odbi�r kuriera.');


        p_creating_report_pdf(v_delivery_nr,'parcel','/reports/Delivery_Company/','/delivery_history','localhost',8051,'jasperadmin','jasperadmin');
        
        COMMIT;
        
    EXCEPTION
    
        WHEN OTHERS THEN

            ROLLBACK;
            raise_application_error(-20001,'Wyst�pi� b��d serwera. Spr�buj ponownie.');
            
    END p_creating_delivery;
   
--function that generate delivery number
    FUNCTION f_get_delivery_number RETURN VARCHAR2 IS
        v_delivery_nr   delivery.nr%TYPE;
    BEGIN
        SELECT 'P'|| lpad(seq_delivery_nr.NEXTVAL,6,'0')|| '/'|| to_char(sysdate,'MM/YYYY')
            INTO v_delivery_nr
        FROM dual;

        RETURN v_delivery_nr;
        
    END f_get_delivery_number;
    
--function that returns kilometers for the delivery
    FUNCTION f_get_distance 
    RETURN NUMBER 
    IS
    
        n_distance   delivery.distance%TYPE;
        
    BEGIN
    
        SELECT trunc(dbms_random.value(1,300) )
            INTO n_distance
        FROM dual;

        RETURN n_distance;
        
    END f_get_distance;
    
--function that returns station
    FUNCTION f_get_station 
    RETURN VARCHAR2 
    IS
    
        v_station   stations.code%TYPE;
        
    BEGIN
        SELECT code
            INTO v_station
        FROM (SELECT code,dbms_random.random
                    FROM stations
                        ORDER BY 2)
        FETCH FIRST 1 ROW ONLY;

        RETURN v_station;
        
    END f_get_station;

--function that divide text and it get table with words
FUNCTION f_divide_text(pv_text IN VARCHAR2)
RETURN words 
IS 
    tab_words words;

    n_p NUMBER := 1; --p like position
    n_i NUMBER := 1; --i like index

BEGIN
    
    FOR j IN 1..LENGTH(pv_text) LOOP
            
        CASE substr(pv_text,j,1)
            WHEN ' ' THEN
            tab_words(n_i) := substr(pv_text,n_p,j-n_p);
            n_p := j+1;
            n_i := n_i+1;
            WHEN ',' THEN
            tab_words(n_i) := substr(pv_text,n_p,j-n_p);
            n_p := j+1;
            n_i := n_i+1;
            when '/' then
            tab_words(n_i) := substr(pv_text,n_p,j-n_p);
            n_p := j+1;
            n_i := n_i+1;
            ELSE
            null;
        END CASE;
            
      END LOOP;

    RETURN tab_words;
    
END f_divide_text;

PROCEDURE p_account_verification(pv_login IN VARCHAR2,pv_link IN VARCHAR2)
AS
    n_exist NUMBER;
BEGIN

    SELECT 1
        INTO n_exist
        FROM verifications
            WHERE login = pv_login AND LINK = pv_link;
    
    UPDATE clients
        SET verified = 'Y'
            WHERE login = pv_login; 
            
    apex_util.set_session_state('LOGIN_ERROR','Konto zosta�o zweryfikowane.');
    
    DELETE FROM verifications
            WHERE login = pv_login AND LINK = pv_link;
    
    COMMIT;
    
EXCEPTION
    WHEN OTHERS THEN
    apex_util.set_session_state('LOGIN_ERROR',
    'Konto zosta�o nie zweryfikowane. Spr�buj ponownie lub skontaktuj si� z administratorem.');
    
END p_account_verification;

PROCEDURE p_creating_report_pdf(
    pv_delivery_nr          IN      VARCHAR2,
    pv_template_name        IN      VARCHAR2,
    pv_template_path        IN      VARCHAR2, 
    pv_report_path          IN      VARCHAR2,
    pv_host                 IN      VARCHAR2,                                       
    pn_port                 IN      NUMBER,                                       
    pv_jasper_login         IN      VARCHAR2,
    pv_jasper_password      IN      VARCHAR2
    )
    as
    d_data                 TIMESTAMP := sysdate;
    l_clob              CLOB;
    v_task_settings     CLOB :=    '{
    "label": "Zdalny proces",
    "creationDate": "'||to_char(d_data,'yyyy-MM-dd')||'T'||to_char(d_data,'HH24:mm:ss')||'",
    "trigger": {
        "simpleTrigger": {
            "timezone": "Europe/Belgrade",
            "startType": 1,
            "occurrenceCount": 1
        }
    },
    "baseOutputFilename": "'||lower(pv_template_name)||'-'||substr(pv_delivery_nr,1,7)||substr(pv_delivery_nr,9,2)||substr(pv_delivery_nr,12,4)||'",
    "source": {
        "reportUnitURI": "'||pv_template_path||lower(pv_template_name)||'",
        "parameters": {
            "parameterValues": {
                "delivery_nr": [
                    "'||pv_delivery_nr||'"
                ]
            }
        }
    },
    "outputFormats": {
        "outputFormat": [
            "PDF"
        ]
    },
    "repositoryDestination": {
        "folderURI": "'||pv_report_path||'",
        "sequentialFilenames": false,
        "timestampPattern": "yyyyMMddHHmm",
        "saveToRepository": true
    }
}';
    
    v_link clob := 'http://'||pv_host||':'||pn_port||'/jasperserver/rest_v2/jobs';
BEGIN

    apex_web_service.g_request_headers (1) .name := 'Content-Type'; 
    apex_web_service.g_request_headers (1) .value := 'application/job+json';
     
     l_clob := apex_web_service.make_rest_request(
        p_url => v_link,
        p_http_method => 'PUT',
        p_username => pv_jasper_login,
        p_password => pv_jasper_password,
        p_body => v_task_settings
        );

--    if apex_web_service.g_status_code = '200' then
--        DBMS_OUTPUT.PUT_LINE('Zadanie wykonane.');
--    ELSE
--        DBMS_OUTPUT.PUT_LINE('B��d');
--    END IF;
END p_creating_report_pdf;

PROCEDURE p_get_report(
  pv_file_name          IN VARCHAR2,
  pv_folder_path        IN VARCHAR2,
  pv_hostname           IN VARCHAR2, 
  pn_port               IN NUMBER, 
  pv_username           IN VARCHAR2, 
  pv_password           IN VARCHAR2
  )
  AS
  
  v_blob                 BLOB;
  v_vcContentDisposition VARCHAR2 (25)  := 'inline';



  v_jasper_string VARCHAR2(30) := pv_username || ';' || pv_password;

  v_login_url  VARCHAR2(100) := 
    'http://' || pv_hostname || ':' || pn_port || '/jasperserver/rest/login';

  v_report_url VARCHAR2(100) := 
    'http://' || pv_hostname || ':' || pn_port || '/jasperserver/rest_v2/resources/'||pv_folder_path||'/'||pv_file_name||'.pdf';
BEGIN

  -- log into jasper server
  v_blob := apex_web_service.make_rest_request_b(
    p_url => v_login_url,
    p_http_method => 'GET',
    p_parm_name => apex_util.string_to_table('j_username;j_password',';'),
    p_parm_value => apex_util.string_to_table(v_jasper_string,';')
  );

  -- download file
  v_blob := apex_web_service.make_rest_request_b(
    p_url => v_report_url,
    p_http_method => 'GET'
  );

  OWA_UTIL.mime_header ('application/pdf', FALSE);  -- view your pdf file
  OWA_UTIL.MIME_HEADER( 'application/octet', FALSE ); -- download your pdf file
  htp.P('Content-Length: ' || dbms_lob.getlength(v_blob));
  HTP.p('Content-Disposition: ' || v_vcContentDisposition ||'; filename="' || pv_file_name || '"');
  OWA_UTIL.http_header_close;
  WPG_DOCLOAD.DOWNLOAD_FILE(v_blob);

  APEX_APPLICATION.STOP_APEX_ENGINE;

EXCEPTION
  WHEN OTHERS THEN
    RAISE;

END p_get_report;

END pkg_delivery_company;
/