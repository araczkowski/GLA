create or replace package body GL_UTILS as

procedure CHANGE_CURRENT_USER_PW(
    p_new_password IN VARCHAR2) is
    begin
APEX_UTIL.CHANGE_CURRENT_USER_PW(p_new_password => p_new_password);
    end;

procedure CREATE_USER(
     p_user_name                     IN      VARCHAR2,
    p_first_name                    IN      VARCHAR2,
    p_last_name                     IN      VARCHAR2,
    p_email_address                 IN      VARCHAR2,
    p_web_password                  IN      VARCHAR2) is

l_id number;
l_body varchar2(20000);
begin

APEX_UTIL.CREATE_USER(
    p_user_name   => p_user_name,
    p_first_name  => p_first_name,
    p_last_name   => p_last_name,
    p_email_address  => p_email_address,
    p_web_password  => p_web_password,
    p_group_ids     => APEX_UTIL.GET_GROUP_ID('GLA'),
    p_developer_privs => 'ADMIN:CREATE:DATA_LOADER:EDIT:HELP:MONITOR:SQL',
    p_account_expiry  => null,
    p_account_locked   => 'N',
    p_failed_access_attempts   => 0,
    p_change_password_on_first_use  => 'N');


    insert into gl_users(LOGIN,EMAIL,IMIE, NAZWISKO) values(p_user_name,p_email_address,p_first_name,p_last_name);

   l_body := '<h1>Cześć Mikołaju '||p_user_name||'!</h1>';
   l_body := l_body||'<h2>Dziękujemy, że wybrałeś Santa v2015 system ;)</h2>';
   l_body := l_body||'<p>Twoje dane do logowania: <br>';
   l_body := l_body||'<strong>URL:</strong> '||'<a href="https://apex.oracle.com/pls/apex/f?p=GLA">https://apex.oracle.com/pls/apex/f?p=GLA</a>'||'<br>';
   l_body := l_body||'<strong>login:</strong> '||p_user_name||'<br>';
   l_body := l_body||'<strong>haslo:</strong> '||p_web_password||'</p>';
   l_body := l_body||'<h5><strong>Uwaga </strong>Po zalogowniu możesz zmienić hasło, w tym celu w prawym górnym rogu kliknij w swój <Login> -> wybierz "Profil" -> następnie podaj i potwierdz nowe hasło -> i naciśnij "Zapisz"</h5>';

   --
   l_id := APEX_MAIL.SEND(
       p_to        => p_email_address,
       p_from      => 'info@sviete.pl',
       p_subj      => 'Witamy w Santa v2015 system',
       p_body      => ' ',
       p_body_html => l_body,
       p_replyto   => 'info@sviete.pl');


    end;

procedure SEND_MAIL(
       p_to        varchar2,
       p_from      varchar2,
       p_subj      varchar2,
       p_body_html varchar2) is
       l_id number;

