CREATE OR REPLACE VIEW my_friends_vw AS
SELECT u.*
FROM gl_users u
WHERE upper(u.login) = v('APP_USER')
UNION
SELECT u.*
FROM gl_users u
WHERE u.invited_by =
        (SELECT id
         FROM gl_users
         WHERE upper(login) = v('APP_USER'))
UNION
SELECT u.*
FROM gl_users u
WHERE u.id =
        (SELECT invited_by
         FROM gl_users
         WHERE upper(login) = v('APP_USER'))
UNION
SELECT u.*
FROM gl_users u
WHERE u.id IN
        (SELECT e.id
         FROM gl_events_users e
         WHERE e.event_id IN
                 (SELECT DISTINCT eu.event_id
                  FROM gl_events_users eu,
                       gl_users u
                  WHERE eu.user_id = u.id
                      AND upper(u.login) = v('APP_USER')))
