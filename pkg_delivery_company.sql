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
--procedures that creating new delivery
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
        pv_parcel_code              IN VARCHAR2,
        pv_parcel_name              IN VARCHAR2,
        pn_parcel_count             IN NUMBER,
        pn_parcel_price             IN NUMBER,
        pn_parcel_value             IN NUMBER,
        pv_payment_way              IN VARCHAR2,
        pv_payer_nip_pesel          IN VARCHAR2,
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
            
            apex_util.set_session_state('LOGIN_ERROR','Podane has³o jest niepoprawne!');
            
            RETURN FALSE;
            
        END IF;

        IF v_verified = 'N' THEN
        
            apex_util.set_session_state('LOGIN_ERROR','Twoje konto nie zosta³o jeszcze zweryfikowane.');
        
            RETURN false;
        
        END IF;

        IF v_blocked = 'Y' THEN
        
            apex_util.set_session_state('LOGIN_ERROR','Twoje konto jest zablokowane!');
        
            RETURN false;
        
        END IF;

        RETURN TRUE;
        
    EXCEPTION
    
        WHEN no_data_found THEN
        
            apex_util.set_session_state('LOGIN_ERROR','U¿ytkownik nie istnieje!');
           
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
    BEGIN
    
        pv_password_io   := f_get_encrypt_password(pv_login => UPPER(pv_login),pv_password => pv_password_io);

        INSERT INTO clients 
        (nr,login,password,company_name,nip_pesel,last_name,first_name,country,city,postal_code,street,building_nr,apartment_nr,phone,email,verified,blocked)
        VALUES 
        (seq_clients.NEXTVAL,pv_login,pv_password_io,pv_company_name,pv_nip_pesel,pv_last_name,pv_first_name,pv_country,pv_city,pv_postal_code,pv_street,pv_building_nr,pv_apartment_nr,pv_phone,pv_email,'N','N');

        COMMIT;
        
    EXCEPTION
    
        WHEN OTHERS THEN
        
            ROLLBACK;
            
    END p_add_client;
    
--procedures that creating new delivery
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
        
        CURSOR cur_delivery_details 
        IS 
        SELECT c001,n001,n002,n003
            FROM apex_collections
                WHERE collection_name = 'PARCELS';

    BEGIN
        
        v_delivery_nr   := f_get_delivery_number;
        n_distance      := f_get_distance;
        
        INSERT INTO payers 
        (company_name,nip_pesel,last_name,first_name,country,city,postal_code,street,building_nr,apartment_nr,phone,email,payer_bank_account_nr) 
        VALUES 
        (pv_payer_company_name,pv_payer_nip_pesel,pv_payer_last_name,pv_payer_first_name,pv_payer_country,pv_payer_city,pv_payer_postal_code,pv_payer_street,pv_payer_building_nr,pv_payer_apartment_nr,pv_payer_phone,pv_payer_email,pv_payer_bank_account_nr);

        INSERT INTO delivery 
        (nr,COST,CONTENT,comments,distance,payment_way,payment_status,
        sender_company_name,sender_nip_pesel,sender_last_name,sender_first_name,sender_country,sender_city,sender_postal_code,sender_street,sender_building_nr,sender_apartment_nr,sender_phone,sender_email,
        recipient_company_name,recipient_nip_pesel,recipient_last_name,recipient_first_name,recipient_country,recipient_city,recipient_postal_code,recipient_street,recipient_building_nr,recipient_apartment_nr,recipient_phone,recipient_email,
        payer_nip_pesel,transport_company_nip_pesel) 
        VALUES 
        (v_delivery_nr,pn_delivery_cost,pv_delivery_content,pv_delivery_comments,n_distance,pv_payment_way,'NIEZAP£ACONA',
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
        (TO_CHAR(SYSDATE,'YY/MM/DD HH24:MM:SS'),v_delivery_nr,v_station,'Przesy³ka nadana. Czeka na odbiór kuriera.');

        COMMIT;
        
    EXCEPTION
    
        WHEN OTHERS THEN
            
            ROLLBACK;
--            raise_application_error(-20001,'Wyst¹pi³ b³¹d serwera. Spróbuj ponownie.');
            
    END p_creating_delivery;

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
        pv_parcel_code              IN VARCHAR2,
        pv_parcel_name              IN VARCHAR2,
        pn_parcel_count             IN NUMBER,
        pn_parcel_price             IN NUMBER,
        pn_parcel_value             IN NUMBER,
        pv_payment_way              IN VARCHAR2,
        pv_payer_nip_pesel          IN VARCHAR2,
        pn_delivery_cost            IN NUMBER,
        pv_delivery_content         IN VARCHAR2,
        pv_delivery_comments        IN VARCHAR2
    )
    IS
    BEGIN
        NULL;
    EXCEPTION
        WHEN OTHERS THEN
            raise_application_error(-20001,'blad');
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
            n_p := LENGTH(substr(pv_text,n_p,j+1));
            n_i := n_i+1;
            WHEN ',' THEN
            tab_words(n_i) := substr(pv_text,n_p,j-n_p);
            n_p := LENGTH(substr(pv_text,n_p,j+1));
            n_i := n_i+1;
            when '/' then
            tab_words(n_i) := substr(pv_text,n_p,j-n_p);
            n_p := LENGTH(substr(pv_text,n_p,j+1));
            n_i := n_i+1;
            ELSE
            null;
        END CASE;
            
      END LOOP;

    RETURN tab_words;
    
END f_divide_text;

END pkg_delivery_company;
/