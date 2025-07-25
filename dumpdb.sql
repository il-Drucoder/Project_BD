--
-- PostgreSQL database dump
--

-- Dumped from database version 14.17 (Homebrew)
-- Dumped by pg_dump version 14.17 (Homebrew)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: add_partecipante_hackathon(); Type: FUNCTION; Schema: public; Owner: alessiapicari
--

CREATE FUNCTION public.add_partecipante_hackathon() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE hackathon
    SET numiscritti = numiscritti + 1
    WHERE titolo = NEW.titolohackathon;
END;
$$;


ALTER FUNCTION public.add_partecipante_hackathon() OWNER TO alessiapicari;

--
-- Name: add_voto_assegnato_hackathon(); Type: FUNCTION; Schema: public; Owner: alessiapicari
--

CREATE FUNCTION public.add_voto_assegnato_hackathon() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE hackathon
    SET numvotiassegnati = numvotiassegnati + 1
    WHERE titolo = NEW.titolohackathon;
END;
$$;


ALTER FUNCTION public.add_voto_assegnato_hackathon() OWNER TO alessiapicari;

--
-- Name: check_datainserimento_valid(); Type: FUNCTION; Schema: public; Owner: alessiapicari
--

CREATE FUNCTION public.check_datainserimento_valid() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    datainizio DATE;
    datafine DATE;
BEGIN
    SELECT h.datainizio, h.datafine
    INTO datainizio, datafine
    FROM Hackathon h
    WHERE h.titolo = NEW.titolohackathon;
    IF NEW.datainserimento < datainizio OR NEW.datainserimento > datafine THEN
        RAISE EXCEPTION 'Non si deve inserire un documento prima che inizi la gara o dopo la sua fine';
    END IF;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.check_datainserimento_valid() OWNER TO alessiapicari;

--
-- Name: check_dim_max_team_hackathon(); Type: FUNCTION; Schema: public; Owner: alessiapicari
--

CREATE FUNCTION public.check_dim_max_team_hackathon() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    num_concorrenti INTEGER;
    dim_max_team INTEGER;
BEGIN
    SELECT COUNT(*)
    INTO num_concorrenti
    FROM concorrente_team
    WHERE titolohackathon = NEW.titolohackathon
    AND nometeam = NEW.nometeam;
    SELECT dimmaxteam
    INTO dim_max_team
    FROM hackathon
    WHERE titolo = NEW.titolohackathon;
    IF num_concorrenti >= dim_max_team THEN
        RAISE EXCEPTION 'Non si deve inserire un nuovo partecipante in questo team. Numero massimo di partecipanti per questo team raggiunto.';
    END IF;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.check_dim_max_team_hackathon() OWNER TO alessiapicari;

--
-- Name: check_inizioiscrizioni(); Type: FUNCTION; Schema: public; Owner: alessiapicari
--

CREATE FUNCTION public.check_inizioiscrizioni() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NEW.inizioiscrizioni < CURRENT_DATE + INTERVAL '1 day' THEN
        RAISE EXCEPTION 'Le iscrizioni devono iniziare almeno domani';
    END IF;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.check_inizioiscrizioni() OWNER TO alessiapicari;

--
-- Name: check_num_max_concorrenti_hackathon(); Type: FUNCTION; Schema: public; Owner: alessiapicari
--

CREATE FUNCTION public.check_num_max_concorrenti_hackathon() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    num_iscritti INTEGER;
    num_max_iscritti INTEGER;
BEGIN
    SELECT numiscritti, nummaxiscritti
    INTO num_iscritti, num_max_iscritti
    FROM hackathon
    WHERE titolo = NEW.titolohackathon;
    IF num_iscritti >= num_max_iscritti THEN
        RAISE EXCEPTION 'Non si deve inserire un nuovo partecipante in questo team. Numero massimo di partecipanti per questo Hackathon raggiunto.';
    END IF;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.check_num_max_concorrenti_hackathon() OWNER TO alessiapicari;

