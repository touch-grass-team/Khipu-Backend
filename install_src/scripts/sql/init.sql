CREATE SCHEMA syslog_ng.logs;
CREATE ROLE server_role;
CREATE ROLE client_role;
CREATE USER log_writer WITH ENCRYPTED PASSWORD 'server';
CREATE USER log_reader WITH ENCRYPTED PASSWORD 'client';


CREATE TABLE IF NOT EXISTS syslog_ng.logs.logs_info(
	_id SERIAL NOT NULL PRIMARY KEY,
	_timestamp timestamp without time zone NOT NULL,
	_level character varying(50),
	_user_name character varying(255) NOT NULL,
	_process_name character varying(255) NOT NULL,
	_pid integer NOT NULL,
	_message character varying NOT NULL
);


CREATE OR REPLACE FUNCTION syslog_ng.logs.prc_ins_logs_info(
	new_timestamp timestamp,
	new_level character varying(50),
	new_user_name character varying(255),
	new_process_name character varying(255),
	new_pid integer,
	new_message character varying)
RETURNS INTEGER AS
$BODY$
BEGIN
INSERT INTO syslog_ng.logs.logs_info("_timestamp","_level","_user_name","_process_name","_pid","_message")
VALUES (new_timestamp,new_level,new_user_name,new_process_name,new_pid,new_message);
RETURN 0;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

COMMENT ON FUNCTION syslog_ng.logs.prc_ins_logs_info(timestamp,character varying,character varying,character varying,integer,character varying) IS 'Вставляет данные данные о новой записи';

CREATE TYPE syslog_ng.logs.logs_file_info_type AS (
	_id integer,
	_timestamp timestamp,
	_level character varying(50),
	_user_name character varying(255),
	_process_name character varying(255),
	_pid integer,
	_message character varying);

GRANT USAGE ON SCHEMA logs TO server_role,client_role;
GRANT SELECT,INSERT,UPDATE,DELETE ON TABLE syslog_ng.logs.logs_info to server_role;
GRANT SELECT ON TABLE syslog_ng.logs.logs_info to client_role;

REVOKE ALL ON FUNCTION syslog_ng.logs.prc_ins_logs_info(timestamp,character varying,character varying,character varying,integer,character varying) FROM public;
GRANT EXECUTE ON FUNCTION syslog_ng.logs.prc_ins_logs_info(timestamp,character varying,character varying,character varying,integer,character varying) TO server_role;


GRANT SELECT,UPDATE ON SEQUENCE syslog_ng.logs.logs_info__id_seq TO server_role;

GRANT server_role to log_writer;
GRANT client_role to log_reader;
