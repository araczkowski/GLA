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
l_dodane varchar2(32767);
l_skomentowane varchar2(32767);
l_dni number;
l_dzien_char varchar2(40);
l_dodane_wszystkie varchar2(32767);
begin

l_dzien_char := to_char(p_day-1,'DD/MM/YYYY');

for rec in (select gl.dodal, count(1) ile from gift_list gl
            where trunc(gl.data_dodania) = trunc(p_day-1)
            group by gl.dodal
            order by 2 desc ) loop

 if length(l_dodane) = 0 then
     l_dodane := '<ul>';
 end if;

 l_dodane := l_dodane || '<li>' || rec.dodal || ' => '|| rec.ile ||'</li>';
end loop;

if length(l_dodane) > 0 then
     l_dodane := l_dodane || '</ul>';
 end if;

--

for rec in (select c.dodal, count(1) ile from gl_comment c
 where trunc(c.data_dodania) = trunc(p_day-1)
group by c.dodal
order by 2 desc ) loop

 if length(l_skomentowane) = 0 then
     l_skomentowane := '<ul>';
 end if;

 l_skomentowane := l_skomentowane || '<li>' || rec.dodal || ' => '|| rec.ile ||'</li>';
end loop;

if length(l_skomentowane) > 0 then
     l_skomentowane := l_skomentowane || '</ul>';
 end if;

 --
 select trunc(e.data) - trunc(p_day) into l_dni
 from gl_events e
 where nazwa = 'PreWIGILIA 2015';

 --

 l_dodane_wszystkie := '<ol>';
 for rec in (select gl.dodal, count(1) ile from gift_list gl
            where impreza = 'PreWIGILIA 2015'
            group by gl.dodal
            order by 2 desc ) loop

            l_dodane_wszystkie := l_dodane_wszystkie || '<li>' || rec.dodal || ' => '|| rec.ile ||'</li>';
 end loop;
 l_dodane_wszystkie := l_dodane_wszystkie || '</ol>';

 l_body := l_body || '<meta http-equiv="Content-Type"  content="text/html charset=UTF-8" />';





 l_body := l_body || '<div>';
 l_body := l_body || '<p style="font-size:xx-large;font-weight:bolder;margin-bottom: 0px;">santa<span style="color:red">news</span>letter</p>';
 l_body := l_body || '<p style="margin-top:0px;font-size:small">Issue #1 // '|| to_char(p_day, 'Month dd, YYYY') || ' // Santa ' || p_login || '</p>';
 l_body := l_body || '<hr style="border-top: dotted 1px;" /><br>';





 l_body := l_body || '<p>#<span style="font-weight:bolder; color:red">POMYSŁY NA PREZENTY</span> dodane w dniu '||l_dzien_char||': </p>' || l_dodane;
 l_body := l_body || '<br><br><hr style="border-top: dotted 1px;" />';

 l_body := l_body || '<p>#<span style="font-weight:bolder; color:red">KOMENTARZE</span> dodane w dniu'||l_dzien_char||': </p>' || l_skomentowane;
 l_body := l_body || '<br><br><hr style="border-top: dotted 1px;" />';

 l_body := l_body || '<p>#<span style="font-weight:bolder; color:red">Mikołaj''s toplist:</span>'||l_dodane_wszystkie;
 l_body := l_body || '<br><br><hr style="border-top: dotted 1px;" />';

 l_body := l_body || '<h5 style="margin-bottom: 0px;">Do PreWIGILIA 2015 zostało już tylko '||l_dni|| 'dni!</h5>';
 l_body := l_body || '<a style="font-size: small;" href="https://apex.oracle.com/pls/apex/f?p=GLA">Santa v2015 system</a>';



 return l_body;
end;


--
procedure send_daily_newsleter is
l_body clob;
begin


for rec in (select * from gl_users where newsletter = 1) loop

 l_body := get_daily_newsleter(sysdate, rec.login);

 SEND_MAIL(rec.email,'info@sviete.pl','Ho Ho Ho! Mikołaju '|| rec.login || '! Twój Mikołajowy Newsletter '||to_char(sysdate,'DD/MM/YYYY'), l_body);


end loop;

end;


end;