--
-- Name: check_unique_partecipazione_hackathon(); Type: FUNCTION; Schema: public; Owner: alessiapicari
--

CREATE FUNCTION public.check_unique_partecipazione_hackathon() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM concorrente_team ct
        WHERE ct.titolohackathon = NEW.titolohackathon
        AND ct.emailconcorrente = NEW.emailconcorrente
    ) THEN
        RAISE EXCEPTION 'Il partecipante gareggia in un team per questo Hackathon, quindi non deve iscriversi ad un altro team';
    END IF;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.check_unique_partecipazione_hackathon() OWNER TO alessiapicari;

--
-- Name: classifica_hackathon(text); Type: FUNCTION; Schema: public; Owner: alessiapicari
--

CREATE FUNCTION public.classifica_hackathon(titolo text) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
    risultato TEXT := '';
    r RECORD;
BEGIN
    FOR r IN (
        SELECT nometeam, AVG(valore) AS media
        FROM Voto
        WHERE titolohackathon = titolo
        GROUP BY nometeam
        ORDER BY media DESC
  )
    LOOP
        risultato := risultato || r.nometeam || ' ' || r.media || E'\n';
    END LOOP;
    risultato := RTRIM(risultato, ',');
    RETURN risultato;
END;
$$;


ALTER FUNCTION public.classifica_hackathon(titolo text) OWNER TO alessiapicari;

--
-- Name: documenti_team(text, text); Type: FUNCTION; Schema: public; Owner: alessiapicari
--

CREATE FUNCTION public.documenti_team(nomet text, titolo text) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
    risultato TEXT := '';
    doc RECORD;
BEGIN
    FOR doc IN (
        SELECT d.percorso
        FROM documento d
        WHERE d.nometeam = nomeT AND d.titolohackathon = titolo
        ORDER BY d.datainserimento
    )
    LOOP
        risultato := risultato || doc.percorso || E'\n';
    END LOOP;
    risultato := RTRIM(risultato, ', ');
    RETURN risultato;
END;
$$;


ALTER FUNCTION public.documenti_team(nomet text, titolo text) OWNER TO alessiapicari;

--
-- Name: media_voti_team(text); Type: FUNCTION; Schema: public; Owner: alessiapicari
--

CREATE FUNCTION public.media_voti_team(nome text) RETURNS numeric
    LANGUAGE plpgsql
    AS $$
DECLARE
    media NUMERIC;
BEGIN
    SELECT AVG(valore)
    INTO media
    FROM Voto
    WHERE nometeam = nome AND titolohackathon = nometeam.titoloHackathon;
    RETURN media;
END;
$$;


ALTER FUNCTION public.media_voti_team(nome text) OWNER TO alessiapicari;

--
-- Name: media_voti_team(text, text); Type: FUNCTION; Schema: public; Owner: alessiapicari
--

CREATE FUNCTION public.media_voti_team(nome text, titolo text) RETURNS numeric
    LANGUAGE plpgsql
    AS $$
DECLARE
    media NUMERIC;
BEGIN
    SELECT AVG(valore)
    INTO media
    FROM Voto
    WHERE nometeam = nome AND titolohackathon = titolo;
    RETURN media;
END;
$$;


ALTER FUNCTION public.media_voti_team(nome text, titolo text) OWNER TO alessiapicari;

--
-- Name: partecipanti_hackathon(text); Type: FUNCTION; Schema: public; Owner: alessiapicari
--

CREATE FUNCTION public.partecipanti_hackathon(titolo text) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
    risultato TEXT := '';
    part RECORD;
BEGIN
    FOR part IN
        SELECT c.nome, c.cognome, ct.emailconcorrente
        FROM concorrente_team ct
        INNER JOIN concorrente c ON c.email = ct.emailconcorrente
        WHERE ct.titolohackathon = titolo
    LOOP
        risultato := risultato || part.nome || ' ' || part.cognome || ' ' || part.emailconcorrente || E'\n';
    END LOOP;
    risultato:= RTRIM(risultato, ', ');
    RETURN risultato;
