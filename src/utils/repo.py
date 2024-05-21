import psycopg

def send_log(log_info):
    with psycopg.connect("dbname=syslog_ng user=postgres password=postgres") as conn:

        with conn.cursor() as cur:

            cur.execute(("SELECT syslog_ng.logs.prc_ins_logs_info(%s, %s, %s, %s, %s, %s)",
                         (log_info.Timestamp, log_info.Level, log_info.User, log_info.Process, log_info.PID, log_info.Message)))

    conn.commit()
