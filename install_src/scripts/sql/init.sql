CREATE SCHEMA logs;
ALTER DATABASE syslog_ng SET search_path TO logs;
CREATE ROLE server_role;
CREATE ROLE client_role;
CREATE USER log_writer WITH ENCRYPTED PASSWORD 'server' INHERIT;
CREATE USER log_reader WITH ENCRYPTED PASSWORD 'client' INHERIT;


CREATE TABLE IF NOT EXISTS syslog_ng.logs.logs_info(
	_id SERIAL NOT NULL PRIMARY KEY,
	_timestamp timestamp without time zone NOT NULL,
	_level character varying(50),
	_user_name character varying(255) NOT NULL,
	_process_name character varying(255) NOT NULL,
	_pid integer,
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

GRANT USAGE ON SCHEMA logs TO server_role,client_role WITH GRANT OPTION;
GRANT SELECT,INSERT,UPDATE,DELETE ON TABLE syslog_ng.logs.logs_info to server_role WITH GRANT OPTION;
GRANT SELECT ON TABLE syslog_ng.logs.logs_info to client_role WITH GRANT OPTION;
GRANT TEMP ON DATABASE syslog_ng TO client_role WITH GRANT OPTION;

REVOKE ALL ON FUNCTION syslog_ng.logs.prc_ins_logs_info(timestamp,character varying,character varying,character varying,integer,character varying) FROM public;
GRANT EXECUTE ON FUNCTION syslog_ng.logs.prc_ins_logs_info(timestamp,character varying,character varying,character varying,integer,character varying) TO server_role WITH GRANT OPTION;


GRANT SELECT,UPDATE ON SEQUENCE syslog_ng.logs.logs_info__id_seq TO server_role WITH GRANT OPTION;

GRANT server_role to log_writer;
GRANT client_role to log_reader;

CREATE OR REPLACE FUNCTION syslog_ng.logs.select_logs_info_with_filter(
	f_bot_timestamp timestamp,
	f_ceil_timestamp timestamp,
	f_level character varying(50),
	f_user_name character varying(255),
	f_process_name character varying(255))
RETURNS TABLE(log syslog_ng.logs.logs_file_info_type) AS
$BODY$
BEGIN
CREATE TEMP TABLE res_table OF syslog_ng.logs.logs_file_info_type ON COMMIT DROP;
INSERT INTO res_table SELECT * FROM syslog_ng.logs.logs_info;
IF f_bot_timestamp IS NOT NULL AND f_ceil_timestamp IS NOT NULL THEN
  DELETE
  FROM res_table
  WHERE _timestamp NOT BETWEEN f_bot_timestamp AND f_ceil_timestamp;
END IF;

IF f_level IS NOT NULL THEN
  DELETE
  FROM res_table
  WHERE _level<>f_level;
END IF;

IF f_user_name IS NOT NULL THEN
  DELETE
  FROM res_table
  WHERE _user_name<>f_user_name;
END IF;

IF f_process_name IS NOT NULL THEN
  DELETE
  FROM res_table
  WHERE _process_name<>f_process_name;
END IF;
RETURN QUERY SELECT * FROM res_table;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

COMMENT ON FUNCTION syslog_ng.logs.select_logs_info_with_filter(
	timestamp,
	timestamp,
	character varying,
	character varying,
	character varying) IS 'Returns filtered logs';

CREATE OR REPLACE FUNCTION logs.prc_get_logs_by_time(
	need_time timestamp)
RETURNS SETOF logs.type_logs_info AS
$BODY$
SELECT * FROM logs.logs_info WHERE "_timestamp" >= need_time ORDER BY "_timestamp"
$BODY$
 LANGUAGE sql
 COST 100
 ROWS 1000;

COMMENT ON FUNCTION logs.prc_get_logs_by_time(timestamp) IS 'Возращает логи, >= заданному времени';

CREATE OR REPLACE FUNCTION syslog_ng.logs.select_n_filtered_logs_ordered_by_time(
	asc_order boolean,
	number_of_logs integer,
	f_bot_timestamp timestamp,
	f_ceil_timestamp timestamp,
	f_level character varying(50),
	f_user_name character varying(255),
	f_process_name character varying(255))
RETURNS TABLE(log syslog_ng.logs.logs_file_info_type) AS
$BODY$
BEGIN
IF asc_order IS NULL THEN
	RAISE EXCEPTION 'asc_order cannot be NULL';
END IF;

IF number_of_logs < 0 THEN
	RAISE EXCEPTION 'Number_of_logs cannot be less than 0';
END IF;

CREATE TEMP TABLE res_asc OF syslog_ng.logs.logs_file_info_type ON COMMIT DROP;
INSERT INTO res_asc
	SELECT *
	FROM syslog_ng.logs.select_logs_info_with_filter(
	  f_bot_timestamp,
	  f_ceil_timestamp,
	  f_level,
	  f_user_name,
	  f_process_name)
	ORDER BY
	  CASE WHEN asc_order=TRUE THEN _timestamp END ASC,
	  CASE WHEN asc_order=FALSE THEN _timestamp END DESC
	LIMIT CASE WHEN number_of_logs IS NOT NULL 
	  THEN number_of_logs END;
RETURN QUERY SELECT * FROM res_asc;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

COMMENT ON FUNCTION syslog_ng.logs.select_n_filtered_logs_ordered_by_time(
	boolean,
	integer,
	timestamp,
	timestamp,
	character varying,
	character varying,
	character varying) IS 'Returns n logs arranged by time asc/desc';


CREATE OR REPLACE FUNCTION syslog_ng.logs.get_stat_table_of_warnings(
	f_bot_timestamp timestamp,
	f_ceil_timestamp timestamp,
	f_user_name character varying(255),
	f_process_name character varying(255))
RETURNS TABLE(level character varying(50), num_of_appearance int) AS
$BODY$
BEGIN
CREATE TEMP TABLE res_asc(level character varying(50),num_of_appearance int) ON COMMIT DROP;
INSERT INTO res_asc
	SELECT _level,COUNT(*)
	FROM syslog_ng.logs.select_logs_info_with_filter(
	  f_bot_timestamp,
	  f_ceil_timestamp,
	  null,
	  f_user_name,
	  f_process_name)
	GROUP BY _level;
RETURN QUERY SELECT * FROM res_asc;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;


COMMENT ON FUNCTION syslog_ng.logs.get_stat_table_of_warnings(
	timestamp,
	timestamp,
	character varying,
	character varying) IS 'Returns number of logs grouped by level';


CREATE OR REPLACE FUNCTION syslog_ng.logs.get_n_messages(
	asc_order boolean,
	number_of_logs integer,
	f_bot_timestamp timestamp,
	f_ceil_timestamp timestamp,
	f_level character varying(50),
	f_user_name character varying(255),
	f_process_name character varying(255))
RETURNS TABLE(message character varying, num_of_appear integer) AS
$BODY$
BEGIN
IF asc_order IS NULL THEN
	RAISE EXCEPTION 'asc_order cannot be NULL';
END IF;

IF number_of_logs < 0 THEN
	RAISE EXCEPTION 'Number_of_logs cannot be less than 0';
END IF;

CREATE TEMP TABLE res_asc (log_message character varying, num_of_appearance integer) ON COMMIT DROP;
INSERT INTO res_asc
	SELECT _message,COUNT(*)
	FROM syslog_ng.logs.select_logs_info_with_filter(
	  f_bot_timestamp,
	  f_ceil_timestamp,
	  f_level,
	  f_user_name,
	  f_process_name)
	GROUP BY
	  _message;
RETURN QUERY 
	SELECT * 
	FROM res_asc
	ORDER BY
	  CASE WHEN asc_order=TRUE THEN num_of_appearance END ASC,
	  CASE WHEN asc_order=FALSE THEN num_of_appearance END DESC
        LIMIT CASE WHEN number_of_logs IS NOT NULL 
          THEN number_of_logs END;	
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

