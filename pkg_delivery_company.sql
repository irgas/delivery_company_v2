--------------------------------------------------------
--  DDL for Package PKG_DELIVERY_COMPANY
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE PKG_DELIVERY_COMPANY 
IS
--function that encrypts the password    
    FUNCTION f_get_encrypt_password(pv_login IN VARCHAR2, pv_password IN VARCHAR2) RETURN VARCHAR2;
--functions that checks the user's identity    
    FUNCTION f_authentication(p_username IN VARCHAR2, p_password IN OUT VARCHAR2) RETURN BOOLEAN;
--procedure that add new client
    PROCEDURE p_add_client(pv_login IN VARCHAR2, 
    pv_password_io IN OUT VARCHAR2, 
    pv_company_name IN VARCHAR2, 
    pv_nip_pesel IN VARCHAR2,
    pv_last_name IN VARCHAR2, 
    pv_first_name IN VARCHAR2, 
    pv_country IN VARCHAR2, 
    pv_city IN VARCHAR2, 
    pv_postal_code IN VARCHAR2, 
    pv_street IN VARCHAR2,
    pv_building_nr IN VARCHAR2, 
    pv_apartment_nr IN VARCHAR2, 
    pv_phone IN VARCHAR2, 
    pv_email IN VARCHAR2);
    
    
END pkg_delivery_company;

/
--------------------------------------------------------
--  DDL for Package Body PKG_DELIVERY_COMPANY
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY PKG_DELIVERY_COMPANY AS

--function that encrypts the password
  FUNCTION f_get_encrypt_password(
    pv_login IN VARCHAR2,
    pv_password IN VARCHAR2
  ) RETURN VARCHAR2
  AS
    v_string VARCHAR2(40 CHAR) := 'super secret password';
  BEGIN
    RETURN dbms_crypto.HASH(utl_raw.cast_to_raw(pv_login||v_string||pv_password),dbms_crypto.hash_sh1);
  END;

--functions that checks the user's identity
  FUNCTION f_authentication(
    p_username IN VARCHAR2,
    p_password IN OUT VARCHAR2
  ) RETURN BOOLEAN 
  AS
  
    v_verified clients.verified%TYPE;
    v_blocked  clients.blocked%TYPE;
    v_password clients.PASSWORD%TYPE;
    
 BEGIN
    
    p_password := f_get_encrypt_password(pv_login => upper(p_username),pv_password => p_password);
          
    SELECT verified, blocked, PASSWORD
        INTO v_verified, v_blocked, v_password
        FROM clients
        WHERE upper(login) LIKE upper(p_username);
        
    IF UPPER(p_password) != UPPER(v_password) THEN
        apex_util.set_session_state('LOGIN_ERROR','Podane has³o jest niepoprawne!');
        RETURN FALSE;
    END IF;
    
    IF v_verified = 'N' THEN
        apex_util.set_session_state('LOGIN_ERROR','Twoje konto nie zosta³o jeszcze zweryfikowane.');
        RETURN FALSE;
    END IF;
    
    IF v_blocked = 'Y' THEN
        apex_util.set_session_state('LOGIN_ERROR','Twoje konto jest zablokowane!');
        RETURN FALSE;
    END IF;
    
    RETURN TRUE;
    
  EXCEPTION
    WHEN no_data_found THEN
        apex_util.set_session_state('LOGIN_ERROR','U¿ytkownik nie istnieje!');
    return false;
  END f_authentication;

--procedure that add new client
PROCEDURE p_add_client(
    pv_login IN VARCHAR2, 
    pv_password_io IN OUT VARCHAR2, 
    pv_company_name IN VARCHAR2, 
    pv_nip_pesel IN VARCHAR2,
    pv_last_name IN VARCHAR2, 
    pv_first_name IN VARCHAR2, 
    pv_country IN VARCHAR2, 
    pv_city IN VARCHAR2, 
    pv_postal_code IN VARCHAR2, 
    pv_street IN VARCHAR2,
    pv_building_nr IN VARCHAR2,
    pv_apartment_nr IN VARCHAR2,
    pv_phone IN VARCHAR2,
    pv_email IN VARCHAR2
    )
    AS
    BEGIN
    
    pv_password_io := f_get_encrypt_password(pv_login => upper(pv_login), pv_password => pv_password_io);
    
    INSERT INTO clients
    (nr,login,PASSWORD,company_name,nip_pesel,last_name,first_name,country,city,postal_code,street,building_nr,apartment_nr,phone,email,verified,blocked)
    VALUES
    (seq_clients.nextval,pv_login,pv_password_io,pv_company_name,pv_nip_pesel,pv_last_name,pv_first_name,pv_country,pv_city,pv_postal_code,pv_street,pv_building_nr,pv_apartment_nr,pv_phone,pv_email,'N','N');
    
    COMMIT;
    
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
    END p_add_client;
    
    
END pkg_delivery_company;

/
