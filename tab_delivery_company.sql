
DROP TABLE clients CASCADE CONSTRAINTS;

DROP TABLE delivery CASCADE CONSTRAINTS;

DROP TABLE delivery_details CASCADE CONSTRAINTS;

DROP TABLE parcels CASCADE CONSTRAINTS;

DROP TABLE payers CASCADE CONSTRAINTS;

DROP TABLE payment_recipients CASCADE CONSTRAINTS;

DROP TABLE stations CASCADE CONSTRAINTS;

DROP TABLE statues CASCADE CONSTRAINTS;

CREATE TABLE clients (
    nr                NUMBER(5) NOT NULL,
    company_name      VARCHAR2(80 CHAR),
    nip_pesel         VARCHAR2(11 CHAR),
    last_name         VARCHAR2(50 CHAR),
    first_name        VARCHAR2(30 CHAR),
    country           VARCHAR2(40 CHAR) NOT NULL,
    city              VARCHAR2(40 CHAR) NOT NULL,
    postal_code       VARCHAR2(10 CHAR) NOT NULL,
    street            VARCHAR2(60 CHAR) NOT NULL,
    building_nr       VARCHAR2(5 CHAR) NOT NULL,
    apartment_nr      VARCHAR2(5 CHAR),
    phone             VARCHAR2(15 CHAR) NOT NULL,
    email             VARCHAR2(50 CHAR) NOT NULL,
    bank_account_nr   NUMBER(26),
    verified          VARCHAR2(1 CHAR),
    blocked           VARCHAR2(1 CHAR),
    PASSWORD          VARCHAR2(40 CHAR),
    login             VARCHAR2(15 CHAR)
);

ALTER TABLE clients ADD CONSTRAINT clients_pk PRIMARY KEY ( nr );

CREATE TABLE delivery (
    nr                            VARCHAR2(15 CHAR) NOT NULL,
    cost                          NUMBER(10,2) NOT NULL,
    content                       VARCHAR2(200 CHAR),
    comments                      VARCHAR2(200 CHAR),
    distance                      NUMBER(10) NOT NULL,
    payment_way                   VARCHAR2(50 CHAR) NOT NULL,
    payment_status                VARCHAR2(50 CHAR) NOT NULL,
    sender_company_name           VARCHAR2(80 CHAR),
    sender_nip_pesel              VARCHAR2(13 CHAR),
    sender_last_name              VARCHAR2(50 CHAR),
    sender_first_name             VARCHAR2(30 CHAR),
    sender_country                VARCHAR2(40 CHAR) NOT NULL,
    sender_city                   VARCHAR2(40 CHAR) NOT NULL,
    sender_postal_code            VARCHAR2(10 CHAR) NOT NULL,
    sender_street                 VARCHAR2(60 CHAR) NOT NULL,
    sender_building_nr            VARCHAR2(5 CHAR) NOT NULL,
    sender_apartment_nr           VARCHAR2(5 CHAR),
    sender_phone                  VARCHAR2(15 CHAR) NOT NULL,
    sender_email                  VARCHAR2(50 CHAR) NOT NULL,
    recipient_company_name        VARCHAR2(80 CHAR),
    recipient_nip_pesel           VARCHAR2(13 CHAR),
    recipient_last_name           VARCHAR2(50 CHAR),
    recipient_first_name          VARCHAR2(30 CHAR),
    recipient_country             VARCHAR2(40 CHAR) NOT NULL,
    recipient_city                VARCHAR2(40 CHAR) NOT NULL,
    recipient_postal_code         VARCHAR2(10 CHAR) NOT NULL,
    recipient_street              VARCHAR2(60 CHAR) NOT NULL,
    recipient_building_nr         VARCHAR2(5 CHAR) NOT NULL,
    recipient_apartment_nr        VARCHAR2(5 CHAR),
    recipient_phone               VARCHAR2(15 CHAR) NOT NULL,
    recipient_email               VARCHAR2(50 CHAR) NOT NULL,
    payer_nip_pesel               VARCHAR2(13 CHAR) NOT NULL,
    transport_company_nip_pesel   VARCHAR2(11 CHAR) NOT NULL
);

ALTER TABLE delivery ADD CONSTRAINT delivery_pk PRIMARY KEY ( nr );

CREATE TABLE delivery_details (
    delivery_nr    VARCHAR2(15 CHAR) NOT NULL,
    parcel_code    VARCHAR2(5 CHAR) NOT NULL,
    parcel_count   NUMBER(8) NOT NULL,
	parcel_price  NUMBER(8,2) NOT NULL,
    value          NUMBER(8,2) NOT NULL
);

ALTER TABLE delivery_details ADD CONSTRAINT delivery_details_pk PRIMARY KEY ( delivery_nr,
parcel_code );

