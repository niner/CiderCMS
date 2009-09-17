SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = off;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET escape_string_warning = off;

SET default_with_oids = false;

CREATE TABLE sys_attrs (
    type character varying NOT NULL,
    id character varying NOT NULL,
    name character varying NOT NULL,
    sort_id integer DEFAULT 0 NOT NULL,
    data_type character varying NOT NULL,
    repetitive boolean DEFAULT false NOT NULL,
    default_value character varying
);

CREATE TABLE sys_object (
    id integer NOT NULL,
    parent integer,
    sort_id integer DEFAULT 0 NOT NULL,
    type character varying NOT NULL,
    changed timestamp not null default now(),
    tree_changed timestamp not null default now(),
    active_start timestamp without time zone,
    active_end timestamp without time zone
);

CREATE SEQUENCE sys_object_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;

ALTER SEQUENCE sys_object_id_seq OWNED BY sys_object.id;

SELECT pg_catalog.setval('sys_object_id_seq', 1, false);

CREATE TABLE sys_types (
    id character varying NOT NULL,
    name character varying NOT NULL,
    type character varying NOT NULL
);

CREATE TABLE site (
    id integer NOT NULL,
    parent integer,
    sort_id integer DEFAULT 0 NOT NULL,
    type character varying DEFAULT 'site'::character varying NOT NULL,
    changed timestamp not null default now(),
    tree_changed timestamp not null default now(),
    active_start timestamp without time zone,
    active_end timestamp without time zone,
    title character varying NOT NULL
);

CREATE SEQUENCE site_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;

ALTER SEQUENCE site_id_seq OWNED BY site.id;

SELECT pg_catalog.setval('site_id_seq', 1, false);

ALTER TABLE site ALTER COLUMN id SET DEFAULT nextval('site_id_seq'::regclass);

ALTER TABLE sys_object ALTER COLUMN id SET DEFAULT nextval('sys_object_id_seq'::regclass);

ALTER TABLE ONLY site
    ADD CONSTRAINT site_pkey PRIMARY KEY (id);

ALTER TABLE ONLY sys_attrs
    ADD CONSTRAINT sys_attrs_pkey PRIMARY KEY (type, id);

ALTER TABLE ONLY sys_object
    ADD CONSTRAINT sys_object_pkey PRIMARY KEY (id);

ALTER TABLE ONLY sys_types
    ADD CONSTRAINT sys_types_pkey PRIMARY KEY (id);

