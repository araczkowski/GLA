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
       p_body_html => l_body);


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
       p_from      => p_from,
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


end;