CREATE TABLE parcels (
    code     VARCHAR2(5 CHAR) NOT NULL,
    name     VARCHAR2(50 CHAR) NOT NULL,
    weight   NUMBER(10) NOT NULL,
    length   NUMBER(10) NOT NULL,
    height   NUMBER(10) NOT NULL,
    width    NUMBER(10) NOT NULL,
    price    NUMBER(8,2) NOT NULL
);

ALTER TABLE parcels ADD CONSTRAINT parcels_pk PRIMARY KEY ( code );

CREATE TABLE payers (
    nip_pesel               VARCHAR2(13 CHAR) NOT NULL,
    company_name            VARCHAR2(80 CHAR),
    last_name               VARCHAR2(50 CHAR),
    first_name              VARCHAR2(30 CHAR),
    country                 VARCHAR2(40 CHAR) NOT NULL,
    city                    VARCHAR2(40 CHAR) NOT NULL,
    postal_code             VARCHAR2(10 CHAR) NOT NULL,
    street                  VARCHAR2(60 CHAR) NOT NULL,
    building_nr             VARCHAR2(5 CHAR) NOT NULL,
    apartment_nr            VARCHAR2(5 CHAR),
    phone                   VARCHAR2(15 CHAR) NOT NULL,
    email                   VARCHAR2(50 CHAR) NOT NULL,
    payer_bank_account_nr   VARCHAR2(26 CHAR)
);

ALTER TABLE payers ADD CONSTRAINT payers_pk PRIMARY KEY ( nip_pesel );

CREATE TABLE payment_recipients (
    nip_pesel      VARCHAR2(11 CHAR) NOT NULL,
    company_name   VARCHAR2(80 CHAR),
    last_name      VARCHAR2(50 CHAR),
    first_name     VARCHAR2(30 CHAR),
    country        VARCHAR2(40 CHAR) NOT NULL,
    city           VARCHAR2(40 CHAR) NOT NULL,
    postal_code    VARCHAR2(10 CHAR) NOT NULL,
    street         VARCHAR2(60 CHAR) NOT NULL,
    building_nr    VARCHAR2(5 CHAR) NOT NULL,
    apartment_nr   VARCHAR2(5 CHAR),
    phone          VARCHAR2(15 CHAR) NOT NULL,
    email          VARCHAR2(50 CHAR) NOT NULL
);

ALTER TABLE payment_recipients ADD CONSTRAINT payment_recipients_pk PRIMARY KEY ( nip_pesel );

CREATE TABLE stations (
    code                  VARCHAR2(5 CHAR) NOT NULL,
    name                  VARCHAR2(50 CHAR) NOT NULL,
    country        VARCHAR2(40 CHAR) NOT NULL,
    city           VARCHAR2(40 CHAR) NOT NULL,
    postal_code    VARCHAR2(10 CHAR) NOT NULL,
    street         VARCHAR2(60 CHAR) NOT NULL,
    building_nr    VARCHAR2(5 CHAR) NOT NULL,
    apartment_nr   VARCHAR2(5 CHAR)
);

ALTER TABLE stations ADD CONSTRAINT stations_pk PRIMARY KEY ( code );

CREATE TABLE statues (
    date_time      TIMESTAMP NOT NULL,
    delivery_nr    VARCHAR2(15 CHAR) NOT NULL,
    station_code   VARCHAR2(5 CHAR) NOT NULL,
    description    VARCHAR2(80 CHAR) NOT NULL
);

ALTER TABLE statues ADD CONSTRAINT statues_pk PRIMARY KEY ( delivery_nr,
date_time );

ALTER TABLE delivery_details
    ADD CONSTRAINT delivery_details_delivery_fk FOREIGN KEY ( delivery_nr )
        REFERENCES delivery ( nr );

ALTER TABLE delivery_details
    ADD CONSTRAINT delivery_details_parcels_fk FOREIGN KEY ( parcel_code )
        REFERENCES parcels ( code );

ALTER TABLE delivery
    ADD CONSTRAINT delivery_payers_fk FOREIGN KEY ( payer_nip_pesel )
        REFERENCES payers ( nip_pesel );

ALTER TABLE delivery
    ADD CONSTRAINT delivery_payment_recipients_fk FOREIGN KEY ( transport_company_nip_pesel )
        REFERENCES payment_recipients ( nip_pesel );

ALTER TABLE statues
    ADD CONSTRAINT statues_delivery_fk FOREIGN KEY ( delivery_nr )
        REFERENCES delivery ( nr );

ALTER TABLE statues
    ADD CONSTRAINT statues_stations_fk FOREIGN KEY ( station_code )
        REFERENCES stations ( code );