END;
$$;


ALTER FUNCTION public.partecipanti_hackathon(titolo text) OWNER TO alessiapicari;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: commento; Type: TABLE; Schema: public; Owner: alessiapicari
--

CREATE TABLE public.commento (
    emailgiudice character varying(150) NOT NULL,
    iddocumento integer NOT NULL,
    commento character varying(50) NOT NULL
);


ALTER TABLE public.commento OWNER TO alessiapicari;

--
-- Name: concorrente; Type: TABLE; Schema: public; Owner: alessiapicari
--

CREATE TABLE public.concorrente (
    email character varying(150) NOT NULL,
    nome character varying(50),
    cognome character varying(50),
    pw character varying(255)
);


ALTER TABLE public.concorrente OWNER TO alessiapicari;

--
-- Name: concorrente_team; Type: TABLE; Schema: public; Owner: alessiapicari
--

CREATE TABLE public.concorrente_team (
    emailconcorrente character varying(150) NOT NULL,
    nometeam character varying(50) NOT NULL,
    titolohackathon character varying(100) NOT NULL
);


ALTER TABLE public.concorrente_team OWNER TO alessiapicari;

--
-- Name: convocazione; Type: TABLE; Schema: public; Owner: alessiapicari
--

CREATE TABLE public.convocazione (
    emailorganizzatore character varying(150) NOT NULL,
    emailgiudice character varying(150) NOT NULL,
    titolohackathon character varying(50) NOT NULL
);


ALTER TABLE public.convocazione OWNER TO alessiapicari;

--
-- Name: documento; Type: TABLE; Schema: public; Owner: alessiapicari
--

CREATE TABLE public.documento (
    iddocumento integer NOT NULL,
    percorso character varying(100),
    nometeam character varying(50) NOT NULL,
    titolohackathon character varying(100) NOT NULL,
    datainserimento date,
    nome character varying(100)
);


ALTER TABLE public.documento OWNER TO alessiapicari;

--
-- Name: giudice; Type: TABLE; Schema: public; Owner: alessiapicari
--

CREATE TABLE public.giudice (
    email character varying(150) NOT NULL,
    nome character varying(50),
    cognome character varying(50),
    pw character varying(255)
);


ALTER TABLE public.giudice OWNER TO alessiapicari;

--
-- Name: hackathon; Type: TABLE; Schema: public; Owner: alessiapicari
--

CREATE TABLE public.hackathon (
    titolo character varying(100) NOT NULL,
    datainizio date,
    datafine date,
    nummaxiscritti integer,
    dimmaxteam integer,
    inizioiscrizioni date,
    fineiscrizioni date,
    descrizioneproblema character varying(250),
    classifica character varying(500),
    indirizzosede character varying(50),
    creatore character varying(50),
    numiscritti integer,
    numvotiassegnati integer,
    CONSTRAINT chk_durata CHECK ((datafine >= datainizio)),
    CONSTRAINT chk_iscrizioni CHECK ((fineiscrizioni >= inizioiscrizioni)),
    CONSTRAINT chk_nummaxiscritti CHECK ((nummaxiscritti > 1)),
    CONSTRAINT chk_tempoiscrizioni CHECK ((datainizio > (fineiscrizioni + '2 days'::interval)))
);


ALTER TABLE public.hackathon OWNER TO alessiapicari;

--
-- Name: organizzatore; Type: TABLE; Schema: public; Owner: alessiapicari
--

CREATE TABLE public.organizzatore (
    email character varying(150) NOT NULL,
    nome character varying(50),
    cognome character varying(50),
    pw character varying(255)
);


ALTER TABLE public.organizzatore OWNER TO alessiapicari;

--
-- Name: team; Type: TABLE; Schema: public; Owner: alessiapicari
--

CREATE TABLE public.team (
    nome character varying(50) NOT NULL,
    titolohackathon character varying(100) NOT NULL,
    pw character varying(255) NOT NULL,
    creatore character varying(50)
);


ALTER TABLE public.team OWNER TO alessiapicari;

