--
-- PostgreSQL database dump
--

-- Dumped from database version 9.5.12
-- Dumped by pg_dump version 9.5.12

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: pd_dfsbenchmarking; Type: SCHEMA; Schema: -; Owner: joebrew
--

CREATE SCHEMA pd_dfsbenchmarking;


ALTER SCHEMA pd_dfsbenchmarking OWNER TO joebrew;

--
-- Name: assessments_data_save(character varying); Type: FUNCTION; Schema: pd_dfsbenchmarking; Owner: joebrew
--

CREATE FUNCTION pd_dfsbenchmarking.assessments_data_save(v_session_id character varying) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE i_count int default 0;
BEGIN

  create temp table _inserts(u_assessment_id int,u_question_id int,u_entry_time timestamp);
create index if not exists _inserts_index ON _inserts USING btree (u_assessment_id,u_question_id,u_entry_time);

with data_uploads as
(
select assessment_id,question_id,last_modified_time as entry_time,last_modified_user_id as entry_user_id,score,rationale
from public._pd_dfsbenchmarking_save_client_assessment_data
where pd_dfsbenchmarking.user_has_client_access(client_id,pd_dfsbenchmarking.user_id_session_chain( v_session_id ))
),
data_inserts as
(
insert into pd_dfsbenchmarking.assessment_data(assessment_id,question_id,entry_time,entry_user_id,score,rationale)
select assessment_id,question_id,entry_time,entry_user_id,score,rationale
from data_uploads
on conflict(assessment_id,question_id,entry_time) do update set score=excluded.score,rationale=excluded.rationale
returning assessment_id,question_id,entry_time
)
insert into _inserts(u_assessment_id,u_question_id,u_entry_time)
select assessment_id,question_id,entry_time
from data_inserts;

delete from public._pd_dfsbenchmarking_save_client_assessment_data
where exists(select * from _inserts where u_assessment_id = assessment_id and u_question_id = question_id and u_entry_time = last_modified_time);

select count(*) into i_count from _inserts;

drop table _inserts;

return i_count;

END; 
$$;


ALTER FUNCTION pd_dfsbenchmarking.assessments_data_save(v_session_id character varying) OWNER TO joebrew;

--
-- Name: client_assessment_edit(character varying, integer, integer, character varying, date); Type: FUNCTION; Schema: pd_dfsbenchmarking; Owner: joebrew
--

CREATE FUNCTION pd_dfsbenchmarking.client_assessment_edit(v_session_id character varying, v_assessment_id integer, v_client_id integer, v_assessment_name character varying, v_assessment_date date) RETURNS integer
    LANGUAGE plpgsql
    AS $$
declare v_new_assessment_id int default null;
begin

v_new_assessment_id := v_assessment_id;

IF coalesce(v_assessment_id,-1) = -1 THEN
insert into pd_dfsbenchmarking.assessments(client_id,assessment_name,assessment_date,created_by_user_id)
select v_client_id,v_assessment_name,v_assessment_date,users.user_id
from pd_dfsbenchmarking.users
where users.session_id = v_session_id::uuid and 
pd_dfsbenchmarking.user_has_client_access(v_client_id,pd_dfsbenchmarking.user_id_session_chain(v_session_id))
on conflict do nothing;

ELSE
update pd_dfsbenchmarking.assessments set(assessment_name,assessment_date) = (v_assessment_name,v_assessment_date)
where assessments.assessment_id = v_assessment_id and
assessments.client_id = v_client_id and
pd_dfsbenchmarking.user_has_client_access(assessments.client_id,pd_dfsbenchmarking.user_id_session_chain(v_session_id))
and not exists(select * from pd_dfsbenchmarking.assessments ca2 
 where ((ca2.assessment_name = v_assessment_name or ca2.assessment_date = v_assessment_date) 
 and ca2.assessment_id <> v_assessment_id
 and ca2.client_id = v_client_id));

  END IF;

select assessment_id into v_new_assessment_id 
from pd_dfsbenchmarking.assessments
where client_id = v_client_id and assessment_name = v_assessment_name and assessment_date = v_assessment_date;

return coalesce(v_new_assessment_id,v_assessment_id);

end; 
$$;


ALTER FUNCTION pd_dfsbenchmarking.client_assessment_edit(v_session_id character varying, v_assessment_id integer, v_client_id integer, v_assessment_name character varying, v_assessment_date date) OWNER TO joebrew;

--
-- Name: client_edit(uuid, integer, integer, character varying, character varying, character varying, character varying, character varying, character varying); Type: FUNCTION; Schema: pd_dfsbenchmarking; Owner: joebrew
--

CREATE FUNCTION pd_dfsbenchmarking.client_edit(v_session_id uuid, v_client_id integer, v_ifc_client_id integer, v_name character varying, v_short_name character varying, v_firm_type character varying, v_address character varying, v_city character varying, v_country character varying) RETURNS integer
    LANGUAGE plpgsql
    AS $$
declare v_new_client_id int default null;
declare v_user_id_chain int[] default null;
begin

select user_id_chain into v_user_id_chain from pd_dfsbenchmarking.user_id_session_chain(v_session_id);

--select user_id_chain from pd_dfsbenchmarking.user_id_session_chain(v_session_id);
--select user_id_chain into v_user_id_chain from pd_dfsbenchmarking.user_id_session_chain('ab35a18f-dcc8-4f86-aedc-2bcdee3fd0b3')

insert into pd_dfsbenchmarking.clients(client_id,ifc_client_id,"name",short_name,firm_type,address,city,country,created_by_user_id)
select 
case when coalesce(v_client_id,-1) < 1 then NULL else v_client_id end as client_id,
v_ifc_client_id,v_name,v_short_name,v_firm_type,v_address,v_city,v_country,
users.user_id
from pd_dfsbenchmarking.users
where users.session_id = v_session_id -- insert where client is logged in (has a session)
  on conflict(client_id)
do update set (ifc_client_id,"name",short_name,firm_type,address,city,country) = 
(v_ifc_client_id,v_name,v_short_name,v_firm_type,v_address,v_city,v_country)
where clients.client_id = v_client_id  -- where conflicting client_id matches and user has access to edit
--and pd_dfsbenchmarking.user_has_client_access(v_client_id,pd_dfsbenchmarking.user_id_session_chain(v_session_id))
and pd_dfsbenchmarking.user_has_client_access(clients.client_id,v_user_id_chain)
returning clients.client_id into v_new_client_id;

return v_new_client_id;

end; 
$$;


ALTER FUNCTION pd_dfsbenchmarking.client_edit(v_session_id uuid, v_client_id integer, v_ifc_client_id integer, v_name character varying, v_short_name character varying, v_firm_type character varying, v_address character varying, v_city character varying, v_country character varying) OWNER TO joebrew;

--
-- Name: client_edit(character varying, integer, integer, character varying, character varying, character varying, character varying, character varying, character varying); Type: FUNCTION; Schema: pd_dfsbenchmarking; Owner: joebrew
--

CREATE FUNCTION pd_dfsbenchmarking.client_edit(v_session_id character varying, v_client_id integer, v_ifc_client_id integer, v_name character varying, v_short_name character varying, v_firm_type character varying, v_address character varying, v_city character varying, v_country character varying) RETURNS integer
    LANGUAGE plpgsql
    AS $$
declare v_new_client_id int default null;
begin

v_new_client_id := v_client_id;

IF coalesce(v_client_id,-1) = -1 THEN
insert into pd_dfsbenchmarking.clients(ifc_client_id,"name",short_name,firm_type,address,city,country,created_by_user_id)
select 
v_ifc_client_id,v_name,v_short_name,v_firm_type,v_address,v_city,v_country,users.user_id
from pd_dfsbenchmarking.users
where users.session_id = v_session_id::uuid 
on conflict do nothing 
returning clients.client_id into v_new_client_id;
ELSE
update pd_dfsbenchmarking.clients set(ifc_client_id,"name",short_name,firm_type,address,city,country) = 
(v_ifc_client_id,v_name,v_short_name,v_firm_type,v_address,v_city,v_country)
where clients.client_id = v_client_id  -- where conflicting client_id matches and user has access to edit
and pd_dfsbenchmarking.user_has_client_access(clients.client_id,pd_dfsbenchmarking.user_id_session_chain(v_session_id))
and not exists(select * from pd_dfsbenchmarking.clients c2 where ((c2."name" = v_name or c2.short_name = v_short_name) and c2.client_id <> v_client_id))
returning clients.client_id into v_new_client_id;
  END IF;

return coalesce(v_new_client_id,v_client_id);

end; 
$$;


ALTER FUNCTION pd_dfsbenchmarking.client_edit(v_session_id character varying, v_client_id integer, v_ifc_client_id integer, v_name character varying, v_short_name character varying, v_firm_type character varying, v_address character varying, v_city character varying, v_country character varying) OWNER TO joebrew;

--
-- Name: user_create(character varying, character varying, character varying, character varying, integer); Type: FUNCTION; Schema: pd_dfsbenchmarking; Owner: joebrew
--

