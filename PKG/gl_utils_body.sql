create or replace PACKAGE BODY GL_UTILS AS

  PROCEDURE CHANGE_CURRENT_USER_PW(p_new_password IN VARCHAR2) IS
  BEGIN
    APEX_UTIL.CHANGE_CURRENT_USER_PW(p_new_password => p_new_password);
  END;

  PROCEDURE CREATE_USER(p_user_name     IN VARCHAR2
                       ,p_first_name    IN VARCHAR2
                       ,p_last_name     IN VARCHAR2
                       ,p_email_address IN VARCHAR2) IS

    l_id           NUMBER;
    l_body         VARCHAR2(20000);
    l_web_password VARCHAR2(20000);
    l_email_hash   VARCHAR2(20000);
    l_INVITED_BY_id number;
  BEGIN
    begin
        select id into l_INVITED_BY_id from
        gl_users where login = v('APP_USER');
    exception when others then
        l_INVITED_BY_id := null;
    end;

    l_web_password := to_char(systimestamp
                             ,'yyyymmddhh24missff');

    APEX_UTIL.CREATE_USER(p_user_name                    => p_user_name
                         ,p_first_name                   => p_first_name
                         ,p_last_name                    => p_last_name
                         ,p_email_address                => p_email_address
                         ,p_web_password                 => l_web_password
                         ,p_group_ids                    => APEX_UTIL.GET_GROUP_ID('GLA')
                         ,p_developer_privs              => 'ADMIN:CREATE:DATA_LOADER:EDIT:HELP:MONITOR:SQL'
                         ,p_account_expiry               => NULL
                         ,p_account_locked               => 'N'
                         ,p_failed_access_attempts       => 0
                         ,p_change_password_on_first_use => 'N');

    l_email_hash := lower(dbms_obfuscation_toolkit.md5(input => utl_i18n.string_to_raw(data => lower(p_email_address))));
    INSERT INTO gl_users
      (LOGIN
      ,EMAIL
      ,IMIE
      ,NAZWISKO
      ,email_hash
      ,INVITED_BY)
    VALUES
      (p_user_name
      ,lower(p_email_address)
      ,p_first_name
      ,p_last_name
      ,l_email_hash
      ,l_INVITED_BY_id);

    l_body := '<h1>Cześć Mikołaju ' || p_user_name || '!</h1>';
    l_body := l_body ||
              '<h2>Dziękujemy, że wybrałeś Santa v2015 system ;)</h2>';
    l_body := l_body || '<p>Twoje dane do logowania: <br>';
    l_body := l_body || '<strong>URL:</strong> ' ||
              '<a href="https://apex.oracle.com/pls/apex/f?p=GLA">https://apex.oracle.com/pls/apex/f?p=GLA</a>' ||
              '<br>';
    l_body := l_body || '<strong>login:</strong> ' || p_user_name || '<br>';
    l_body := l_body || '<strong>haslo:</strong> ' || l_web_password ||
              '</p>';
    l_body := l_body ||
              '<h5><strong>Uwaga </strong>Po zalogowniu możesz zmienić hasło, w tym celu w prawym górnym rogu kliknij w swój <Login> -> wybierz "Profil" -> następnie podaj i potwierdz nowe hasło -> i naciśnij "Zapisz"</h5>';

    --
    l_id := APEX_MAIL.SEND(p_to        => p_email_address
                          ,p_from      => 'info@sviete.pl'
                          ,p_subj      => 'Witamy w Santa v2015 system'
                          ,p_body      => ' '
                          ,p_body_html => l_body
                          ,p_replyto   => 'info@sviete.pl');

  END;

  PROCEDURE SEND_MAIL(p_to        VARCHAR2
                     ,p_from      VARCHAR2
                     ,p_subj      VARCHAR2
                     ,p_body_html VARCHAR2) IS
    l_id NUMBER;

  BEGIN

    l_id := APEX_MAIL.SEND(p_to        => p_to
                          ,p_from      => 'noreply@sviete.pl'
                          ,p_replyto   => p_from
                          ,p_subj      => p_subj
                          ,p_body      => ''
                          ,p_bcc       => 'araczkowski@gmail.com'
                          ,p_body_html => p_body_html);

  END;

  FUNCTION get_comments(p_gl_id NUMBER) RETURN CLOB IS
    l_comments    CLOB;
    l_no_comments NUMBER;
    l_popup_url   VARCHAR2(4000);
  BEGIN
    --
    l_popup_url := apex_util.prepare_url(p_url                => 'f?p=' ||
                                                                 v('APP_ID') ||
                                                                 ':11' || ':' ||
                                                                 v('APP_SESSION') ||
                                                                 ':::11:P11_GL_ID' || ':' ||
                                                                 p_gl_id
                                        ,p_triggering_element => 'apex.jQuery(''#GL_' ||
                                                                 p_gl_id ||
                                                                 ''')');

    l_comments := '<br><br><div id="GL_' || p_gl_id || '"><a href="' ||
                  l_popup_url ||
                  '"><i class="fa fa-comment-o fa-2x"></i> Skomentuj:</a></div>';

    SELECT COUNT(1)
      INTO l_no_comments
      FROM gl_comment c
     WHERE c.POMYSL_ID = p_gl_id;

    IF l_no_comments > 0
    THEN
      l_comments := l_comments || '<table class="commentTable"> <tbody>';
      FOR rec IN (SELECT *
                    FROM gl_comment c
                   WHERE c.POMYSL_ID = p_gl_id
                   ORDER BY DATA_DODANIA DESC)
      LOOP
        l_comments := l_comments || '<tr> <td> <div style="min-width:90px">' ||
                      initcap(rec.DODAL) || '</div>' ||
                      to_char(rec.DATA_DODANIA
                             ,'YYYY/MM/DD hh24:mi') || '</td><td>' ||
                      rec.tekst || '</td></tr>';
      END LOOP;
      l_comments := l_comments || '</tbody></table>';
    END IF;

    RETURN l_comments;
  END;

  PROCEDURE add_comments(p_gl_id   NUMBER
                        ,p_comment VARCHAR2) IS
  BEGIN
    --
    INSERT INTO gl_comment
      (POMYSL_ID
      ,DODAL
      ,DATA_DODANIA
      ,TEKST)
    VALUES
      (p_gl_id
      ,v('APP_USER')
      ,SYSDATE
      ,p_comment);
    --
  END;

  --
  FUNCTION get_daily_newsleter(p_day   DATE
                              ,p_login VARCHAR2
                              ,p_event_id number) RETURN CLOB IS
    l_body       CLOB;
    l_wstepniak  CLOB;
    l_time_line  CLOB;
    l_top_list   CLOB;
    l_dni        NUMBER;
    l_dzien_char VARCHAR2(40);
    l_issue_no   VARCHAR2(100);

    l_impreza_id number;

  BEGIN

    -- todo
    l_impreza_id := 1;


    SELECT (SELECT COUNT(1)
              FROM GL_NEWSLETTER)
          ,n.text
      INTO l_issue_no
          ,l_wstepniak
      FROM GL_NEWSLETTER n
     WHERE n.id = (SELECT MAX(id)
                     FROM GL_NEWSLETTER);

    l_dzien_char := to_char(p_day - 1
                           ,'DD/MM/YYYY');

    FOR rec IN (SELECT *
                  FROM (SELECT c.dodal
                              ,decode(gl.link
                                     ,NULL
                                     ,gl.nazwa
                                     ,'<a href="' || gl.LINK ||
                                      '" target="_blank">' || gl.nazwa ||
                                      '</a>') nazwa
                              ,to_char(c.data_dodania
                                      ,'hh24:mi') data_dodania
                              ,gl.prezent_dla
                              ,c.tekst
                              ,'success' klasa
                              ,'#KOMENTARZ' tag_
                              ,'color: #3c763d; background-color: #dff0d8;border-color: #d6e9c6;' style_
                          FROM gift_list  gl
                              ,gl_comment c
                         WHERE gl.IMPREZA_ID = p_event_id
                           AND trunc(c.data_dodania) = trunc(p_day - 1)
                           AND c.POMYSL_ID = gl.id
                           AND (gl.prezent_dla != p_login OR gl.dodal = p_login)
                        UNION
                        SELECT gl.dodal
                              ,decode(gl.link
                                     ,NULL
                                     ,gl.nazwa
                                     ,'<a href="' || gl.LINK ||
                                      '" target="_blank">' || gl.nazwa ||
                                      '</a>') nazwa
                              ,to_char(gl.data_dodania
                                      ,'hh24:mi') data_dodania
                              ,gl.prezent_dla
                              ,gl.opis
                              ,'warning'
                              ,'#POMYSŁ'
                              ,'color: #8a6d3b; background-color: #fcf8e3;border-color:#faebcc;' style_
                          FROM gift_list gl
                         WHERE gl.IMPREZA_ID = p_event_id
                           AND trunc(gl.data_dodania) = trunc(p_day - 1)
                           AND (gl.prezent_dla != p_login OR gl.dodal = p_login))
                 ORDER BY data_dodania)
    LOOP

      l_time_line := l_time_line ||
                     '<div style="padding: 25px; margin-bottom: 20px; border: 1px solid transparent; border-radius: 4px; margin: 35px; max-width: 720px;' ||
                     rec.style_ || '"><span style="font-size:small;"> <b>' ||
                     rec.data_dodania || ' ' || rec.tag_ ||
                     '</b><br></span><span style="font-size: larger;">Prezent <b>' ||
                     rec.nazwa || '</b> dla <b>' || initcap(rec.prezent_dla) ||
                     '</b></span><br><br>' ||
                     '<span style="font-size:medium; font-weight:bold"> @' ||
                     initcap(rec.dodal) ||
                     '</span><br><span style="font-style: italic; font-size: medium;">' ||
                     rec.tekst || '</span></div>';
    END LOOP;

    --
    SELECT trunc(e.data) - trunc(SYSDATE)
      INTO l_dni
      FROM gl_events e
     WHERE id = p_event_id;

    --

    l_top_list := '<div style="padding: 25px; border: 3px solid transparent; border-radius: 6px; margin: 35px; max-width: 720px; color:#a94442;background-color:#f2dede;border-color:#ebccd1;">';
    l_top_list := l_top_list || '<ul>';
    -- POMYSLY
    l_top_list := l_top_list || '<li>Pomysły';
    l_top_list := l_top_list || '<ol>';
    FOR rec IN (SELECT gl.dodal
                      ,COUNT(1) ile
                  FROM gift_list gl
                 WHERE impreza_id = p_event_id
                 GROUP BY gl.dodal
                 ORDER BY 2 DESC)
    LOOP

      l_top_list := l_top_list || '<li>' || rec.dodal || ' => ' || rec.ile ||
                    '</li>';
    END LOOP;
    l_top_list := l_top_list || '</ol>';
    l_top_list := l_top_list || '</li>';

    -- KOMENTARZE
    l_top_list := l_top_list || '<br><li>Komentarze';
    l_top_list := l_top_list || '<ol>';
    FOR rec IN (SELECT c.dodal,COUNT(1) ile
                    FROM gl_comment c, gift_list gl
                    where gl.id = c.pomysl_id
                    and gl.impreza_id = p_event_id
                    GROUP BY c.dodal
                    ORDER BY 2 DESC)
    LOOP

      l_top_list := l_top_list || '<li>' || rec.dodal || ' => ' || rec.ile ||
                    '</li>';
    END LOOP;
    l_top_list := l_top_list || '</ol>';
    l_top_list := l_top_list || '</li>';

    -- WSTEPNIAKI
    l_top_list := l_top_list || '<br><li>Wstępniaki';
    l_top_list := l_top_list || '<ol>';
    FOR rec IN (SELECT n.dodal
                      ,COUNT(1) ile
                  FROM gl_newsletter n
                  where length(n.text) > 1
                 GROUP BY n.dodal
                 ORDER BY 2 DESC)
    LOOP

      l_top_list := l_top_list || '<li>' || rec.dodal || ' => ' || rec.ile ||
                    '</li>';
    END LOOP;
    l_top_list := l_top_list || '</ol>';
    l_top_list := l_top_list || '</li>';

    l_top_list := l_top_list || '</ul>';
    l_top_list := l_top_list || '</div>';

    l_body := l_body ||
              '<meta http-equiv="Content-Type"  content="text/html charset=UTF-8" />';

    l_body := l_body || '<div>';
    l_body := l_body ||
              '<p style="font-size:xx-large;font-weight:bolder;margin-bottom: 0px;">santa<span style="color:red">news</span>letter</p>';
    l_body := l_body || '<p style="margin-top:0px;font-size:small">Issue #' ||
              l_issue_no || ' // ' ||
              to_char(p_day
                     ,'Month dd, YYYY') || ' // Santa ' || p_login || '</p>';
    l_body := l_body || '<hr style="border-top: dotted 1px;" /><br>';

    l_body := l_body || '<h2 style="">Do PreWIGILIA 2015 zostało już tylko ' ||
              l_dni || 'dni!</h2><br><br>';

    l_body := l_body ||
              '<p>#<span style="font-weight:bolder; color:red">WSTĘPNIAK</span> <b>@' ||
              v('APP_USER')||'</b></p>';
    l_body := l_body || '<p>' || l_wstepniak || '</p>';
    l_body := l_body || '<br><br><hr style="border-top: dotted 1px;" />';

    l_body := l_body ||
              '<p>#<span style="font-weight:bolder; color:red">LINIA CZASU / </span> <b> ekscytujące momenty w dniu ' ||
              l_dzien_char || '</b>: </p>' || l_time_line;
    l_body := l_body || '<br><br><hr style="border-top: dotted 1px;" />';

    l_body := l_body ||
              '<p>#<span style="font-weight:bolder; color:red">Mikołaj''s toplist:</span></p><div>' ||
              l_top_list || '</div>';
    l_body := l_body || '<br><br><hr style="border-top: dotted 1px;" />';

    l_body := l_body ||
              '<a style="font-size: small;" href="https://apex.oracle.com/pls/apex/f?p=GLA">Santa v2015 system</a></div>';

    RETURN l_body;
  END;

  --
  PROCEDURE send_daily_newsleter(p_event_id number) IS
    l_body CLOB;
  BEGIN

    FOR rec IN (SELECT distinct u.email, u.login
                 FROM gl_users u,
                  gl_events_users eu
                WHERE u.id = eu.user_id
                and u.newsletter = 1
                and eu.event_id = 1)
    LOOP

      l_body := get_daily_newsleter(SYSDATE
                                   ,rec.login
                                   ,p_event_id);

      SEND_MAIL(rec.email
               ,'info@sviete.pl'
               ,'Ho Ho Ho! Mikołaju ' || rec.login || '! Twój ' ||
                chr(4036988545) || chr(4036988545) || chr(4036988545) ||
                ' Mikołajowy Newsletter! ' ||
                to_char(SYSDATE
                       ,'DD/MM/YYYY')
               ,l_body);

    END LOOP;

  END;

END;