begin

  l_id := APEX_MAIL.SEND(
       p_to        => p_to,
       p_from      => 'noreply@sviete.pl',
       p_replyto   => p_from,
       p_subj      => p_subj,
       p_body      => '',
       p_bcc       => 'araczkowski@gmail.com',
       p_body_html => p_body_html);


 end;

 function get_comments(p_gl_id number) return clob is
 l_comments clob;
 l_no_comments number;
 l_popup_url varchar2(4000);
 begin
   --
   l_popup_url := apex_util.prepare_url(  p_url => 'f?p=' || v('APP_ID')|| ':11'|| ':' || v('APP_SESSION') || ':::11:P11_GL_ID' || ':' || p_gl_id
                      , p_triggering_element => 'apex.jQuery(''#GL_'||p_gl_id||''')') ;

   l_comments := '<br><br><div id="GL_'||p_gl_id||'"><a href="'|| l_popup_url ||'"><i class="fa fa-comment-o fa-2x"></i> Skomentuj:</a></div>';

   select count(1) into l_no_comments from gl_comment c where c.POMYSL_ID = p_gl_id;

   if l_no_comments > 0 then
       l_comments := l_comments ||'<table class="commentTable"> <tbody>';
       for rec in (select * from gl_comment c where c.POMYSL_ID = p_gl_id order by DATA_DODANIA desc) loop
           l_comments := l_comments || '<tr> <td> <div style="min-width:90px">'|| initcap(rec.DODAL) ||'</div>'||to_char(rec.DATA_DODANIA, 'YYYY/MM/DD hh24:mi')|| '</td><td>'||rec.tekst||'</td></tr>';
       end loop;
       l_comments := l_comments ||'</tbody></table>';
   end if;

  return l_comments;
 end;

procedure add_comments(p_gl_id number, p_comment varchar2) is
begin
    --
    insert into gl_comment(POMYSL_ID,DODAL,DATA_DODANIA,TEKST)
    values (p_gl_id,v('APP_USER'),sysdate,p_comment);
    --
end;

--
function get_daily_newsleter(p_day date, p_login varchar2) return clob is
l_body clob;
l_wstepniak clob;
l_time_line clob;
l_top_list clob;
l_dni number;
l_dzien_char varchar2(40);
l_issue_no varchar2(100);

begin

select (select count(1) from GL_NEWSLETTER), n.text into l_issue_no, l_wstepniak from GL_NEWSLETTER n
where n.id = (select max(id) from GL_NEWSLETTER);

l_dzien_char := to_char(p_day-1,'DD/MM/YYYY');

for rec in (select * from (select c.dodal, decode(gl.link, null, gl.nazwa,'<a href="'|| gl.LINK ||'" target="_blank">'||  gl.nazwa ||'</a>') nazwa, to_char(c.data_dodania,'hh24:mi') data_dodania, gl.prezent_dla,  c.tekst, 'success' klasa, '#KOMENTARZ' tag_
                   ,'color: #3c763d; background-color: #dff0d8;border-color: #d6e9c6;' style_
                         from gift_list gl, gl_comment c
                          where trunc(c.data_dodania) = trunc(p_day-1)
                          and c.POMYSL_ID = gl.id
                          and (gl.prezent_dla != p_login or gl.dodal = p_login)
            union
            select gl.dodal, decode(gl.link, null, gl.nazwa,'<a href="'|| gl.LINK ||'" target="_blank">'||  gl.nazwa ||'</a>') nazwa, to_char(gl.data_dodania,'hh24:mi') data_dodania, gl.prezent_dla, gl.opis, 'warning', '#POMYSŁ'
                  ,'color: #8a6d3b; background-color: #fcf8e3;border-color:#faebcc;' style_
                         from gift_list gl
                          where trunc(gl.data_dodania) = trunc(p_day-1)
                          and (gl.prezent_dla != p_login or gl.dodal = p_login)
            )
            order by data_dodania) loop


 l_time_line := l_time_line || '<div style="padding: 25px; margin-bottom: 20px; border: 1px solid transparent; border-radius: 4px; margin: 35px; max-width: 720px;'
                            || rec.style_
                            || '"><span style="font-size:small;"> <b>' || rec.data_dodania || ' '|| rec.tag_
                            || '</b><br></span><span style="font-size: larger;">Prezent <b>' ||  rec.nazwa|| '</b> dla <b>'|| initcap(rec.prezent_dla)
                            || '</b></span><br><br>'|| '<span style="font-size:medium; font-weight:bold"> @' ||initcap(rec.dodal)|| '</span><br><span style="font-style: italic; font-size: medium;">'|| rec.tekst ||'<span></div>';
end loop;


 --
 select trunc(e.data) - trunc(sysdate) into l_dni
 from gl_events e
 where nazwa = 'PreWIGILIA 2015';

 --

 l_top_list := '<div style="padding: 25px; border: 3px solid transparent; border-radius: 6px; margin: 35px; max-width: 720px; color:#a94442;background-color:#f2dede;border-color:#ebccd1;">';
 l_top_list := l_top_list || '<ul>';
 -- POMYSLY
 l_top_list := l_top_list || '<li>Pomysły';
 l_top_list := l_top_list || '<ol>';
 for rec in (select gl.dodal, count(1) ile from gift_list gl
            where impreza = 'PreWIGILIA 2015'
            group by gl.dodal
            order by 2 desc ) loop

            l_top_list := l_top_list || '<li>' || rec.dodal || ' => '|| rec.ile ||'</li>';
 end loop;
 l_top_list := l_top_list || '</ol>';
 l_top_list := l_top_list || '</li>';

 -- KOMENTARZE
 l_top_list := l_top_list || '<br><li>Komentarze';
 l_top_list := l_top_list || '<ol>';
 for rec in (select c.dodal, count(1) ile from gl_comment c
            group by c.dodal
            order by 2 desc ) loop

            l_top_list := l_top_list || '<li>' || rec.dodal || ' => '|| rec.ile ||'</li>';
 end loop;
 l_top_list := l_top_list || '</ol>';
 l_top_list := l_top_list || '</li>';

 -- WSTEPNIAKI
 l_top_list := l_top_list || '<br><li>Wstępniaki';
 l_top_list := l_top_list || '<ol>';
 for rec in (select n.dodal, count(1) ile from gl_newsletter n
            group by n.dodal
            order by 2 desc ) loop

            l_top_list := l_top_list || '<li>' || rec.dodal || ' => '|| rec.ile ||'</li>';
 end loop;
 l_top_list := l_top_list || '</ol>';
 l_top_list := l_top_list || '</li>';

 l_top_list := l_top_list || '</ul>';
 l_top_list := l_top_list || '</div>';


 l_body := l_body || '<meta http-equiv="Content-Type"  content="text/html charset=UTF-8" />';



 l_body := l_body || '<div>';
 l_body := l_body || '<p style="font-size:xx-large;font-weight:bolder;margin-bottom: 0px;">santa<span style="color:red">news</span>letter</p>';
 l_body := l_body || '<p style="margin-top:0px;font-size:small">Issue #'||l_issue_no||' // '|| to_char(p_day, 'Month dd, YYYY') || ' // Santa ' || p_login || '</p>';
 l_body := l_body || '<hr style="border-top: dotted 1px;" /><br>';

 l_body := l_body || '<h2 style="">Do PreWIGILIA 2015 zostało już tylko '||l_dni|| 'dni!</h2><br><br>';

 l_body := l_body || '<p>#<span style="font-weight:bolder; color:red">WSTĘPNIAK</span> <b>@' ||v('APP_USER');
 l_body := l_body || '<p>'||l_wstepniak||'</p>';
 l_body := l_body || '<br><br><hr style="border-top: dotted 1px;" />';



 l_body := l_body || '<p>#<span style="font-weight:bolder; color:red">LINIA CZASU / </span> <b> ekscytujące momenty w dniu '||l_dzien_char||'</b>: </p>' || l_time_line;
 l_body := l_body || '<br><br><hr style="border-top: dotted 1px;" />';


 l_body := l_body || '<p>#<span style="font-weight:bolder; color:red">Mikołaj''s toplist:</span><div style="">'||l_top_list ||'</div>';
 l_body := l_body || '<br><br><hr style="border-top: dotted 1px;" />';


 l_body := l_body || '<a style="font-size: small;" href="https://apex.oracle.com/pls/apex/f?p=GLA">Santa v2015 system</a>';



 return l_body;
end;


--
procedure send_daily_newsleter is
l_body clob;
begin


for rec in (select * from gl_users where newsletter = 1) loop

 l_body := get_daily_newsleter(sysdate, rec.login);

 SEND_MAIL(rec.email,'info@sviete.pl','Ho Ho Ho! Mikołaju '|| rec.login || '! Twój '|| chr(4036988545) || chr(4036988545) || chr(4036988545)  ||' Mikołajowy Newsletter! '||to_char(sysdate,'DD/MM/YYYY'), l_body);


end loop;

end;


end;
