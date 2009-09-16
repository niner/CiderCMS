--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = off;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET escape_string_warning = off;

SET search_path = public, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: site; Type: TABLE; Schema: public; Owner: nine; Tablespace: 
--

CREATE TABLE site (
    id integer NOT NULL,
    parent integer,
    sort_id integer DEFAULT 0 NOT NULL,
    type character varying DEFAULT 'site'::character varying NOT NULL,
    active_start timestamp without time zone,
    active_end timestamp without time zone,
    title character varying NOT NULL
);


ALTER TABLE public.site OWNER TO nine;

--
-- Name: site_id_seq; Type: SEQUENCE; Schema: public; Owner: nine
--

CREATE SEQUENCE site_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.site_id_seq OWNER TO nine;

--
-- Name: site_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: nine
--

ALTER SEQUENCE site_id_seq OWNED BY site.id;


--
-- Name: site_id_seq; Type: SEQUENCE SET; Schema: public; Owner: nine
--

SELECT pg_catalog.setval('site_id_seq', 1, false);


--
-- Name: sys_attrs; Type: TABLE; Schema: public; Owner: nine; Tablespace: 
--

CREATE TABLE sys_attrs (
    type character varying NOT NULL,
    id character varying NOT NULL,
    name character varying NOT NULL,
    sort_id integer DEFAULT 0 NOT NULL,
    data_type character varying NOT NULL,
    repetitive boolean DEFAULT false NOT NULL,
    default_value character varying
);


ALTER TABLE public.sys_attrs OWNER TO nine;

--
-- Name: sys_object; Type: TABLE; Schema: public; Owner: nine; Tablespace: 
--

CREATE TABLE sys_object (
    id integer NOT NULL,
    parent integer,
    sort_id integer DEFAULT 0 NOT NULL,
    type character varying NOT NULL,
    active_start timestamp without time zone,
    active_end timestamp without time zone
);


ALTER TABLE public.sys_object OWNER TO nine;

--
-- Name: sys_object_id_seq; Type: SEQUENCE; Schema: public; Owner: nine
--

CREATE SEQUENCE sys_object_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.sys_object_id_seq OWNER TO nine;

--
-- Name: sys_object_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: nine
--

ALTER SEQUENCE sys_object_id_seq OWNED BY sys_object.id;


--
-- Name: sys_object_id_seq; Type: SEQUENCE SET; Schema: public; Owner: nine
--

SELECT pg_catalog.setval('sys_object_id_seq', 1, false);


--
-- Name: sys_types; Type: TABLE; Schema: public; Owner: nine; Tablespace: 
--

CREATE TABLE sys_types (
    id character varying NOT NULL,
    name character varying NOT NULL,
    type character varying NOT NULL
);


ALTER TABLE public.sys_types OWNER TO nine;

--
-- Name: id; Type: DEFAULT; Schema: public; Owner: nine
--

ALTER TABLE site ALTER COLUMN id SET DEFAULT nextval('site_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: nine
--

ALTER TABLE sys_object ALTER COLUMN id SET DEFAULT nextval('sys_object_id_seq'::regclass);


--
-- Data for Name: site; Type: TABLE DATA; Schema: public; Owner: nine
--

COPY site (id, parent, sort_id, type, active_start, active_end, title) FROM stdin;
\.


--
-- Data for Name: sys_attrs; Type: TABLE DATA; Schema: public; Owner: nine
--

COPY sys_attrs (type, id, name, sort_id, data_type, repetitive, default_value) FROM stdin;
\.


--
-- Data for Name: sys_object; Type: TABLE DATA; Schema: public; Owner: nine
--

COPY sys_object (id, parent, sort_id, type, active_start, active_end) FROM stdin;
\.


--
-- Data for Name: sys_types; Type: TABLE DATA; Schema: public; Owner: nine
--

COPY sys_types (id, name, type) FROM stdin;
\.


--
-- Name: site_pkey; Type: CONSTRAINT; Schema: public; Owner: nine; Tablespace: 
--

ALTER TABLE ONLY site
    ADD CONSTRAINT site_pkey PRIMARY KEY (id);


--
-- Name: sys_attrs_pkey; Type: CONSTRAINT; Schema: public; Owner: nine; Tablespace: 
--

ALTER TABLE ONLY sys_attrs
    ADD CONSTRAINT sys_attrs_pkey PRIMARY KEY (type, id);


--
-- Name: sys_object_pkey; Type: CONSTRAINT; Schema: public; Owner: nine; Tablespace: 
--

ALTER TABLE ONLY sys_object
    ADD CONSTRAINT sys_object_pkey PRIMARY KEY (id);


--
-- Name: sys_types_pkey; Type: CONSTRAINT; Schema: public; Owner: nine; Tablespace: 
--

ALTER TABLE ONLY sys_types
    ADD CONSTRAINT sys_types_pkey PRIMARY KEY (id);


--
-- Name: public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM postgres;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO PUBLIC;


--
-- PostgreSQL database dump complete
--

