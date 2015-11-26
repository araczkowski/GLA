CREATE OR REPLACE VIEW my_events_vw AS
SELECT e.id,
       e.nazwa,
       e.organizator,
       e.opis,
       '<span>Zaproszonych: <br><h4>'||
    (SELECT count(1)
     FROM gl_events_users eu
     WHERE eu.event_id = e.id) ||'</h4>Potwierdzonych:<h4> '||
    (SELECT count(1)
     FROM gl_events_users eu
     WHERE eu.event_id = e.id
         AND eu.confirmation_date IS NOT NULL)|| '</h4></span>' uczestnicy,
                                        "DATA",
                                        "STATUS",

    (SELECT u.email
     FROM gl_users u
     WHERE upper(u.login) = :APP_USER) AS email,
                                        replace(e.uczestnicy,':','') email_to
FROM gl_events e
WHERE (EXISTS
           (SELECT 1
            FROM gl_events_users eu,
                 gl_users u
            WHERE eu.user_id = u.id
                AND eu.event_id = e.id
                AND upper(u.login) = :APP_USER)
       OR upper(organizator) = :APP_USER)