CREATE FUNCTION pd_dfsbenchmarking.user_create(v_username character varying, v_password character varying, v_name character varying, v_email character varying, v_upi integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$
declare v_user_id int4;
BEGIN

insert into pd_dfsbenchmarking.users("username","password","name","email",upi,can_login,last_login)
values(lower(trim(v_username)),
 CRYPT(v_password, GEN_SALT('md5')),
 v_name,
 v_email,
 v_upi,
 true,
 NULL)
returning user_id into v_user_id;

return(v_user_id);

END; 
$$;


ALTER FUNCTION pd_dfsbenchmarking.user_create(v_username character varying, v_password character varying, v_name character varying, v_email character varying, v_upi integer) OWNER TO joebrew;

--
-- Name: user_has_client_access(integer, integer[]); Type: FUNCTION; Schema: pd_dfsbenchmarking; Owner: joebrew
--

CREATE FUNCTION pd_dfsbenchmarking.user_has_client_access(v_client_id integer, v_user_id_chain integer[]) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
declare v_has_access boolean default false;
begin
select (ARRAY[created_by_user_id] <@ v_user_id_chain) into v_has_access
from pd_dfsbenchmarking.clients where clients.client_id = v_client_id;

return coalesce(v_has_access,false);
end;
$$;


ALTER FUNCTION pd_dfsbenchmarking.user_has_client_access(v_client_id integer, v_user_id_chain integer[]) OWNER TO joebrew;

--
-- Name: user_id_session_chain(character varying); Type: FUNCTION; Schema: pd_dfsbenchmarking; Owner: joebrew
--

CREATE FUNCTION pd_dfsbenchmarking.user_id_session_chain(v_session_id character varying) RETURNS integer[]
    LANGUAGE plpgsql
    AS $$
declare user_id_chain int[] default null;
BEGIN
--This function doesn't do much now
--To Do: create user groups that allow nesting so managers or supervisors can see clients/assessments created under them
--and admins can see all created
select array_agg(distinct user_id) into user_id_chain from pd_dfsbenchmarking.users where session_id = v_session_id::uuid;
return user_id_chain;
END;
$$;


ALTER FUNCTION pd_dfsbenchmarking.user_id_session_chain(v_session_id character varying) OWNER TO joebrew;

--
-- Name: user_login(character varying, character varying); Type: FUNCTION; Schema: pd_dfsbenchmarking; Owner: joebrew
--

CREATE FUNCTION pd_dfsbenchmarking.user_login(v_username character varying, v_password character varying) RETURNS TABLE(user_id integer, name character varying, session_id character varying)
    LANGUAGE plpgsql
    AS $$
declare v_user_id int4 default null;
declare v_name varchar default null;
declare v_session_id uuid default null;
BEGIN

select users.user_id,users."name" into v_user_id,v_name
from pd_dfsbenchmarking.users
where lower(username) = lower(trim(v_username)) and
"password" = CRYPT(v_password,"password");

update pd_dfsbenchmarking.users
set last_login = now(), session_id = gen_random_uuid()
where v_user_id is not null and users.user_id = v_user_id
returning users.session_id into v_session_id;

return query select (coalesce(v_user_id,-1)) as user_id, v_name as "name", v_session_id::varchar as session_id;

END; 
$$;


ALTER FUNCTION pd_dfsbenchmarking.user_login(v_username character varying, v_password character varying) OWNER TO joebrew;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: assessment_data; Type: TABLE; Schema: pd_dfsbenchmarking; Owner: joebrew
--

CREATE TABLE pd_dfsbenchmarking.assessment_data (
    assessment_id integer NOT NULL,
    question_id integer NOT NULL,
    entry_time timestamp(6) without time zone DEFAULT now() NOT NULL,
    entry_user_id integer NOT NULL,
    score numeric(3,1) NOT NULL,
    rationale text
);


ALTER TABLE pd_dfsbenchmarking.assessment_data OWNER TO joebrew;

--
-- Name: assessment_question_categories; Type: TABLE; Schema: pd_dfsbenchmarking; Owner: joebrew
--

CREATE TABLE pd_dfsbenchmarking.assessment_question_categories (
    category_id integer NOT NULL,
    sort_order smallint NOT NULL,
    category_name character varying(40) NOT NULL
);


ALTER TABLE pd_dfsbenchmarking.assessment_question_categories OWNER TO joebrew;

--
-- Name: assessment_question_categories_category_id_seq; Type: SEQUENCE; Schema: pd_dfsbenchmarking; Owner: joebrew
--

CREATE SEQUENCE pd_dfsbenchmarking.assessment_question_categories_category_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


ALTER TABLE pd_dfsbenchmarking.assessment_question_categories_category_id_seq OWNER TO joebrew;

--
-- Name: assessment_question_categories_category_id_seq; Type: SEQUENCE OWNED BY; Schema: pd_dfsbenchmarking; Owner: joebrew
--

ALTER SEQUENCE pd_dfsbenchmarking.assessment_question_categories_category_id_seq OWNED BY pd_dfsbenchmarking.assessment_question_categories.category_id;


--
-- Name: assessment_questions; Type: TABLE; Schema: pd_dfsbenchmarking; Owner: joebrew
--

CREATE TABLE pd_dfsbenchmarking.assessment_questions (
    question_id integer NOT NULL,
    category_id integer NOT NULL,
    sort_order smallint NOT NULL,
    question_title character varying(50) NOT NULL,
    question_summary character varying(255),
    formative_text text,
    emerging_text text,
    developed_text text
);


ALTER TABLE pd_dfsbenchmarking.assessment_questions OWNER TO joebrew;

--
-- Name: assessment_questions_question_id_seq; Type: SEQUENCE; Schema: pd_dfsbenchmarking; Owner: joebrew
--

CREATE SEQUENCE pd_dfsbenchmarking.assessment_questions_question_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


ALTER TABLE pd_dfsbenchmarking.assessment_questions_question_id_seq OWNER TO joebrew;

--
-- Name: assessment_questions_question_id_seq; Type: SEQUENCE OWNED BY; Schema: pd_dfsbenchmarking; Owner: joebrew
--

ALTER SEQUENCE pd_dfsbenchmarking.assessment_questions_question_id_seq OWNED BY pd_dfsbenchmarking.assessment_questions.question_id;


--
-- Name: assessments; Type: TABLE; Schema: pd_dfsbenchmarking; Owner: joebrew
--

CREATE TABLE pd_dfsbenchmarking.assessments (
    assessment_id integer NOT NULL,
    client_id integer NOT NULL,
    assessment_name character varying(50) NOT NULL,
    assessment_date date NOT NULL,
    created_by_user_id integer NOT NULL,
    created_time timestamp(6) without time zone DEFAULT now() NOT NULL
);


ALTER TABLE pd_dfsbenchmarking.assessments OWNER TO joebrew;

--
-- Name: assessments_assessment_id_seq; Type: SEQUENCE; Schema: pd_dfsbenchmarking; Owner: joebrew
--

CREATE SEQUENCE pd_dfsbenchmarking.assessments_assessment_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


ALTER TABLE pd_dfsbenchmarking.assessments_assessment_id_seq OWNER TO joebrew;

--
-- Name: assessments_assessment_id_seq; Type: SEQUENCE OWNED BY; Schema: pd_dfsbenchmarking; Owner: joebrew
--

ALTER SEQUENCE pd_dfsbenchmarking.assessments_assessment_id_seq OWNED BY pd_dfsbenchmarking.assessments.assessment_id;


--
-- Name: clients; Type: TABLE; Schema: pd_dfsbenchmarking; Owner: joebrew
--

CREATE TABLE pd_dfsbenchmarking.clients (
    client_id integer NOT NULL,
    ifc_client_id integer,
    name character varying(255) NOT NULL,
    short_name character varying(15) NOT NULL,
    firm_type character varying(255),
    address character varying(255),
    city character varying(255),
    country character varying(255),
    created_by_user_id integer NOT NULL,
    created_time timestamp(6) without time zone DEFAULT now() NOT NULL
);


ALTER TABLE pd_dfsbenchmarking.clients OWNER TO joebrew;

--
-- Name: clients_client_id_seq; Type: SEQUENCE; Schema: pd_dfsbenchmarking; Owner: joebrew
--

CREATE SEQUENCE pd_dfsbenchmarking.clients_client_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


ALTER TABLE pd_dfsbenchmarking.clients_client_id_seq OWNER TO joebrew;

--
-- Name: clients_client_id_seq; Type: SEQUENCE OWNED BY; Schema: pd_dfsbenchmarking; Owner: joebrew
--

ALTER SEQUENCE pd_dfsbenchmarking.clients_client_id_seq OWNED BY pd_dfsbenchmarking.clients.client_id;


--
-- Name: users; Type: TABLE; Schema: pd_dfsbenchmarking; Owner: joebrew
--

CREATE TABLE pd_dfsbenchmarking.users (
    user_id integer NOT NULL,
    username character varying(30) NOT NULL,
    password character varying(100) NOT NULL,
    name character varying(255) NOT NULL,
    email character varying(255),
    upi integer,
    can_login boolean DEFAULT false NOT NULL,
    last_login timestamp(6) without time zone,
    session_id uuid,
    is_admin boolean DEFAULT false NOT NULL
);


ALTER TABLE pd_dfsbenchmarking.users OWNER TO joebrew;

--
-- Name: users_user_id_seq; Type: SEQUENCE; Schema: pd_dfsbenchmarking; Owner: joebrew
--

CREATE SEQUENCE pd_dfsbenchmarking.users_user_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 2147483647
    CACHE 1;


ALTER TABLE pd_dfsbenchmarking.users_user_id_seq OWNER TO joebrew;

--
-- Name: users_user_id_seq; Type: SEQUENCE OWNED BY; Schema: pd_dfsbenchmarking; Owner: joebrew
--

ALTER SEQUENCE pd_dfsbenchmarking.users_user_id_seq OWNED BY pd_dfsbenchmarking.users.user_id;


--
-- Name: view_assessment_questions_list; Type: VIEW; Schema: pd_dfsbenchmarking; Owner: joebrew
--

CREATE VIEW pd_dfsbenchmarking.view_assessment_questions_list AS
 SELECT aqc.category_id,
    ac.question_id,
    regexp_replace(lower((aqc.category_name)::text), '\s+'::text, '_'::text, 'g'::text) AS tab_name,
    regexp_replace(lower((ac.question_title)::text), '\s+'::text, '_'::text, 'g'::text) AS competency,
    ((regexp_replace(lower((aqc.category_name)::text), '\s+'::text, '_'::text, 'g'::text) || '_'::text) || regexp_replace(lower((ac.question_title)::text), '\s+'::text, '_'::text, 'g'::text)) AS combined_name,
    aqc.category_name,
    ac.question_title,
    ac.formative_text,
    ac.emerging_text,
    ac.developed_text
   FROM (pd_dfsbenchmarking.assessment_question_categories aqc
     JOIN pd_dfsbenchmarking.assessment_questions ac ON ((ac.category_id = aqc.category_id)))
  ORDER BY aqc.sort_order, ac.sort_order;


ALTER TABLE pd_dfsbenchmarking.view_assessment_questions_list OWNER TO joebrew;

--
-- Name: view_assessments_current_data; Type: VIEW; Schema: pd_dfsbenchmarking; Owner: joebrew
--

CREATE VIEW pd_dfsbenchmarking.view_assessments_current_data AS
 SELECT DISTINCT ON (asm.client_id, asm.assessment_id, ad.question_id) asm.client_id,
    asm.assessment_id,
    ad.question_id,
    ad.entry_time AS last_modified_time,
    ad.entry_user_id AS last_modified_user_id,
    us.name AS last_modified_user_name,
    ad.score,
    ad.rationale
   FROM ((pd_dfsbenchmarking.assessments asm
     JOIN pd_dfsbenchmarking.assessment_data ad ON ((ad.assessment_id = asm.assessment_id)))
     LEFT JOIN pd_dfsbenchmarking.users us ON ((us.user_id = ad.entry_user_id)))
  ORDER BY asm.client_id, asm.assessment_id, ad.question_id, ad.entry_time DESC;


ALTER TABLE pd_dfsbenchmarking.view_assessments_current_data OWNER TO joebrew;

--
-- Name: view_client_assessment_listing; Type: VIEW; Schema: pd_dfsbenchmarking; Owner: joebrew
--

CREATE VIEW pd_dfsbenchmarking.view_client_assessment_listing AS
 SELECT assessments.assessment_id,
    assessments.client_id,
    assessments.assessment_name,
    assessments.assessment_date
   FROM pd_dfsbenchmarking.assessments;


ALTER TABLE pd_dfsbenchmarking.view_client_assessment_listing OWNER TO joebrew;

--
-- Name: view_client_listing; Type: TABLE; Schema: pd_dfsbenchmarking; Owner: joebrew
--

CREATE TABLE pd_dfsbenchmarking.view_client_listing (
    created_by_user_id integer,
    client_id integer,
    ifc_client_id integer,
    name character varying,
    address character varying(255),
    city character varying(255),
    country character varying(255),
    created_by character varying(255),
    assessments bigint,
    last_assessment character varying
);

ALTER TABLE ONLY pd_dfsbenchmarking.view_client_listing REPLICA IDENTITY NOTHING;


ALTER TABLE pd_dfsbenchmarking.view_client_listing OWNER TO joebrew;

--
-- Name: category_id; Type: DEFAULT; Schema: pd_dfsbenchmarking; Owner: joebrew
--

ALTER TABLE ONLY pd_dfsbenchmarking.assessment_question_categories ALTER COLUMN category_id SET DEFAULT nextval('pd_dfsbenchmarking.assessment_question_categories_category_id_seq'::regclass);


--
-- Name: question_id; Type: DEFAULT; Schema: pd_dfsbenchmarking; Owner: joebrew
--

ALTER TABLE ONLY pd_dfsbenchmarking.assessment_questions ALTER COLUMN question_id SET DEFAULT nextval('pd_dfsbenchmarking.assessment_questions_question_id_seq'::regclass);


--
-- Name: assessment_id; Type: DEFAULT; Schema: pd_dfsbenchmarking; Owner: joebrew
--

ALTER TABLE ONLY pd_dfsbenchmarking.assessments ALTER COLUMN assessment_id SET DEFAULT nextval('pd_dfsbenchmarking.assessments_assessment_id_seq'::regclass);


--
-- Name: client_id; Type: DEFAULT; Schema: pd_dfsbenchmarking; Owner: joebrew
--

ALTER TABLE ONLY pd_dfsbenchmarking.clients ALTER COLUMN client_id SET DEFAULT nextval('pd_dfsbenchmarking.clients_client_id_seq'::regclass);


--
-- Name: user_id; Type: DEFAULT; Schema: pd_dfsbenchmarking; Owner: joebrew
--

ALTER TABLE ONLY pd_dfsbenchmarking.users ALTER COLUMN user_id SET DEFAULT nextval('pd_dfsbenchmarking.users_user_id_seq'::regclass);


--
-- Data for Name: assessment_data; Type: TABLE DATA; Schema: pd_dfsbenchmarking; Owner: joebrew
--

COPY pd_dfsbenchmarking.assessment_data (assessment_id, question_id, entry_time, entry_user_id, score, rationale) FROM stdin;
1	2	2018-03-09 18:56:37.885084	1	4.0	Hi there!
1	2	2018-03-09 18:56:52.536334	1	3.0	oops not as good
1	2	2018-03-09 18:57:05.306983	1	6.0	now even better!
1	3	2018-03-09 18:57:05.306983	1	4.0	ok
1	5	2018-03-09 18:57:05.306983	1	3.0	ok3
24	2	2018-03-11 03:00:47	1	3.0	A bit better...
24	3	2018-03-11 03:00:54	1	6.0	No, actually, great!
24	5	2018-03-11 03:00:45	1	2.0	We're a 2!
24	2	2018-03-11 03:40:32	1	2.0	We're a 2!
24	3	2018-03-11 03:40:32	1	3.0	A bit better...
24	4	2018-03-11 03:40:32	1	2.0	A little worse
24	5	2018-03-11 03:40:32	1	6.0	No, actually, great!
24	2	2018-03-11 03:43:02	1	2.0	We're a 2!
24	3	2018-03-11 03:43:02	1	3.0	A bit better...
24	4	2018-03-11 03:43:02	1	2.0	A little worse
24	5	2018-03-11 03:43:02	1	6.0	No, actually, great!
24	2	2018-03-11 03:45:47	1	2.0	We're a 2!
24	3	2018-03-11 03:45:47	1	3.0	A bit better...
24	4	2018-03-11 03:45:47	1	2.0	A little worse
24	5	2018-03-11 03:45:47	1	6.0	No, actually, great!
24	2	2018-03-11 03:51:18	1	2.0	We're a 2!
24	3	2018-03-11 03:51:18	1	3.0	A bit better...
24	4	2018-03-11 03:51:18	1	2.0	A little worse
24	5	2018-03-11 03:51:18	1	6.0	No, actually, great!
24	2	2018-03-11 03:54:44	1	2.0	We're a 2!
24	3	2018-03-11 03:54:44	1	3.0	A bit better...
24	4	2018-03-11 03:54:44	1	2.0	A little worse
24	5	2018-03-11 03:54:44	1	6.0	No, actually, great!
24	2	2018-03-11 03:55:12	1	2.0	We're a 2!
24	3	2018-03-11 03:55:12	1	3.0	A bit better...
24	4	2018-03-11 03:55:12	1	2.0	A little worse
24	5	2018-03-11 03:55:12	1	6.0	No, actually, great!
24	2	2018-03-11 03:56:12	1	2.0	We're a 2!
24	3	2018-03-11 03:56:12	1	3.0	A bit better...
24	4	2018-03-11 03:56:12	1	2.0	A little worse
24	5	2018-03-11 03:56:12	1	6.0	No, actually, great!
24	2	2018-03-11 03:56:43	1	2.0	We're a 2!
24	3	2018-03-11 03:56:43	1	3.0	A bit better...
24	4	2018-03-11 03:56:43	1	2.0	A little worse
24	5	2018-03-11 03:56:43	1	6.0	No, actually, great!
24	4	2018-03-11 03:58:53	1	2.0	A little worse
24	2	2018-03-11 03:58:53	1	2.0	We're a 2!
24	3	2018-03-11 03:58:53	1	3.0	A bit better...
24	5	2018-03-11 03:58:53	1	6.0	No, actually, great!
24	4	2018-03-11 03:59:04	1	2.0	A little worse
24	4	2018-03-11 04:08:45	1	2.0	A little worse
24	3	2018-03-11 04:08:45	1	3.0	A bit better...
24	4	2018-03-11 04:09:08	1	2.0	A little worse
24	2	2018-03-11 04:08:45	1	2.0	We're a 2!
24	5	2018-03-11 04:08:45	1	6.0	No, actually, great!
24	4	2018-03-11 04:09:47	1	2.0	A little worse
24	3	2018-03-11 04:09:50	1	3.0	A bit better...
24	15	2018-03-11 04:10:10	1	4.0	4
24	2	2018-03-11 04:12:40	1	2.0	We're a 2!
24	3	2018-03-11 04:12:40	1	3.0	A bit better...
24	4	2018-03-11 04:12:40	1	2.0	A little worse
24	5	2018-03-11 04:12:40	1	6.0	No, actually, great!
24	15	2018-03-11 04:12:42	1	4.0	4
24	2	2018-03-11 04:15:24	1	2.0	We're a 2!
24	3	2018-03-11 04:15:24	1	3.0	A bit better...
24	4	2018-03-11 04:15:24	1	2.0	A little worse
24	5	2018-03-11 04:15:24	1	6.0	No, actually, great!
24	15	2018-03-11 04:15:26	1	4.0	4
24	2	2018-03-11 04:15:57	1	2.0	We're a 2!
24	3	2018-03-11 04:15:57	1	3.0	A bit better...
24	2	2018-03-11 04:17:42	1	2.0	We're a 2!
24	3	2018-03-11 04:17:42	1	3.0	A bit better...
24	4	2018-03-11 04:17:42	1	2.0	A little worse
24	5	2018-03-11 04:17:42	1	6.0	No, actually, great!
24	15	2018-03-11 04:17:44	1	4.0	4
24	2	2018-03-11 04:18:16	1	2.0	We're a 2!
24	3	2018-03-11 04:18:16	1	3.0	A bit better...
24	4	2018-03-11 04:18:16	1	2.0	A little worse
24	5	2018-03-11 04:18:16	1	6.0	No, actually, great!
24	15	2018-03-11 04:18:18	1	4.0	4
24	2	2018-03-11 04:19:19	1	2.0	We're a 2!
24	3	2018-03-11 04:19:19	1	3.0	A bit better...
24	4	2018-03-11 04:19:19	1	2.0	A little worse
24	5	2018-03-11 04:19:19	1	6.0	No, actually, great!
24	15	2018-03-11 04:19:21	1	4.0	4
24	2	2018-03-11 11:12:11	1	2.0	We're a 2!
24	3	2018-03-11 11:12:12	1	3.0	A bit better...
24	4	2018-03-11 11:12:12	1	2.0	A little worse
24	5	2018-03-11 11:12:12	1	6.0	No, actually, great!
24	15	2018-03-11 11:12:19	1	4.0	4
\.


--
-- Data for Name: assessment_question_categories; Type: TABLE DATA; Schema: pd_dfsbenchmarking; Owner: joebrew
--

COPY pd_dfsbenchmarking.assessment_question_categories (category_id, sort_order, category_name) FROM stdin;
1	1	Strategy and execution
2	2	Organization and governance
3	3	Partnerships
4	4	Products
5	5	Marketing
6	6	Distribution and channels
7	7	Risk management
8	8	IT and MIS
9	9	Operations and customer service
10	10	Responsible finance
\.


--
-- Name: assessment_question_categories_category_id_seq; Type: SEQUENCE SET; Schema: pd_dfsbenchmarking; Owner: joebrew
--

SELECT pg_catalog.setval('pd_dfsbenchmarking.assessment_question_categories_category_id_seq', 11, true);


--
-- Data for Name: assessment_questions; Type: TABLE DATA; Schema: pd_dfsbenchmarking; Owner: joebrew
--

COPY pd_dfsbenchmarking.assessment_questions (question_id, category_id, sort_order, question_title, question_summary, formative_text, emerging_text, developed_text) FROM stdin;
2	1	1	Vision	\N	There are diverse perspectives about what a digital bank means reflecting a lack of alignment and common vision about where the business needs to go. This often results in piecemeal initiatives or misguided efforts that lead to missed opportunities, sluggish performance and false starts of the digitak bank	Bank leaders may have a clear and common understanding\nof exactly what digital means to them and, as a result, what it means to their business and articulated in any position document but it is somewhat theoretical and not translated into an actionable plan for implementation	Being digital is about using data to make better and faster decisions, devolving decision making to smaller teams, and developing much more iterative and rapid ways of doing things. \nCross functional teams share the same rooms fostering creativity \nThinking in a digital way is not limited to just a handful of functions. It incorporates a broad swath of how the bank operate, including creatively partnering with external companies to extend necessary capabilities. The bank's digital mind-set institutionalizes cross-functional collaboration, flattens hierarchies, and builds environments to encourage the generation of new ideas. Incentives and metrics are developed to support such decision-making agility.\n                       The organizational culture is perceived as "agile": quick to mobilize, nimble, collaborative, easy to get things done, responsive, flow of information, quick decision making, empowered to act, resilient, learning from failures.\n                       They are able to support the cultural shift.
3	1	2	Strategy formulation	\N	The digital strategy is more "evolutionary" than "revolutionary", it focuses on a few areas of the existing business model, in particular: \n- Customer engagement: migrating to direct digital channels; the bank is providing a seamless online and offline channel experience.\n- Ecosystem network engagement: extending the network of business partners developping limited new digital affiliate partnerships\n-Employee engagement: providing employees with effective tools for collaboration \nThe strategy is formalised around the points described. \nTop management counts with enough market intelligence to identify competitors, define a SWOT analysis and define business targets.	The digital strategy starts to become more "revolutionary", than evolutionary; it focuses on more areas of the existing business model on top of the ones described already in particular: \n- Customer engagement: Developing deeper customer understanding from multiple internal and external data sources. Using customer analytics for next-best offer proposition and enhanced customer profitability management. Creating multiple mechanisms for instantaneous collaboration and exchange with and between customers.\n- Ecosystem network engagement:Creating cross-industry customer data sources often through loyalty schemes. Positioning third- party offers and services in extension to own services.\n-Employee engagement: Implementing new intelligent communications platforms, developing\na continuous innovation capability. Introducing new mobile solutions for field workforce, providing remote working solutions.\n-Automation and efficiency: Automating and simplifying front-end and back-end processes, extending customer self-servicing, automating customer servicing and order management. Introducing remote monitoring\nand tracking solutions. \n- Content: Creating personalized interfaces, providing real-time and instantaneous interaction, providing configuration and collaboration functionalities. \nThe strategy is formalised around the points described. Top management is able to articulate targets around broad areas described above	The digital strategy is truly "revolutionary". It focuses on a new business model to become a game changer in the financial industry, in particular besides the features described in "formative" and "emerging" digital strategies, the Bank also develops: \n- Customer communities:Identifying and empowering customer communities around common interests and needs. Leveraging crowd intelligence and power by enabling customers to communicate with each other and the bank.\n- Creative service partners: Developing a platform approach (mostly open source) enabling service partners to develop and sell services and products. Extending the bankâ€™s products and service portfolio through service partners creating a broader customer experience\nand tie-in. \n-Information networks: Developing information networks based on internal and external data and content sources (including connected devices/IOT). Motivating customers to share information and intelligence creating win-win propositions\n-Bridging "bricks and bits": Creating a seamless experience and offer between the physical and the digital world. Integrating hardware and software offerings to drive customer choice and purchase. Merging digital and physical into a hybrid experience.\nThe strategy is formalised around the points described. \nTop management can articulate targets around all areas describe micro-action plans for each of them
4	1	3	Management committment	\N	Pressure to change comes fom outside. Whiel bank managemetn may understand the need to digitize, there is little or no action Government pressure/incentives, sometimes corporate citizenship, are the only drivers for the entity to develop offers for risk of social/financial inclusion customers (e.g. pensioneers, low income, etc); The Bank has enough growth opportunities for digital not to be a priority	The Bank's managemetn is committed to digital transformation. It sees the market pressure and understands the opportuntiies technology brings; wether internal processes, channels and / or through partnerships to gorw the business	The Management sees digital as an opportunity to drive revenue and customer growth over time
5	1	4	Execution capability	\N	The digital bank area is understaffed and does not have formal agile methodologies. Most of the people in the digital bank comes from the "traditional bank" without a formal assessment of digital capabilities \nDigital Projects are not developed as distinct pieces of work, and are instead managed within existing workloads. \nThere is no governance on project delivery, and cost, time and quality is not tracked. Projects routinely do not get delivered or are not delivered to expectation.	Digital Projects are identified and managed as distinct pieces of work. Agile  methodologies are applied, but these are informal and reflective of the experience of the project manager, rather than documented processes. \nProjects are tracked for cost, time and quality, however projects are often not delivered to expectation.	There is a strong sense of governance for project delivery in the organization. All digital initiatives are delivered through use of an organization-wide agilet methodology. The delivery cycles are within weeks and reworked on a "trial and error" approach. Projects are delivered on time, within budget, and to expectation more often than not.
6	2	1	Culture	\N	There is a poor collaboration culture, the decisions are made only by very hierarchical committees and there is no empowerment to lower levesl of the organization.\nInnovation is perceived as something to be done only by engineers and not as a collective effort of the whole organisation.\nThere is strong paper-based culture and not so much around digital workflows.\nThe information is kept in silos and departments are refrained to share data on an informal fashion\nThe organizational culture is perceived as "hierarchical": risk-averse, efficient, slow, standard ways of working, decision scalation, reliable, centralised, siloed.\nThe need for a cultural shift has not yet been recognized.	Collaboration is strong however not very efficient as teams are not in the same room but rather scattered in different floors and even different buildings making information exchange not so efficient.\nDecisions are based on intelligence allowing the delivery of content and experiences that are personalized and relevant to the customer.\nSilos are being tumbled down and automation is widely accepted at all levels of the organization.\nThe organizational culture is perceived to a certain extent as a  "startup": creative, no boundaries, sharing, frentic, continously reinventing the wheel, ad hoc, constantly shifting focus.\nThere is a recognition for cultural shift.	Being digital is about using data to make better and faster decisions, devolving decision making to smaller teams, and developing much more iterative and rapid ways of doing things. \nCross functional teams share the same rooms fostering creativity \nThinking in a digital way is not limited to just a handful of functions. It incorporates a broad swath of how the bank operate, including creatively partnering with external companies to extend necessary capabilities. The bank's digital mind-set institutionalizes cross-functional collaboration, flattens hierarchies, and builds environments to encourage the generation of new ideas. Incentives and metrics are developed to support such decision-making agility.\nThe organizational culture is perceived as "agile": quick to mobilize, nimble, collaborative, easy to get things done, responsive, flow of information, quick decision making, empowered to act, resilient, learning from failures.\nThey are able to support the cultural shift.
19	5	1	Customer insights	\N	The Bank does not conduct customer demand market research, the needs or customer satifaction knowledge is based on informal questioning to customers at the branch. There is no established process to understand the digital needs of customers.\nThere is no competitive analysis done ad hoc, but rather, the Bank relies on "off the shelf" studies conducted by the industry bodies	There are customer demand market research studies, the needs or customer satifaction are based on studies commissioned from time to time.\nThere is competitive analysis done ad hoc.	All customer needs and customer satisfaction are made on a regular basis using formally commissioned studies but also systematically scouting social networks, blogs, etc to pulse the market real time.
7	2	2	People	\N	"People is glued to the ""old organization mentality"", a managerâ€™s status and salary were based on the size of the projects he or she was responsible for and on the number of employees on his or her team. \nPeople stick to their defined roles and responsibilities and job categories and there is little ""horizontal moves"" to other areas.\nPeople profile are focused on department tasks.\nThere is no such a role as a CDO.	"People work in teams and the teams are very cohesive, allowing team members to have ""veto rights"" if they feel a candidate will not fit in the team. Teams that are united in a common purpose, interact closely with customers, and are constantly able to reshape what they are working on.\nProfiles are more multidisciplinary and people's expertise span to many other knowledge areas, in particular:\n- ï¿¼ï¿¼Customer experience grounding: ability to design customer- centric experiences throughout customer decision journey\n- Market orientation: ability to deeply understand market trends, partner ecosystems, and competitive strategies \n- Business acumen: comfort with business strategy, portfolio prioritization, go to market, pricing, and tracking key perfor- mance indicators and financial metrics\nThe CDO position can be created depending on the importance given to the Digital Bank unit or the need of digital transformation"	In an "agile mentality" what matters is how people deal with knowledge. A big part of the transformation is about ensuring there is a good mix between different layers of knowledge and expertise.\nPeople's profile is a compendium of multidisciplinar areas of expertise mixing soft and hard skills:\n- ï¿¼ï¿¼Customer experience grounding: ability to design customer- centric experiences throughout customer decision journey\n- Market orientation: ability to deeply understand market trends, partner ecosystems, and competitive strategies \n- Business acumen: comfort with business strategy, portfolio prioritization, go to market, pricing, and tracking key perfor- mance indicators and financial metrics\n- Technical skills: ability to go deep on technology trends, architectural questions, stack control points, road maps, and managing development life cycle\n- Soft skills: ability to lead teams, communicate with diverse groups, and influence change throughout organization\nThe CDO position is created showing the importance given to the Digital Bank unit or the need of digital transformation
8	2	3	Structure	\N	The bank organizational structure reflect a "bureaucracy" that follow rules that determine where resources, power, and authority lie, with clear boundaries for each role and an established hierarchy for oversight. The bank is based on traditional hierarchiesâ€”boxes and lines on the org chartâ€”typically specify where work gets done and performance is measured, and whoâ€™s responsible for awarding bonuses. All this generally involves a boss (or two in matrix organizations), who oversees work and manages direct reports. People is only motivated by extrinsic rewards via payroll and bonuses	The bank organizational structure reflect a "meritocracy" where\nindividual knowledge is privileged. \nThe traditional boxes of the org chart tend to change very often but reflect a cross functional organization with some support functions and some customer facing evolving teams. Although teams count much all individuals are assessed individually and they always belong to a business unit. \nPeope tend to be motivated by an interesting work and enabling them to achieve personal mastery in a field of expertise	The bank organizational structure reflect a "Adhocracy" where\naction is privileged. \nAgile digital banks deliberately choose which dimension of their organizational structure will be their â€œprimaryâ€ one. This choice will dictate where individual employees work (where they are likely to receive coaching and training) and where the infrastructure around their jobs is located. \nDay-to-day work, performance measurement, and the determination of rewards happen in teams that cut across formal structures. The primary home of employees remains an anchor along their career paths, while the crosscutting teams form, dissolve, and re-form as resources shift in response to market demands. Sometimes these dynamic teams show up in the org chart, typically in the form of business lines, market segments, or product units.\nPeople's motivation centers on giving people a challenge and providing the resources and freedom they need to surmount it
9	2	4	HR function	\N	Job profiles are not adapted to new/changing organization.\nDedicated training is not yet developed.\nHR canâ€™t support talent recruitment and retention.	Job profiles exist and some specific training is developed or in place. There is not yet a creer path or framework, but it is under development. There is a strategy/ability to attract and retain the right talent.	HR has developed dedicated training. Job profiles exist for job positions. There is a career framework and a career path. There is a strategy to attract and retain the right talent.
10	2	5	Governance	\N	When decisions require collaboration, governance committees bring together business leaders to share information and to review proposals coming up from the business units.\nAnalysis paralysis is common place (gathering more and more information rather than making a decision), endless debate, and a bias toward rational, scientific evidence at the expense of intuition or gut feel biasses decision making	Digital agenda is delegated to "digital experts" within the organization. \nDecisions are empowered more to individuals, sometimes individuals leverage from data analitycs to make decisions but many times are based on intution when the field is an uncharted territory.\nDecisions are made through argument and discussion, and everyone is entitled to weigh in with a point of view but decisions are taken helping the bank to avoid analysis paralysis.\nAt the executive level, attention is focused; people are not distracted; and the data are impeccable thus decisions are not unduly delayed due to "governance" and policies	The digital agenda is owned by CEO and Board of Directors. Decisions are clasiffied into those best made in committees, which can be delegated to direct reports and which can be delegated to people close to the day-to-day action. furthermore, management decisions are improved as algorithms crunch big data from social technologies or the Internet of Things coupled with other point-of-contact data.\nThe full digital bank cater for flexible forms of governance, so they can be created and closed down very quickly, according\nto the nature of the opportunity. \nBy emphasizing experimentation, motivation, and urgency, the governance of a true digital bank provides a necessary complement to progress in advanced analytics and in machine learning, which automates decisions previously made through more bureaucratic approaches.\nDecision makers are deeply immersed in the flow of a project or a business rather than more removed from it.
11	3	1	FinTechs	\N	"APIs are not opened and no middleware is in place.\nNo ability to connect with FinTechs, other that through the core banking system.\nLimited awareness of FinTech market developments and technological solutions.\nInnovative concepts are tested only on an ad hoc basis"	FinTechs are not yet connected or there are limited partnership with FinTechs. They have a plan to develop middleware or open APIs to be able to connect with FinTechs. Actively monitor the market and have some knowledge of market developments and technological solutions. Ability to test new concepts is not yet fully developed.	There is a middleware in place or open APIs\nFinTechs can be connected \nThere is an innovation lab or process to test emerging technologies/concepts.\nThey actively monitor the FinTech evolution and are knowledgable of market developments and technological solutions.
12	3	2	BigTechs	\N	No concrete opportunities have been pursued. No discussions with Big Techs are underway.\nBig Data & Analytics is under development.	They recognize the opportunity and early stage discussions are underway.\nSome capacity for Big Data & Analytics.	Alliances and business opportunities have been developed with Big Techs.\nSystems are integrated. Big Data & Analytics capacity is in place.
34	8	5	Reporting and analysis	\N	Client data is stored, but data quality is weak as staff are not sensitized to the importance of good client data; data maybe scattered through many databases, many in-house made in low capability DB (e.g. Access); reporting in Excel with no data integrity; lack of coherent transaction and customer history\nThe lack of a common CRM database inhibits the Bankâ€™s capabilities in identifying and cross servicing their customers who may be scattered in several databases .\nEither the Bankâ€™s systems are incapable of supporting data-mining or the organization sees no value in the process.\nStaff with specific reporting need to rely on IT staff to develop ad hoc data requests. \n\n\n\n\n	Client data is available and consistent, without duplication. \nMost useful client data is stored in the Bankâ€™s CRM / MIS system.\nClient data and account history data are stored in a central data warehouse to allow data mining and development of statistical models using advanced analytics.\nPre-defined data requests are available to users according to their needs, and most advanced users are given tools to design their own request to the central database;\nFor each process in the Bank systems allow detailed tracking of performance and efficiency ;\nOperational staffâ€™s daily activity is driven by automated reporting tools to prioritize daily work and measure past performance.\n\n\n\n\n\n\n	Client data is comprehensive and sourced from internal as well as external sources.\nThe Bank has a strong quantitative culture, and comprehensive data warehousing is used for reporting, piloting and modeling purposes;\nDetailed transactions are mined for marketing purpose;\nAt all levels of the organization, staff are motivated by comparative daily performance measurement, provided by automated activity reports;\nA dedicated analytical team is in charge of coordinating/conducting analysis and making sure the insights are used not only as a one-off exercise, such as strategy development, but also to influence policy making (e.g. pricing guidelines), performance management (e.g. target setting) and tactical improvement initiatives (e.g. process redesign).\n\n\n\n\n\n
13	3	3	RegTechs	\N	No concrete opportunities have been pursued. No discussions with RegTechs are underway.\nThe Bank still rely on manual processing for any compliance documentation such as KYC forms, AML checks, CFT processing, etc; Likewise, the bank relies on manual processing of regulation/supervisory impacted processes; no automation of processes impacted by supervisor "guidelines"; no capacity to automate consumer protection activities impacting service delivery; there is no capacity to collect, use and analize policy data;\nThe Bank is not taking part in any "Regulatory Sandbox" (if permitted in the country) to test new processess under a more agile regulatory environment.	The Bank recognizes the opportunity for RegTechs and early stage discussions are underway.\nThe Bank starts to automate compliance documentation such as KYC forms, AML checks, CFT processing, etc; The bank relies less on manual processing of regulation/supervisory impacted processes; there is som degree of automation of processes impacted by supervisor "guidelines"; there is capacity to automate consumer protection activities impacting service delivery; there is capacity to collect, use and analize policy data;\nThe Bank is now taking part in a "Regulatory Sandbox" (if permitted in the country)  to test new processess under a more agile regulatory environment.	Alliances and business opportunities have been developed with RegTechs, allowing the Bank to significantly reduce spending in compliance documentation. \nAll processess involving compliance, customer service, supervisory, policies/guidelines documents impacting service delivery are now fully automated; Systems are integrated; RegTech capacity is in place.\nThe Bank takes part in a "Regulatory Sandbox" (if permitted in the country)  testing new processess in a more agile regulatory environment and providing active feedback to regulator.
14	3	4	Maturity of ecosystem partners	\N	The Bank does not have effective partnerships in the digital ecosystem.\nThe digital solution of the Bank is largely closed-loop, with little additional services through other ecosystem partners. \nThere are no APIs for access into the Bankâ€™s payment system. \n\n\n	The Bank has some additional products through development of the digital ecosystem. The products are limited to billing capabilities. \nThere may be some API capability to allow easier access to other parties in the payment ecosystem. \n\n\n\n	The Bank has highly leveraged the digital ecosystem to provide customers with multiple products including seamless ATM access, POS acceptance through various technologies (e.g. NFC, etc) multiple billers, integration with social media apps (e.g. Facebook connect, etc)\nEcosystem partners see significant benefit in partnering with the FSP, to the extent that they lobby the FSP for easier access through APIs or similar. \n\n\n\n
15	4	1	Customer journey	\N	Customer touch points are limited to branch, call center and some not-feature rich interaction in the website. No mobile offering as yet.\nThe Bank does exploit any prior action from potential customers browsing the website, the prospect identity is never capture prior to account opening losing a great deal of data.\nThe account opening process, which is the first step as customer, is cumbersome. New-account-opening form fields may range from 30 up to 45 fields, yet this could be reduced  to just 15 fields and pre-populated 10 of them from external data sources that are not exploited. The Bank does not run focus groups to ask prospects or customers who to better open a bank account or interact with them. \nThere is no customer journey view: registration, interaction, cross-selling, pre-attrition and win-back	Customer touch points are: branch, call center, website and mobile. There is however not a full customer-touch point view and information may not be fully integrated or if so it may not be real time.\nThe Bank exploit any prior action from potential customers browsing the website, the prospect identity is capture prior to account opening losing a great deal of data.\nThe account opening process is flawless. New-account-opening form fields may range from 25 up to 30 fields and there is limited pre-populated fields from prior web interactions but not from external data from other partners  that are not exploited. The Bank run focus groups to ask prospects or customers who to better open a bank account or interact with them. \nThere is customer journey view: registration, interaction, cross-selling, pre-attrition and win-back. Furthermore, the Bank has taken some important actions such as:\n- Understand how customers navigate across the touchpoints as they move through the journey.\n- Anticipate the customerâ€™s needs, expectations, and desires during each part of the journey.	Customer touch points are: branch, call center, website, mobile and other partners. All touch points are seamlessly integrated real time allowing a a full 360Âº customer-touch point view.\nThe Bank exploit any prior action from potential customers browsing the website, the prospect identity is capture prior to account opening losing a great deal of data.\nThe account opening process is flawless. New-account-opening form fields are very limited and there is pre-populated fields from prior web interactions and from external data from other partners  that are exploited. The Bank redesign customer facing touch points processes following agile methodologies and zero-based design proess techniques.\nThere is customer journey view: registration, interaction, cross-selling, pre-attrition and win-back and predictive analysis allows the Bank to offer the best customer experience.\nThe Bank really master the customer journey touchpoints as:\n- Step back and identify the nature of the journeys customers takeâ€”from the customerâ€™s point of view.\n- Build an understanding of what is working and what is not.\n- Set priorities for the most important gaps and opportunities to improve the journey.\n- Come to grips with fixing root-cause issues and redesigning the journeys for a better end-to-end experience.\n\n
16	4	2	Range of products	\N	Products are limited to current/savings account, cards, basic payments (ATMs, POS, Internet)	Products are more developed: consumer credit, line of credit for SMEs and corporates, mortages	Full bancassurance product suite including integration with other business areas: insurance (life, accident, car, property), leasing, renting, investment (investment/pension funds), broker (shares, bonds, international capital markets)
17	4	3	Product pricing	\N	Only anchor products are free of charge, like a current account if direct deposit of salary exists and one debit card per customer, free interest for purchases up to three months, free deposit and withdrawal of money in ATM of the Bank's network	Customers are offered a kind of a flat fee / commission for main banking products. ATM's deposits and withdrawal enjoy a low commission when done in another bank's network	A true no commission policy is implemented: free cards, free checks cash in, free transfrers, free account maintenance, free cash withdrawal at Bank's networ and very low fee from other bank's ATM networks, free anti fraud protection. \nThe Bank wants to become a "game-changer" in the way prices are set in Financial Services
18	4	4	Product development and open innovation	\N	Products are launched ad hoc, with no process for gathering data from research, testing of products or analysis of results. \nExisting products are not managed or priced correctly. There is no product committees operating within the business and decisions on products are made without engagement of critical areas such as sales, operations or technology. \n\n	Limited market research is undertaken to develop new products, and there is some appreciation of the need for process. \nA product committee exists in the business, and the interdependence of new products with support areas in the business is understood. \nThe Bank has Open APIs to allow innovation from third parties but rarely participates in Open Innovation forums nor plays a proactive approach in seeking for latests innovations in Financial Services.\n\n	The integration of product development and IT operations enable the bank to develop innovative new product features.\nThe product lifecycle is no longer divided into 5 or 6 yearly releases but on biweekly product releases with a "trail and error" mode.\nProduct innovation is done by "squads" of people drawn from operations, sales, finance and marketing, and products are launched in accordance with "agile methodology" with multidisciplinar teams working together in the same room until product is released. "Squads" are assembled on a case-by-case basis\nThere are specific "trend spotters" to screen customer's unprompted needs. \nThe Bank has Open APIs to allow innovation from third parties and actively participates in Open Innovation forums where it plays a proactive approach in seeking for latests innovations in Financial Services.\n\n
20	5	2	Communications	\N	The bank's communication campaigns use traditional mass media only (TV, press, radio).\nCommunication messages are around "hard" product features: interest rates, commissions, product characteristics like term or absence of collateral, "no frills", etc	The bank's communication campaigns use a mix of traditional mass media (TV, press, radio) and offline events to promote the brand and some social media like facebook campaign\nCommunication messages are around "hard" and also "soft" product features focusing on the emotional /sticky character of the service: personlisation, no commission, simplified processess, "we simplify your life", "we allow you to get the most out of your money", etc.\nThe visuals of the campaign are somewhat "rule-breakers" of traditional communications	The bank's communication campaigns use a mainly digital means from m-marketing, to viral marketing using whatsapp, facebook, community events online, gammification to promote the brand including word-of-mouth rewards.\nCommunication messages are around the brand, it focuses more on values of the brand than on the banking and insurane products being offered: messages around "honesty", "always close", "we never let you down", "we grow with you" are common. \nCampaigns are sometimes commonly developed with selected customers and non-customers to get the pulse of the market.\nThe campaigns may use non banking related instituions like a museum, online market place or a philarmonic orchestra to promote the brand\nThe use of teasers before the name of the brand is unveiled is profoundly used\nTwitter and Facebook are heavily used to promote the brand\nThe use of brand ambassadors, bloggers and other online characters are used to defend the reputation of the brand
21	5	3	Marketing maturity	\N	The business does not have a marketing plan, and there is no individual solely appointed to act as marketing manager. \nMarketing personnel is not involved in any product design or pricing, they only get product specs and then they produce marketing campaigns or product leaflets\nMarketing, when done, does not successfully highlight the benefits of the products, and is there is no causative link between marketing activities and business performance. \nMarketing is managed in house, without involvement of external experts. Marketing lacks digital marketing capabilities\n\n\n\n	There is a marketing function within the business, and marketing is seen as an important element of success. \nMarketing personnel are involved in product and pricing squads in certain occasions. There are identifiable benefits from marketing activities, including a deep understanding of social media and digital marketing\nMarketing is done as a mix of above and below the line activities, and focuses on educating customers on product benefits and usage. \nMarketing activities are assisted by a professional agency, and work is of a reasonable standard. \n\n\n\n	Product marketing changes the shift from product marketing to customer journey and omnichannels. Marketing personnel is always part of the product definition "squads".\nAll digital solutions are tested through "prototype cycles" \nMarketing is a highly developed function that is critical to the performance of the business. \nThe marketing Manager focuses on customer experience and has market orientation, business acumen, technical skills, soft skills, and is a key organizational enablers.\nThe organization is assisted by innovative digital marketing agencies that develops high quality digital communication campaigns in support of the brand and proposition. \n\n\n\n
22	6	1	Strategy and organization	\N	There is no dedicated sales function. Customers are acquired ad hoc through agents, or through existing branches, no other channels are devised such as remote onboarding through call center, apps or website\nThere is no omnichannel strategy in place for customer acquisition, or driving sales growth.\nThere is not an effective sales culture in the organization. \n	There is an omnichannel sales strategy in place that leverages multiple channels for customer growth, including agents,  existing branches, virtual branches, including remote onboarding through call center, apps or website\nThere is a sales organization in place, with a head of sales, and sales team members responsible for management of various channels. \nThe organization, whilst focused on sales, could see improvements to the sales culture. \n	The omnichannel sales strategy is well developed, and leverages partnerships or third party arrangements to drive customer sales.\nThe organization has an effective sales function, with sales being the primary focus of all functions in the business, including operations and the call centre. \nThere is a strong sales culture in the organization.  \n
23	6	2	Physical network	\N	The branch still has a old-fashioned look and feel.\nThe branch equipment does not include latest technologies such as flat screens, tablets and only a tiny part of floor area is dedicated to front line banking operations.\nCashier is still behind a glass marking a distance with customers.\nThe branch employees still sits behind a desk with customers in front. They are typically especialised by operations.\n\nThe breadth of the branch network is not enough, primarily being based on major cities in the market. ATMs are not located in strategic spots.\nSelection of new branch locations is ad hoc, with no analysis of geographic data or ancillary businesses in the area. \n\n	The branch now has a modern look and feel (usually minimalistic - with low ornamentation and functional furniture)\nThe branch equipment include latest technologies such as flat screens, tablets and most of floor area dedicated to front line banking operations.\nCashier are replaced by 2nd generation ATMs that allow both deposits and withdrawal of money and are more interactive.\nThe branch employees now sits side-by-side with customers explaining operations and all branch employees can perform most of bank operations.\n\nThe branch network is geographically more diverse, with an even spread between urban and semiurban locations reflecting customer presence. \nBranch locations are selected with some analysis, with the use of geographic data where available to aid selection and development of branch networks. \nFlagship Branch locations are of high quality, with high foot traffic and high profile branding so that customers can clearly identify the Branch\n\n\n\n	The branch does not look like a bank but rather a cool outlet.\nThe branch equipment include latest technologies such as flat screens, tablets, voice/face/iris recognition for customer ID and most of floor area dedicated to front line banking operations.\nThere may not be ATMs as transactions are conducted cashless and employees only go to branches to seek for complex banking services advice (not transaction related)\nThe branch employees now sits side-by-side with customers explaining operations and all branch employees can perform most of bank operations.\n\nThe branch is ubiquitous, covering many different rural and semiurban locations, providing the ability for customers of the Bank to conduct transactions wherever they may need to travel throughout the market. \nNew branch locations are carefully assessed against other agents in the area to ensure that agent economics can be maintained where possible.\nDifferent branch types (flagships, regular branches and pop-up branches) may perform different tasks per customer segment. \n\n\n\n\n
35	9	1	Customer performance	\N	The customer care is still not digital, it relies still on face-to-face interaction at the branch or through the call center.\nCall center does not have a proper call management system nor is the call center well dimensioned. Long queues pose the problem of the lack of customer drop off calls. If a call management system exist there is not a proper CRM integrated with all other customer-touch-points to have an holistic e-care view of the client\n\n	The customer care is now digital, as customers can rely on online care. The appearance, functionality, and information available in e-care services is consistent regardless of which device or software the customer use.\nCall center has a call management system and the CRM is integrated with all other customer-touch-points to have an holistic e-care view of the client\n\n	E-care goes further as the customer online experience is dynamic and interactive, with blogs, social-media feeds, user reviews, and customer forums feeding business intelligence tools to enhance e-care.\n\n\n
24	6	3	Apps webs and agents	\N	Apps: only one app limited to "basic" product features like: account balance, tranfers, credit /debit card, online payment, demand subscription of new product.\n\nWeb: The look and feel of the web is not very sophisticated, too much text and little multimedia gadgets.\nThere is no possibility to conduct KYC process through the website.\nThe product range being offered is limited to "basic" products: subscribe an account, ask for checks, ask for card, transfers, check balance, pay bills, product simulator.\n\nAgents: the Bank also uses agents but the agents still rely on paper forms to onboard customers and to service them.	Apps: videochat, notification, access to private site, activation/deactivation of e-token, biometric features like facial recognisition or finger print authentication, allow contactless payment through mobile device.\n\nWeb: The look and feel of the web is somewhat sophisticated with a "fresher design", with some multimedia gadgets: for instance video tutorials. Possibility to conduct some KYC steps through the website (sending some documents but the authorisation take a few days). The product range being offered allow more advance product range: chat, private site, status of credit, credit payments, investments, expense organiser (PFM 1st Generation), posibility to pay taxes, social marketing features: linkedIn microsite, facebook microsite, twitter and instagram presence.\n\nAgents: the Bank uses agents who work with digital means such as Pads/ smartphones but they have restricted functionalities	Apps: easy sign in to operate, site fully customised to cater for mobile device, some advance features such as PFM, robo-advisor, integration with personal banker and contact center button exist, product promting is executed through mobile based on behavoiour pattern, bacons technology is used and data captured for loyalty programme purpose, possibility to redeem loyalty points and partner discounts through mobile, proximity and location based services are exploted to increase share of wallet of bank.\n\nWeb: The look and feel of the web is very sophisticated in line with most renowed digital banks, with some multimedia gadgets: chatbots, robo-advisor, multimedia, products are presented like in an online mall. Full KYC can be done digitally almost instantaneously (for instance with a selfie and a scan of the official ID document)\nThe product range being offered caters for best-in-class webproducts: chat, videoassistance (through agent or vitual agent), seamless integration of call center, mobile device and personal banker, allow full customisation of webpage, predictive analysis allows to prompt specific products via robo-advisor (robo-advisor with machine learning capabilities offers targeted products based on behavioural and contextual pattern), savings and credit self-service tools, personal and home budgeting tools (PFM 2nd Generation), payments calendar available in the website with paymeny event alarms, discount of partners are intergrated in the website, gammification is also integrated in the offering, full community banking features through integration with facebook connect, the bank has community managers managing all relationships with social media, customers are actively participating in the bank's life through events and peer-advisory.\n\nAgents: the Bank uses agents who work with digital means such as Pads/ smartphones with full functionalities
25	6	4	Sales function	\N	There is no dedicated sales force; sales has no specific training; the sales process is not formally defined; sales force / customer facing personnel has clear incentives aligned to sales growth	There is dedicated sales team with some training; sales process is defined and sales workflow is mostly automated; incentives are aligned but not regularly adjusted; targets are in place and followed	There is dedicated sales team with specific training; sales process is defined and sales workflow is fully automated; incentives are aligned to meet targets and regularly adjusted; sales targets by channels including digital are defined and tracked
26	7	1	Management and organization	\N	There is no risk function identified in the Bank. Risks are not identified, managed or mitigated. The Bank does not appreciate the different operating risks introduced by digital banking and instead applies whatever existing models are already in place.	Risk is identified as an area that needs focus, and a risk manager has been appointed. Risks are documented in a risk register, communicated to senior management and there are mitigation strategies in place for most of them. A risk management committee has been appointed, but it does not meet regularly, not does it have senior management appointed. Risk awareness is embeded at Sr. and Middle management level of the Bank	The management of existing and emerging risks from digital banking is given the highest priority in the business. \nRisk registers are well developed, with management strategies for all identified risks.\nThe risk management committee meets regularly, with representation of all senior management in the organisation. \nRisks management culture is part of a Bank-wide initiative aiming to make awareness of cyberthreats and other risks when using digital technology
27	7	2	Regulatory compliance	\N	The Bank does not adhere to existing regulations in the market, or the market itself has not applied regulations to cater for digital banking. \nThere is no one appointed in the organization to ensure that regulations, if in existence are complied with. \n \n	The Bank has recognized the regulations that apply to them in the market, and has used them as the basis for building processes and policies in their own organization. \nRegulatory compliance has been audited internally, and breaches where identified are addressed and remedied. \n\n	The Bank actively engages with the regulator to help both guide new regulation and ensure that existing regulation takes a risk-based approach to their endeavors. \nThe Bank regularly conducts internal audits on regulatory compliance, and external audits have identified few if any areas of non-compliance where mitigation plans are being implemented
28	7	3	Kyc Aml maturity model	\N	KYC/AML requirements are understood, and processes are in place to capture KYC information. \nThe Bank does have access to AML/CFT databases, but checks are haphazard, and processes may not be robust enough to ensure that all positive matches are found. \nThere is no implementation of any of the latest identification technologies that avoid identity theft such as biometric ones\n \n\n\n	There are robust processes in place to ensure that KYC checks are done at customer acquisition points. Customers once activated, are validated at the Bank through checking KYC information provided by the customer. \nAll customers are passed through the necessary AML/CFT databases, and any positive matches are dealt with quickly with the customer being suspended. \nThe bank starts to implement some biometric technologies for customer identification but it may not be available nationwide and for all customer segments.	KYC checks are heavily automated, with biometric capture of customers identification (fingerprint, iris or face recognition) and documentation that is then communicated electronically to the Bank, allowing almost 100% validation that customers match documentation. \nAML checks are automated, and customers with positive checks are automatically suspended pending further investigation. \nThe Bank follows all new technology trends to enhance customer KYC. \nThe Bank regularly makes AML campaigns to all customer facing and relevant back office personnel to be aware of latest trends to counter AML and CFT\n\n\n\n\n
29	7	4	Fraud management capability	\N	Given the formative stage of the business, frauds are not well understood, nor are they a major issue in the business.\nReconciliation processes for cash and eMoney controls are poorly documented, and reconciliations are not being carried out every day, introducing the chance of fraud. \nSegregation of duties are not in place, increasing the chance of fraud, particularly for creation of eMoney in the Bank.   \nThe IT systems do not support processes designed to minimize fraud.	The risk of fraud (including cyberfraud) is understood, and likely areas of fraud are documented in the risk register and managed closely. \nReconciliation processes are in place, but cash and eMoney reconciliations may not be occurring every day. \nSegregation of duties is understood, particularly for eMoney and digital channels and reconciliations, and processes and controls exist. \nIT systems are commercial purchased, and support fraud processes. \n\n\n\n\n\n	Fraud is closely monitored in the Bank, and examples of fraud and cyberfraud are used to develop new processes when it occurs. \nReconciliation processes are mature, and occur daily. \nIT systems are very robust, and the vendor proactively assists the Bank to change processes to support fraud management efforts based on their experiences in other markets.\nThe Bank follows recommendations of international banking regulatory bodies to fight against cyberfraud.\n
30	8	1	IT and MIS strategy	\N	IT and MIS strategies are not discussed at the Board level, as they are considered to be internal organizational concerns;\nSenior management considers MIS mainly as a source of costs;\nThe IT team is disconnected from operations but as a result does not really understand how to optimize added value to the business;\nThis disconnection typically leads to either under-investment or over-investment in IT.\nIT staff remains technical only, and operational staff do not understand the potential added-value of IT for the business;\nAs a result, there are gaps between needs and available systems, at all levels in the organization;\nIT needs are included in the Digital Bankâ€™s business plan, but only as a means to meet other departmentsâ€™ needs.\n	IT is still not considered as a core part of the Bank's business but Board and senior management view MIS as a way to reduce operational risks linked to manual processing;\nIT is viewed as a way to increase staff productivity, to increase Bankâ€™s ability to create new digital products and to improve profitability; "Squads" and "tribes" work seamlessly together to enhance products and processes.\nThe IT Manager now is a CISO and is part of the executive committee and is involved in the Bankâ€™s business strategy;\nIT innovations are proposed and discussed within the management team as projects on their own merits, anticipating the needs of other departments;\nThe CISO performs annual reviews of IT needs and keeps himself/herself and his/her team informed of all new techniques available in the digital banking area.\n\n\n	IT and technology are viewed not only as a necessary building block but as a key competitive advantage aiming at increasing cost-efficiency while enhancing customer experience with the digital Bank initiative.\nThe IT strategy is regularly presented to the Board;\nThe Bank has developed a technological culture and staff is able to constantly analyze business needs and identify opportunities for IT developments; All product launches are done by efficient squads\nThere is a good fit between user needs (both internal and external) and IT developments as teams are multidisciplinary ;\nA formalized needs assessment and budget planning process ensures optimal use of IT resources and fit with the Bankâ€™s strategy;\nOutsourcing is often used as a way of permanently benefiting of the latest technologies while reducing maintenance costs.\nThe bank is constantly screening for partnership opportunities with niche vendors that are experts in their respective fields.\n\n\n
31	8	2	Hardware architecture	\N	Communications are not 100% reliable and customer data is somewhat outdated due to lack of maintenance.\nSeparate hardware infrastructure may exist to process cards, mobile transactions, web transactions, as well as additional systems for call centres or CRM, but these systems have limited communications capabilities and are not realtime.\n\n \n	A dual-speed IT architecture is a prerequisite for digital process innovation. It decouples the management of slower legacy systems on the back end from the development of faster customer-facing applications on the front end. If legacy systems are not yet faced out, the bank's solution has a data layer that sources data from underlying back-end and core banking systems, which allows the solution to deal with multiple cores and the bank to change its back end without a major impact on the digital channels\nPCs, tablets, mobile phones are used by all staff for both accessing the core system and using PC applications;\nThere is a mosaic of additional systems â€“ call-centers, ATM switches, payment applications etc., all interfaced in real time with the core system through APIs and a middleware.\nDaily data backs-up ensure data security in case of sinister\n\n\n	The IT architecture now is all operating at the same speed. Legacy systems has been faced out and a new banking core implemented  with all digital applications  intregated through APIs allowing fast implementation of digital apps and partner solutions. \nAll customer touch points apps are fully integrated.\nDisaster recovery is ensured by data mirroring as well as replication of the main hardware systems, located in remote buildings but ready to be switched on at any time to ensure business continuation.\n\n\n
32	8	3	Software architecture	\N	The core software only records accounting operations; Some more complex operations maybe handled manually. \nThe core system is primarily an account management solution, with locally developed modules for the digital channel etc.\nIT is hardly maintainable, as technology is obsolete, and due to the Bankâ€™s custom-made continous adds-on.\nDatabase manager is proprietary and cannot easily be interfaced with external tools;\nNew needs have been answered over time by designing side PC applications, which raises concerns over security and data integrity	The core system has been purchased from a regional or global provider with good references in other Banks;\nIt is built on an open operating system and a recognized database (e.g. SQL), which make interfacing with other systems possible;\nCRM and other analytics systems allow integrated management of client information from different distribution channels.\nNew products or developments can be implemented fast.\nThe Bank relies on cloud solutions to lower down costs.\nSolution architecture is based on a stateless, decoupled set of micro-services. It employs a set of decoupled widgets, such as banking services like bill payment, that can be reused across channels. The widgets are built upon common building blocks, which allows changes to be implemented quickly across all channels.\n	The core system is open and interfaced with a non-proprietary central database;\nIntroduction of new products and existing products automatically integrate all necessary information and give management access to a set of dashboards giving a comprehensive picture of the activity.\nThe bank is not tied to any specific provider when it needs to implement new functionalities, as any sub-system can easily be integrated in the whole architecture through decoupled widgets that are integrated through middleware and APIs.\nNew products are easily implemented (parameterization vs. development).\nThe Bank leverages a network of partners to cater for customer needs offering the best-of-breed solution in the local market.\nThe Bank uses advance analytics including machine learning to exploit customer data\n\n\n\n\n\n
33	8	4	IT Security	\N	IT security is not a concern of neither the CEO or the Board of Directors.\nThe IT security protocol although exists (mainly the IT risk management framework) has many flaws. \nSome security breaches had occur in the past however remedial action was taken, little was done to learn and prevent from it.\nThere is no custom to conduct external security audits to check the robustness of the system.\nThere is not or a very rudimentary Business Continuity Plan. \nData center is not duplicated in a different premise with the risk of collapse of operations if both DC are destroyed in a sinister.	IT security is the concern of the Executive and the Board of Directors. CISO debrief the Board from time to time about IT security\nThere is a comprehensive IT risk management framework dealing with at least\n- Acquisition of IT infrastructe\n- Dealing with IT sourcing risks\n- IT service management\n- Security of Operations\n- Data center protection and control\n- Principles of access control\n- Online financial services security \nThere are external security audits to check the robustness of the system and remedial action is taken\n	IT security is the concern of the whole digital Bank. Employees receive regular IT Security training to prevent cyber attacks.\nThere is a comprehensive IT risk management framework deling with at least:\n- Acquisition of IT infrastructe\n- Dealing with IT sourcing risks\n- IT service management\n- Security of Operations\n- Data center protection and control\n- Principles of access control\n- Online financial services security \n- Specific security for payment services\n- Scope of AML/CFT applied to mobile and online banking\nThere are external security audits with "red teams" to test security.\nSpecial attention is taken to spot cyberthreats such as: Cloud solutions (including ISP) threats, DDoS attacks, MITMA, man-in-the browser attack or man-in-the application attack.\nSecurity education programs for customers exists and are regularly rolled out\n
36	9	2	Agile process	\N	All bank processes are designed in a very precise, deliberate way to ensure that the organization runs as it should and that employees can rely on rules, handbooks, and priorities coming from the hierarchy to execute tasks. \nPerformance monitoring is usually at individual level.\n\n\n\n \n	Processes are defined on a very broad sense allowing flexibilty and some degree of adaptability but every one speak the same standardised language allowing everyone to understands how these key tasks are performed, who does what, and how. \nPerformance monitoring mixes both individual and team KPIs.\n\n\n\n	Processes are designed with a relatively unchanging set of core elementsâ€”a fixed backbone. The rest of processes, notably those that are more customer focus evolve as rapid and customer needs changes or competition compels the change.\nPerformance monitoring is usually done at "tribe" level more than at "squad" level compelling all to work as teams and cross-functionally along the whole organisation\n\n\n\n
37	9	3	Process automation	\N	Both front end (customer facing) and back end (back office) processes are mostly manual with a number of entry errors demanding special attention to correct issues with customers, suppliers and supervisor.	The majority of front end (customer facing) and back end (back office) processes are automated with workflows that demand to human intervention except to deal with exceptions. \nNot many resources are needed to correct issues with customers, suppliers and supervisor.	Processes are efficient, and staff workload is optimized against demand as now all processes from back office to customer facing operations are automated; the Bank has implemented a bank-wide Intelligent Process Automation (IPA) initiative.\nThe Bank's system relevant data plus the latest analytics tools are maintained by a dedicated team of knowledge professionals.\n
38	9	4	Financial controlling	\N	Although all activities are costed using cost center approach, the accounting systems does not allow full control of cost drivers as the process is not fully automated following a workflow since the entry of an e-invoice until payment. The Bank cannot calculate costs on a per-activity basis and need to rely on cost allocation methods which does not allow to properly calculate margins	All activities are costed using cost center approach. Accounting systems allow full control of cost drivers but not all activities from the accounting perspective are automated following a workflow since the entry of an e-invoice until payment. The Bank is able to assess the cost of its core processes but need to calculate an approximation for the costs related to back office processes.	All activities are costed using cost center approach. Accounting systems allow full control of cost drivers and are fully automated following a workflow since the entry of an e-invoice until payment. The Bank is able to assess the cost of its core processes both customer facing and back office ones.
39	10	1	Consumer protection strategy	\N	The institution is insufficiently aware of the potential risks clients face when using DFS, i.e. fraud, data and identity theft, poor financial decisions, non-transparent or excessive fees, etc. There is no defined Code of Conduct or overall strategies to integrate consumer protection principles.	The company has mapped the potential risks their clients face when using DFS but mitigation strategies and client  information is not integrated in standard operating procedures.   A general company code of conduct may exist; in some cases may cover overindebteness implicitly thru credit, liquidity or operational risk governance/framework/policies, but is institution specific for Basel compliance; processes not specifically communicated nor training provided for staff, i.e. customer centric principles and practices.	The company has mapped the potential risks their clients face when using DFS and has established appropriate mitigation strategies. It established a Consumer Protection strategy and, in the best case scenario, appointed a Senior Manager as head of a Responsible Finance Committee. A specific Code of Conduct/Ethics exists and is disseminated among all staff and agents, regular training/testing on the code is provided.  The Code is also integrated into staff performance assessments at all levels.\nThe sub-components of the scorecard are integrated in the code of conduct and specific metrics are used to assess staff performance, create incentives and improve customer data for product innovation\nThe Code of Ethics is regularly reviewed as part of business/strategy approval processes/timeframe (every 3 years). - The institutionâ€™s image and brand are supported by specific communications around customer centricity and responsible finance targeting shareholders, clients, staff and the broader public (e.g. local community) to enhance staff and customer loyalty, improve staff and client retention and increase profitability.
40	10	2	Responsible pricing and transparency	\N	It is difficult for the client to calculate /understand the full cost of the products. The breakdown of fees is not clearly stated in marketing materials. In certain cases (like the accumulation of high penalty fees) excessive fees can be harmful for the client.	Whilst the institution has a clear and non excessive pricing policy, it does not sufficiently control if agents might charge unauthorized fees or do not clearly disclose fees/prices to the client.	All product prices and fees, terms and conditions are unambiguously explained to the client early on in the product cycle through staff and agents.\nPrices are inline with market prices, terms and conditions, interest charges, insurance premiums, minimum balances, fees, penalties, linked products, third party fees are market-based and not excessive for clients. Product pricing, terms and conditions are fully disclosed to the customer prior to sale in local language.  The financial institution uses multiple ways for disclosing clear and accurate information about the product such as brochures, orientation sessions, meetings, posting information in the branch, website.\n
41	10	3	Complaint resolution	\N	There is no, or just a basic, informal complaint resolution mechanism in the institution. No special procedures are established and there is limited monitoring on resolution of complaints. Complaints remain at the branch level/ are not received by independent department/ staff member.	There is a formal complaints resolution mechanism but it could be as rudimental as a suggestion box. There may be a designated department/ staff to deal with the resolution. Complaint resolution, however, does not receive the attention of executive management and clients are not properly informed on the existing procedures and their right to complain.	A well functioning  and easy understandable complaints resolution process is in place (call center,  complaint hotline, messaging system, complaints department or other channel), and the are clear process and procedures on how to deal with complaints and escalations thereof. Turnaround time to resolve complaints is less than a week. Most frequent or exceptional complaints are reported to executive management.\nClients are informed and educated about the process to file complaints.\nIt is clearly defined which provider is ultimately responsible for resolving clients issues and the timeframe in which those issues should be resolved. Key staff are trained on customer service issues, how to resolve complaints and enhance customer relationships.\nSystem issues, errors or fraud that may result in customers' loss of funds may be compensated in more sophisticated digital/technology platforms.
42	10	4	Data protection	\N	Data security and encryption are not incorporated in all DFS solutions internally and for the mobile money provider.\nClients are not informed/misinformed on how their data and history is being used or shared.	Data security and encryption requirements have been incorporated but not updated frequently.\nOnly limited client data is shared, but clients are not asked for consent.	Data security and encryption requirements are incorporated into all DFS solutions.\nUse of data: customers are informed how and if their data will be used; and how it will not be used for.  \nMinimum security requirements for the mobile money provider are established.\nClient consent: customers are asked whether they are willing to share data voluntarily or to opt-out at any time from data tracking as a default.  \nPrivacy settings can be customized by client with profile options to protect privacy.\nPrivacy policies are specified in standard terms and conditions prior to sale both in digital form and in print format
43	10	5	Financial education	\N	The institution does not take adequate time to educate new clients on the products, its features and the client's responsibilities.\nStaff and agents are not aware of all product features due to low quality training.\nProducts are sold instantaneously without understanding client needs\nStaff performance is mainly volume driven and tied to bonus or minimum transactions per day/week.	New staff/ agents are properly trained on product features but product modifications are poorly communicated throughout the institution and not well documented in the product manuals. Terms and conditions and prices/fees are clearly outlined in promotional materials but staff/agents do not follow a rigorous program to inform clients at point of sale. \nDigital communication (text messaging) is used but limited to expediting digital transactions; does not promote improving ability of its customers to make more informed decisions about the products and services being offered to them.	The institutions provides internal staff and agents training to fully understand all DFS products and to better communicate financial products, terms and services offered to prospective DFS clients. This FE component also explains how to safely use DFS, avoid theft/ fraud and the consequences of over indebtedness.\nStaff officers and agents explain clearly client obligations and rights for due recourse including how to report potential customer complaints to clients. Client awareness and education on fraud protection is enacted, users should understand the importance of a PIN and not disclose it to any other user.\nThe institution also provides financial education modules to clients on how to use DFS channels, risks and responsibilities. Broad based financial education program(s) may also be in place, via partnerships with NGOs, radio or to programs. \nMore sophisticated digital communications and messaging promotes improving customer financial capability, by customized steps/messages that promote informed decisions for products (loan, savings, insurance, remittances)
\.


--
-- Name: assessment_questions_question_id_seq; Type: SEQUENCE SET; Schema: pd_dfsbenchmarking; Owner: joebrew
--

SELECT pg_catalog.setval('pd_dfsbenchmarking.assessment_questions_question_id_seq', 44, true);


--
-- Data for Name: assessments; Type: TABLE DATA; Schema: pd_dfsbenchmarking; Owner: joebrew
--

COPY pd_dfsbenchmarking.assessments (assessment_id, client_id, assessment_name, assessment_date, created_by_user_id, created_time) FROM stdin;
1	1	test assessment	2017-10-15	1	2018-03-09 18:55:42.205113
24	11	New Assessment	2018-03-11	1	2018-03-10 19:19:25.219823
\.


--
-- Name: assessments_assessment_id_seq; Type: SEQUENCE SET; Schema: pd_dfsbenchmarking; Owner: joebrew
--

SELECT pg_catalog.setval('pd_dfsbenchmarking.assessments_assessment_id_seq', 53, true);


--
-- Data for Name: clients; Type: TABLE DATA; Schema: pd_dfsbenchmarking; Owner: joebrew
--

COPY pd_dfsbenchmarking.clients (client_id, ifc_client_id, name, short_name, firm_type, address, city, country, created_by_user_id, created_time) FROM stdin;
7	100000	Yapi Kredi Bankasi	Yapi Kredi	Bank	\N	Istanbul	Turkey	1	2018-03-10 12:36:27.176374
8	200000	Yapi Kredi Bankasi2	Yapi Kredi2	Bank	\N	Istanbul	Turkey	1	2018-03-10 16:21:57.908626
10	200000	Yapi Kredi Bankasi3	Yapi Kredi3	Bank	\N	Istanbul	Turkey	1	2018-03-10 16:32:36.922313
2	\N	Is Bankasi	Is Bank	bank	\N	Istanbul	Turkey	5	2018-03-10 12:35:48.300008
1	0	Garanti Bankasi	Garanti	bank	\N	Istanbul	Turkey	1	2018-03-09 18:55:04.741104
11	200033	New Bank Co.	NBC	Bank	111 Main St.	Anytown	USA	1	2018-03-10 16:32:53.578021
\.


--
-- Name: clients_client_id_seq; Type: SEQUENCE SET; Schema: pd_dfsbenchmarking; Owner: joebrew
--

SELECT pg_catalog.setval('pd_dfsbenchmarking.clients_client_id_seq', 13, true);


--
-- Data for Name: users; Type: TABLE DATA; Schema: pd_dfsbenchmarking; Owner: joebrew
--

COPY pd_dfsbenchmarking.users (user_id, username, password, name, email, upi, can_login, last_login, session_id, is_admin) FROM stdin;
0	SYSTEM	SYSTEM	SYSTEM	\N	\N	f	\N	\N	f
3	test1	$1$aGstpxLZ$wmVnQLxF.70AMpQ51ftFN0	Soren test1	\N	\N	t	2018-03-10 07:46:08.379318	\N	f
4	test2	$1$YYIcDwCS$0cZ25s4EaWquXYvq96Cs9.	Soren test1	\N	\N	t	\N	\N	f
5	joe	$1$aTc/PFPD$d8mVat5rcZ/nSK3xXFjQy.	Joe Brew	\N	\N	t	2018-03-10 12:24:43.881231	81a1c607-6c92-44b7-aac9-3a39cd9b2573	f
1	MEL	$1$9FLfnwld$amkkGyaJvBpW3QT5VEzC6.	MEL Team	\N	\N	t	2018-03-11 11:11:59.72299	7be54672-6d2f-4ee7-b1ff-25a03a1e3f2c	f
\.


--
-- Name: users_user_id_seq; Type: SEQUENCE SET; Schema: pd_dfsbenchmarking; Owner: joebrew
--

SELECT pg_catalog.setval('pd_dfsbenchmarking.users_user_id_seq', 6, true);


--
-- Name: assessment_data_pkey; Type: CONSTRAINT; Schema: pd_dfsbenchmarking; Owner: joebrew
--

ALTER TABLE ONLY pd_dfsbenchmarking.assessment_data
    ADD CONSTRAINT assessment_data_pkey PRIMARY KEY (assessment_id, question_id, entry_time);


--
-- Name: assessment_question_categories_pkey; Type: CONSTRAINT; Schema: pd_dfsbenchmarking; Owner: joebrew
--

ALTER TABLE ONLY pd_dfsbenchmarking.assessment_question_categories
    ADD CONSTRAINT assessment_question_categories_pkey PRIMARY KEY (category_id);


--
-- Name: assessment_questions_pkey; Type: CONSTRAINT; Schema: pd_dfsbenchmarking; Owner: joebrew
--

ALTER TABLE ONLY pd_dfsbenchmarking.assessment_questions
    ADD CONSTRAINT assessment_questions_pkey PRIMARY KEY (question_id);


--
-- Name: assessments_client_id_assessment_date_key; Type: CONSTRAINT; Schema: pd_dfsbenchmarking; Owner: joebrew
--

ALTER TABLE ONLY pd_dfsbenchmarking.assessments
    ADD CONSTRAINT assessments_client_id_assessment_date_key UNIQUE (client_id, assessment_date);


--
-- Name: assessments_client_id_assessment_name_key; Type: CONSTRAINT; Schema: pd_dfsbenchmarking; Owner: joebrew
--

ALTER TABLE ONLY pd_dfsbenchmarking.assessments
    ADD CONSTRAINT assessments_client_id_assessment_name_key UNIQUE (client_id, assessment_name);


--
-- Name: assessments_pkey; Type: CONSTRAINT; Schema: pd_dfsbenchmarking; Owner: joebrew
--

ALTER TABLE ONLY pd_dfsbenchmarking.assessments
    ADD CONSTRAINT assessments_pkey PRIMARY KEY (assessment_id);


--
-- Name: clients_name_key; Type: CONSTRAINT; Schema: pd_dfsbenchmarking; Owner: joebrew
--

ALTER TABLE ONLY pd_dfsbenchmarking.clients
    ADD CONSTRAINT clients_name_key UNIQUE (name);


--
-- Name: clients_pkey; Type: CONSTRAINT; Schema: pd_dfsbenchmarking; Owner: joebrew
--

ALTER TABLE ONLY pd_dfsbenchmarking.clients
    ADD CONSTRAINT clients_pkey PRIMARY KEY (client_id);


--
-- Name: clients_short_name_key; Type: CONSTRAINT; Schema: pd_dfsbenchmarking; Owner: joebrew
--

ALTER TABLE ONLY pd_dfsbenchmarking.clients
    ADD CONSTRAINT clients_short_name_key UNIQUE (short_name);


--
-- Name: users_pkey; Type: CONSTRAINT; Schema: pd_dfsbenchmarking; Owner: joebrew
--

ALTER TABLE ONLY pd_dfsbenchmarking.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (user_id);


--
-- Name: assessment_data_assessment_id_question_id_entry_time_entry__idx; Type: INDEX; Schema: pd_dfsbenchmarking; Owner: joebrew
--

CREATE INDEX assessment_data_assessment_id_question_id_entry_time_entry__idx ON pd_dfsbenchmarking.assessment_data USING btree (assessment_id, question_id, entry_time, entry_user_id DESC);


--
-- Name: assessment_question_categories_category_name_idx; Type: INDEX; Schema: pd_dfsbenchmarking; Owner: joebrew
--

CREATE UNIQUE INDEX assessment_question_categories_category_name_idx ON pd_dfsbenchmarking.assessment_question_categories USING btree (category_name);


--
-- Name: users_username_idx; Type: INDEX; Schema: pd_dfsbenchmarking; Owner: joebrew
--

CREATE UNIQUE INDEX users_username_idx ON pd_dfsbenchmarking.users USING btree (username);


--
-- Name: view_client_listing _RETURN; Type: RULE; Schema: pd_dfsbenchmarking; Owner: joebrew
--

CREATE RULE "_RETURN" AS
    ON SELECT TO pd_dfsbenchmarking.view_client_listing DO INSTEAD  SELECT clients.created_by_user_id,
    clients.client_id,
    clients.ifc_client_id,
    COALESCE(clients.short_name, clients.name) AS name,
    clients.address,
    clients.city,
    clients.country,
    users.name AS created_by,
    count(DISTINCT assessments.assessment_id) AS assessments,
    COALESCE((max(assessments.assessment_date))::character varying, 'Never'::character varying) AS last_assessment
   FROM ((pd_dfsbenchmarking.clients
     JOIN pd_dfsbenchmarking.users ON ((users.user_id = clients.created_by_user_id)))
     LEFT JOIN pd_dfsbenchmarking.assessments ON ((assessments.client_id = clients.client_id)))
  GROUP BY clients.created_by_user_id, clients.client_id, clients.ifc_client_id, COALESCE(clients.short_name, clients.name), clients.city, clients.country, users.name
  ORDER BY clients.created_time DESC;

delete from public._pd_dfsbenchmarking_save_client_assessment_data;

--
-- PostgreSQL database dump complete
--