--
-- Name: voto; Type: TABLE; Schema: public; Owner: alessiapicari
--

CREATE TABLE public.voto (
    emailgiudice character varying(150) NOT NULL,
    nometeam character varying(50) NOT NULL,
    titolohackathon character varying(100) NOT NULL,
    valore integer NOT NULL,
    CONSTRAINT voto_check CHECK (((valore >= 0) AND (valore <= 10)))
);


ALTER TABLE public.voto OWNER TO alessiapicari;

--
-- Data for Name: commento; Type: TABLE DATA; Schema: public; Owner: alessiapicari
--

COPY public.commento (emailgiudice, iddocumento, commento) FROM stdin;
ag@giudice.com	1	non male!(Aurora Gallo)
ag@giudice.com	1	ok!(Aurora Gallo)
ag@giudice.com	2	ok(Aurora Gallo)
ag@giudice.com	2	bello!(Aurora Gallo)
\.


--
-- Data for Name: concorrente; Type: TABLE DATA; Schema: public; Owner: alessiapicari
--

COPY public.concorrente (email, nome, cognome, pw) FROM stdin;
ac@concorrente.com	Alessio	Conti	1
bc@concorrente.com	Beatrice	Colombo	1
cc@concorrente.com	Chiara	Caruso	1
dc@concorrente.com	Davide	Cattaneo	1
ec@concorrente.com	Elisa	Corsi	1
fc@concorrente.com	Federico	Caputo	1
gc@concorrente.com	Giorgia	Cioffi	1
hc@concorrente.com	Harry	Cirelli	1
ic@concorrente.com	Ivan	Cassano	1
jc@concorrente.com	Jessica	Cavedoni	1
\.


--
-- Data for Name: concorrente_team; Type: TABLE DATA; Schema: public; Owner: alessiapicari
--

COPY public.concorrente_team (emailconcorrente, nometeam, titolohackathon) FROM stdin;
ac@concorrente.com	Team 1	Hackathon 3
bc@concorrente.com	Team 2	Hackathon 3
cc@concorrente.com	Team 3	Hackathon 3
dc@concorrente.com	Team 4	Hackathon 3
ec@concorrente.com	Team 1	Hackathon 3
fc@concorrente.com	Team 2	Hackathon 3
gc@concorrente.com	Team 3	Hackathon 3
hc@concorrente.com	Team 4	Hackathon 3
jc@concorrente.com	Team 2	Hackathon 3
ac@concorrente.com	Team 1	Hackathon 4
bc@concorrente.com	Team 2	Hackathon 4
cc@concorrente.com	Team 3	Hackathon 4
dc@concorrente.com	Team 4	Hackathon 4
ec@concorrente.com	Team 1	Hackathon 4
fc@concorrente.com	Team 2	Hackathon 4
gc@concorrente.com	Team 3	Hackathon 4
hc@concorrente.com	Team 4	Hackathon 4
jc@concorrente.com	Team 2	Hackathon 4
ac@concorrente.com	Team 1	Hackathon 5
bc@concorrente.com	Team 2	Hackathon 5
cc@concorrente.com	Team 3	Hackathon 5
dc@concorrente.com	Team 4	Hackathon 5
ec@concorrente.com	Team 1	Hackathon 5
fc@concorrente.com	Team 2	Hackathon 5
gc@concorrente.com	Team 3	Hackathon 5
hc@concorrente.com	Team 4	Hackathon 5
jc@concorrente.com	Team 2	Hackathon 5
ac@concorrente.com	Team 1	Hackathon 6
bc@concorrente.com	Team 2	Hackathon 6
cc@concorrente.com	Team 3	Hackathon 6
dc@concorrente.com	Team 4	Hackathon 6
ec@concorrente.com	Team 1	Hackathon 6
fc@concorrente.com	Team 2	Hackathon 6
gc@concorrente.com	Team 3	Hackathon 6
hc@concorrente.com	Team 4	Hackathon 6
jc@concorrente.com	Team 2	Hackathon 6
ac@concorrente.com	Team 5	Hackathon 2
bc@concorrente.com	Team 5	Hackathon 2
ic@concorrente.com	Team 1	Hackathon 3
ic@concorrente.com	Team 1	Hackathon 4
ic@concorrente.com	Team 1	Hackathon 5
ic@concorrente.com	Team 1	Hackathon 6
dc@concorrente.com	Team 6	Hackathon 2
gc@concorrente.com	Team 7	Hackathon 2
\.


