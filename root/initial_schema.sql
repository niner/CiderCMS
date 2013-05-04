SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = off;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET escape_string_warning = off;

SET default_with_oids = false;

CREATE TABLE sys_types (
    id character varying NOT NULL primary key,
    name character varying NOT NULL,
    page_element boolean NOT NULL default false
);

CREATE TABLE sys_attributes (
    type character varying NOT NULL references sys_types (id) deferrable,
    id character varying NOT NULL,
    name character varying NOT NULL,
    sort_id integer DEFAULT 0 NOT NULL,
    data_type character varying NOT NULL,
    repetitive boolean DEFAULT false NOT NULL,
    mandatory boolean DEFAULT false NOT NULL,
    default_value character varying,
    primary key (type, id)
);

CREATE TABLE sys_object (
    id integer NOT NULL primary key,
    parent integer,
    parent_attr varchar,
    sort_id integer DEFAULT 0 NOT NULL,
    type character varying NOT NULL references sys_types (id),
    changed timestamp not null default now(),
    tree_changed timestamp not null default now(),
    active_start timestamp without time zone,
    active_end timestamp without time zone,
    dcid character varying,
    constraint unique_dcid unique (parent, dcid),
    constraint unique_sort_id unique (parent, parent_attr, sort_id)
);

CREATE SEQUENCE sys_object_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;

ALTER SEQUENCE sys_object_id_seq OWNED BY sys_object.id;

ALTER TABLE sys_object ALTER COLUMN id SET DEFAULT nextval('sys_object_id_seq'::regclass);

CREATE OR REPLACE FUNCTION sys_objects_bi() RETURNS TRIGGER AS
$BODY$
DECLARE
BEGIN
    IF NEW.id IS NOT NULL THEN
        insert into sys_object (id, parent, parent_attr, sort_id, type, changed, tree_changed, active_start, active_end, dcid) values (NEW.id, NEW.parent, NEW.parent_attr, NEW.sort_id, TG_TABLE_NAME, NEW.changed, NEW.tree_changed, NEW.active_start, NEW.active_end, NEW.dcid) returning id into NEW.id;
    ELSE
        insert into sys_object (parent, parent_attr, sort_id, type, changed, tree_changed, active_start, active_end, dcid) values (NEW.parent, NEW.parent_attr, NEW.sort_id, TG_TABLE_NAME, NEW.changed, NEW.tree_changed, NEW.active_start, NEW.active_end, NEW.dcid) returning id into NEW.id;
    END IF;
    RETURN NEW;
END;
$BODY$
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION sys_objects_bu() RETURNS TRIGGER AS
$BODY$
DECLARE
BEGIN
    IF NEW.id <> OLD.id THEN
        RAISE EXCEPTION 'Changing ids is forbidden.';
    END IF;
    update sys_object set id=NEW.id, parent=NEW.parent, parent_attr=NEW.parent_attr, sort_id=NEW.sort_id, changed=NEW.changed, tree_changed=NEW.tree_changed, active_start=NEW.active_start, active_end=NEW.active_end, dcid=NEW.dcid where id=NEW.id;
    RETURN NEW;
END;
$BODY$
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION sys_objects_ad() RETURNS TRIGGER AS
$BODY$
DECLARE
BEGIN
    delete from sys_object where id = OLD.id;
    RETURN OLD;
END;
$BODY$
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION sys_object_au() RETURNS TRIGGER AS
$BODY$
DECLARE
BEGIN
    IF OLD.sort_id IS DISTINCT FROM NEW.sort_id OR OLD.parent IS DISTINCT FROM NEW.parent OR OLD.parent_attr IS DISTINCT FROM NEW.parent_attr THEN
        EXECUTE 'update ' || quote_ident(NEW.type) || ' set sort_id=' || NEW.sort_id || ', parent=' || NEW.parent || ', parent_attr=''' || NEW.parent_attr || ''' where id=' || NEW.id;
    END IF;
    RETURN NEW;
END;
$BODY$
LANGUAGE 'plpgsql';

create trigger sys_object_au after update on sys_object for each row execute procedure sys_object_au();

CREATE TABLE sys_users (
    id serial NOT NULL primary key,
    name varchar NOT NULL unique,
    password varchar NOT NULL
);
