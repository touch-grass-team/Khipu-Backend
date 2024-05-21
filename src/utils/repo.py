import psycopg2

def send_log(log_info):
    try:
         ps_connection = psycopg2.connect(user="logwriter",
                                         password="server",
                                         host="127.0.0.1",
                                         port="5432",
                                         database="syslog_ng")

        cursor = ps_connection.cursor()
        cursor.callproc(cur.execute("SELECT syslog_ng.logs.prc_ins_logs_info(%s, %s, %s, %s, %s, %s)",
                                    (log_info.Timestamp, log_info.Level, log_info.User, log_info.Process, log_info.PID, log_info.Message)))

    except (Exception, psycopg2.DatabaseError) as error:
        print("Error while connecting to PostgreSQL", error)

    finally:
        # closing database connection.
        if ps_connection:
            cursor.close()
            ps_connection.close()
            print("PostgreSQL connection is closed")