--
-- Data for Name: convocazione; Type: TABLE DATA; Schema: public; Owner: alessiapicari
--

COPY public.convocazione (emailorganizzatore, emailgiudice, titolohackathon) FROM stdin;
ao@organizzatore.com	ag@giudice.com	Hackathon 2
ao@organizzatore.com	bg@giudice.com	Hackathon 2
ao@organizzatore.com	cg@giudice.com	Hackathon 2
ao@organizzatore.com	dg@giudice.com	Hackathon 2
ao@organizzatore.com	eg@giudice.com	Hackathon 2
ao@organizzatore.com	ag@giudice.com	Hackathon 3
ao@organizzatore.com	bg@giudice.com	Hackathon 3
ao@organizzatore.com	cg@giudice.com	Hackathon 3
ao@organizzatore.com	dg@giudice.com	Hackathon 3
ao@organizzatore.com	eg@giudice.com	Hackathon 3
bo@organizzatore.com	ag@giudice.com	Hackathon 4
bo@organizzatore.com	bg@giudice.com	Hackathon 4
bo@organizzatore.com	cg@giudice.com	Hackathon 4
bo@organizzatore.com	dg@giudice.com	Hackathon 4
bo@organizzatore.com	eg@giudice.com	Hackathon 4
bo@organizzatore.com	ag@giudice.com	Hackathon 5
bo@organizzatore.com	bg@giudice.com	Hackathon 5
bo@organizzatore.com	cg@giudice.com	Hackathon 5
bo@organizzatore.com	dg@giudice.com	Hackathon 5
bo@organizzatore.com	eg@giudice.com	Hackathon 5
bo@organizzatore.com	ag@giudice.com	Hackathon 6
bo@organizzatore.com	bg@giudice.com	Hackathon 6
\.


--
-- Data for Name: documento; Type: TABLE DATA; Schema: public; Owner: alessiapicari
--

COPY public.documento (iddocumento, percorso, nometeam, titolohackathon, datainserimento, nome) FROM stdin;
1	/Users/alessiapicari/Desktop/Project db.pdf	Team 1	Hackathon 4	2025-07-08	Project db
2	/Users/alessiapicari/Desktop/Project Hackathon Database.pdf	Team 1	Hackathon 4	2025-07-09	Project Hackathon Database
\.


--
-- Data for Name: giudice; Type: TABLE DATA; Schema: public; Owner: alessiapicari
--

COPY public.giudice (email, nome, cognome, pw) FROM stdin;
ag@giudice.com	Aurora	Gallo	1
bg@giudice.com	Bruno	Greco	1
cg@giudice.com	Carlo	Giordano	1
dg@giudice.com	Dora	Gatti	1
eg@giudice.com	Emanuele	Grassi	1
\.


--
-- Data for Name: hackathon; Type: TABLE DATA; Schema: public; Owner: alessiapicari
--

