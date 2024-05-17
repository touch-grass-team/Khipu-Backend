CREATE SCHEMA IF NOT EXISTS logs AUTHORIZATION postgres;

CREATE TABLE IF NOT EXISTS logs.log_file_info(
        id SERIAL PRIMARY KEY,
        name VARCHAR(255) NOT NULL,
        time_stamp timestamp NOT NULL,
        path varchar(255) NOT NULL);

CREATE TABLE IF NOT EXISTS  logs.services_info(
        id SERIAL PRIMARY KEY,
        name VARCHAR(255) NOT NULL);

CREATE TABLE IF NOT EXISTS logs.service_id_log_file_id(
        service_id int NOT NULL, 
        CONSTRAINT fk_service
          FOREIGN KEY (service_id) 
           REFERENCES logs.services_info(id),
        log_file_id int NOT NULL,
        CONSTRAINT fk_log_file
          FOREIGN KEY(log_file_id)
           REFERENCES logs.log_file_info(id));

CREATE TABLE IF NOT EXISTS logs.levels_for_logs(
        log_file_id int NOT NULL,
        CONSTRAINT fk_log_file
          FOREIGN KEY(log_file_id)
            REFERENCES logs.log_file_info(id),
        level int NOT NULL
        CONSTRAINT level_in_bounds CHECK(level >= 0 AND level <= 4));

--insert functions

CREATE OR REPLACE FUNCTION logs.insert_log_file_info (
	new_name varchar(255),
       	new_time_stamp timestamp, 
	new_path varchar(255))
  RETURNS int AS 
$BODY$
DECLARE
new_id int;
BEGIN
INSERT INTO logs.log_file_info VALUES (new_name,new_time_stamp,new_path) RETURNING "id" INTO new_id;
RETURN new_id;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

CREATE OR REPLACE FUNCTION logs.insert_levels_for_logs(
	new_log_file_id int,
	new_level int)
  RETURNS int AS 
$BODY$
BEGIN
INSERT INTO logs.levels_for_logs VALUES (new_log_file_id, new_level);
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

CREATE OR REPLACE FUNCTION logs.insert_services_info(
	new_id int,
	new_name varchar(255))
  RETURNS int AS
$BODY$
DECLARE
cur_id int;
BEGIN
IF NOT EXISTS (SELECT logs.services_info.id FROM logs.services_info WHERE id=new_id) THEN
	INSERT INTO logs.services_info VALUES (new_name) RETURNING "id" INTO cur_id;
ELSE
	cur_id = 0;
END IF;
RETURN cur_id;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

CREATE OR REPLACE FUNCTION logs.insert_service_id_log_file_id(
	new_service_id int,
	new_log_file_id int,
  RETURNS int AS
$BODY$
BEGIN
INSERT INTO logs.insert_service_id_log_file_id VALUES (new_service_id,new_log_file_id);
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

CREATE ROLE logwriter WITH LOGIN;
GRANT CONNECT ON DATABASE syslog_ng TO logwriter;
REVOKE ALL ON public FROM logwriter;
ALTER ROLE logwriter SET search_path TO logs;
GRANT USAGE ON SCHEMA logs TO logwriter;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA logs TO logwriter;

CREATE ROLE logreader WITH LOGIN;
GRANT CONNECT ON DATABASE syslog_ng TO logreader;
REVOKE ALL ON public FROM logreader;
ALTER ROLE logreader SET search_path TO logs;
GRANT USAGE ON SCHEMA logs TO logreader;
GRANT SELECT ON ALL TABLES IN SCHEMA logs TO logreader;