COPY public.hackathon (titolo, datainizio, datafine, nummaxiscritti, dimmaxteam, inizioiscrizioni, fineiscrizioni, descrizioneproblema, classifica, indirizzosede, creatore, numiscritti, numvotiassegnati) FROM stdin;
Hackathon 1	2025-08-05	2025-08-07	100	3	2025-08-01	2025-08-02	\N	\N	Via Roma, 15 – 00185 Roma (RM)	ao@organizzatore.com	0	0
Hackathon 4	2025-07-07	2025-08-01	100	3	2025-07-03	2025-07-04	Rivoluziona la mobilità urbana con soluzioni green.	\N	Piazza San Marco, 3 – 30124 Venezia (VE)	bo@organizzatore.com	10	0
Hackathon 5	2025-07-05	2025-07-06	100	3	2025-07-01	2025-07-02	Soluzioni digitali per cibo sostenibile	\N	Via Toledo, 89 – 80134 Napoli (NA)	bo@organizzatore.com	10	0
Hackathon 3	2025-08-01	2025-08-03	100	3	2025-07-05	2025-07-06	\N	\N	Via Dante Alighieri, 27 – 50121 Firenze (FI)	ao@organizzatore.com	10	0
Hackathon 6	2025-07-05	2025-07-06	100	3	2025-07-01	2025-07-02	Migliora la raccolta differenziata con tech innovativa.	[1\t| 10.0\t| Team 1, 2\t| 7.5\t| Team 2, 2\t| 7.5\t| Team 3, 4\t| 7.0\t| Team 4]	Viale della Libertà, 56 – 90143 Palermo (PA)	bo@organizzatore.com	10	8
Hackathon 2	2025-08-04	2025-08-05	8	3	2025-07-07	2025-08-01	\N	\N	Corso Garibaldi, 102 – 20121 Milano (MI)	ao@organizzatore.com	4	0
\.


--
-- Data for Name: organizzatore; Type: TABLE DATA; Schema: public; Owner: alessiapicari
--

COPY public.organizzatore (email, nome, cognome, pw) FROM stdin;
ao@organizzatore.com	Andrea	Orsini	1
bo@organizzatore.com	Bianca	Olivieri	1
\.


--
-- Data for Name: team; Type: TABLE DATA; Schema: public; Owner: alessiapicari
--

COPY public.team (nome, titolohackathon, pw, creatore) FROM stdin;
Team 1	Hackathon 3	2	ac@concorrente.com
Team 2	Hackathon 3	2	bc@concorrente.com
Team 3	Hackathon 3	2	cc@concorrente.com
Team 4	Hackathon 3	2	dc@concorrente.com
Team 1	Hackathon 4	2	ac@concorrente.com
Team 2	Hackathon 4	2	bc@concorrente.com
Team 3	Hackathon 4	2	cc@concorrente.com
Team 4	Hackathon 4	2	dc@concorrente.com
Team 1	Hackathon 5	2	ac@concorrente.com
Team 2	Hackathon 5	2	bc@concorrente.com
Team 3	Hackathon 5	2	cc@concorrente.com
Team 4	Hackathon 5	2	dc@concorrente.com
Team 1	Hackathon 6	2	ac@concorrente.com
Team 2	Hackathon 6	2	bc@concorrente.com
Team 3	Hackathon 6	2	cc@concorrente.com
Team 4	Hackathon 6	2	dc@concorrente.com
Team 5	Hackathon 2	2	ac@concorrente.com
Team 6	Hackathon 2	2	dc@concorrente.com
Team 7	Hackathon 2	2	gc@concorrente.com
\.


--
-- Data for Name: voto; Type: TABLE DATA; Schema: public; Owner: alessiapicari
--

COPY public.voto (emailgiudice, nometeam, titolohackathon, valore) FROM stdin;
ag@giudice.com	Team 1	Hackathon 6	10
bg@giudice.com	Team 1	Hackathon 6	10
ag@giudice.com	Team 2	Hackathon 6	8
bg@giudice.com	Team 2	Hackathon 6	7
ag@giudice.com	Team 3	Hackathon 6	7
bg@giudice.com	Team 3	Hackathon 6	8
ag@giudice.com	Team 4	Hackathon 6	9
bg@giudice.com	Team 4	Hackathon 6	5
\.


--
-- Name: commento commento_pkey; Type: CONSTRAINT; Schema: public; Owner: alessiapicari
--

ALTER TABLE ONLY public.commento
    ADD CONSTRAINT commento_pkey PRIMARY KEY (emailgiudice, iddocumento, commento);


--
-- Name: concorrente concorrente_pkey; Type: CONSTRAINT; Schema: public; Owner: alessiapicari
--

ALTER TABLE ONLY public.concorrente
    ADD CONSTRAINT concorrente_pkey PRIMARY KEY (email);


--
-- Name: documento documento_pkey; Type: CONSTRAINT; Schema: public; Owner: alessiapicari
--

ALTER TABLE ONLY public.documento
    ADD CONSTRAINT documento_pkey PRIMARY KEY (iddocumento);


--
-- Name: giudice giudice_pkey; Type: CONSTRAINT; Schema: public; Owner: alessiapicari
--

ALTER TABLE ONLY public.giudice
    ADD CONSTRAINT giudice_pkey PRIMARY KEY (email);


--
-- Name: hackathon hackathon_pkey; Type: CONSTRAINT; Schema: public; Owner: alessiapicari
--

ALTER TABLE ONLY public.hackathon
    ADD CONSTRAINT hackathon_pkey PRIMARY KEY (titolo);


--
-- Name: organizzatore organizzatore_pkey; Type: CONSTRAINT; Schema: public; Owner: alessiapicari
--

ALTER TABLE ONLY public.organizzatore
    ADD CONSTRAINT organizzatore_pkey PRIMARY KEY (email);


--
-- Name: concorrente_team pk_concorrente_team; Type: CONSTRAINT; Schema: public; Owner: alessiapicari
--

ALTER TABLE ONLY public.concorrente_team
    ADD CONSTRAINT pk_concorrente_team PRIMARY KEY (emailconcorrente, nometeam, titolohackathon);


--
-- Name: convocazione pk_convocazione; Type: CONSTRAINT; Schema: public; Owner: alessiapicari
--

ALTER TABLE ONLY public.convocazione
    ADD CONSTRAINT pk_convocazione PRIMARY KEY (emailorganizzatore, emailgiudice, titolohackathon);


--
-- Name: team pk_team; Type: CONSTRAINT; Schema: public; Owner: alessiapicari
--

ALTER TABLE ONLY public.team
    ADD CONSTRAINT pk_team PRIMARY KEY (nome, titolohackathon);


--
-- Name: voto pk_voto; Type: CONSTRAINT; Schema: public; Owner: alessiapicari
--

ALTER TABLE ONLY public.voto
    ADD CONSTRAINT pk_voto PRIMARY KEY (emailgiudice, nometeam, titolohackathon);


--
-- Name: concorrente_team trg_add_partecipante_hackathon; Type: TRIGGER; Schema: public; Owner: alessiapicari
--

CREATE TRIGGER trg_add_partecipante_hackathon AFTER INSERT ON public.concorrente_team FOR EACH ROW EXECUTE FUNCTION public.add_partecipante_hackathon();


--
-- Name: voto trg_add_voto_assegnato_hackathon; Type: TRIGGER; Schema: public; Owner: alessiapicari
--

CREATE TRIGGER trg_add_voto_assegnato_hackathon AFTER INSERT ON public.voto FOR EACH ROW EXECUTE FUNCTION public.add_voto_assegnato_hackathon();


--
-- Name: concorrente_team trg_check_dim_max_team_hackathon; Type: TRIGGER; Schema: public; Owner: alessiapicari
--

CREATE TRIGGER trg_check_dim_max_team_hackathon BEFORE INSERT ON public.concorrente_team FOR EACH ROW EXECUTE FUNCTION public.check_dim_max_team_hackathon();


--
-- Name: concorrente_team trg_check_num_max_concorrenti_hackathon; Type: TRIGGER; Schema: public; Owner: alessiapicari
--

CREATE TRIGGER trg_check_num_max_concorrenti_hackathon BEFORE INSERT ON public.concorrente_team FOR EACH ROW EXECUTE FUNCTION public.check_num_max_concorrenti_hackathon();


--
-- Name: concorrente_team trg_check_unique_partecipante; Type: TRIGGER; Schema: public; Owner: alessiapicari
--

CREATE TRIGGER trg_check_unique_partecipante BEFORE INSERT ON public.concorrente_team FOR EACH ROW EXECUTE FUNCTION public.check_unique_partecipazione_hackathon();


--
-- Name: documento trigger_check_datainserimento_valid; Type: TRIGGER; Schema: public; Owner: alessiapicari
--

CREATE TRIGGER trigger_check_datainserimento_valid BEFORE INSERT OR UPDATE ON public.documento FOR EACH ROW EXECUTE FUNCTION public.check_datainserimento_valid();


--
-- Name: hackathon trigger_check_inizioiscrizioni; Type: TRIGGER; Schema: public; Owner: alessiapicari
--

CREATE TRIGGER trigger_check_inizioiscrizioni BEFORE INSERT OR UPDATE ON public.hackathon FOR EACH ROW EXECUTE FUNCTION public.check_inizioiscrizioni();


--
-- Name: concorrente_team fk_concorrente_emailconcorrente; Type: FK CONSTRAINT; Schema: public; Owner: alessiapicari
--

ALTER TABLE ONLY public.concorrente_team
    ADD CONSTRAINT fk_concorrente_emailconcorrente FOREIGN KEY (emailconcorrente) REFERENCES public.concorrente(email) ON DELETE CASCADE;


--
-- Name: concorrente_team fk_concorrente_team; Type: FK CONSTRAINT; Schema: public; Owner: alessiapicari
--

ALTER TABLE ONLY public.concorrente_team
    ADD CONSTRAINT fk_concorrente_team FOREIGN KEY (nometeam, titolohackathon) REFERENCES public.team(nome, titolohackathon);


--
-- Name: convocazione fk_convocazione_giudice; Type: FK CONSTRAINT; Schema: public; Owner: alessiapicari
--

ALTER TABLE ONLY public.convocazione
    ADD CONSTRAINT fk_convocazione_giudice FOREIGN KEY (emailgiudice) REFERENCES public.giudice(email) ON DELETE CASCADE;


--
-- Name: convocazione fk_convocazione_hackathon; Type: FK CONSTRAINT; Schema: public; Owner: alessiapicari
--

ALTER TABLE ONLY public.convocazione
    ADD CONSTRAINT fk_convocazione_hackathon FOREIGN KEY (titolohackathon) REFERENCES public.hackathon(titolo);


--
-- Name: convocazione fk_convocazione_organizzatore; Type: FK CONSTRAINT; Schema: public; Owner: alessiapicari
--

ALTER TABLE ONLY public.convocazione
    ADD CONSTRAINT fk_convocazione_organizzatore FOREIGN KEY (emailorganizzatore) REFERENCES public.organizzatore(email) ON DELETE CASCADE;


--
-- Name: commento fk_icommento_giudice; Type: FK CONSTRAINT; Schema: public; Owner: alessiapicari
--

ALTER TABLE ONLY public.commento
    ADD CONSTRAINT fk_icommento_giudice FOREIGN KEY (emailgiudice) REFERENCES public.giudice(email) ON DELETE CASCADE;


--
-- Name: team fk_team_hackathon; Type: FK CONSTRAINT; Schema: public; Owner: alessiapicari
--

ALTER TABLE ONLY public.team
    ADD CONSTRAINT fk_team_hackathon FOREIGN KEY (titolohackathon) REFERENCES public.hackathon(titolo);


--
-- Name: voto fk_voto_giudice; Type: FK CONSTRAINT; Schema: public; Owner: alessiapicari
--

ALTER TABLE ONLY public.voto
    ADD CONSTRAINT fk_voto_giudice FOREIGN KEY (emailgiudice) REFERENCES public.giudice(email) ON DELETE CASCADE;


--
-- Name: voto fk_voto_team; Type: FK CONSTRAINT; Schema: public; Owner: alessiapicari
--

ALTER TABLE ONLY public.voto
    ADD CONSTRAINT fk_voto_team FOREIGN KEY (nometeam, titolohackathon) REFERENCES public.team(nome, titolohackathon);


--
-- PostgreSQL database dump complete
--

