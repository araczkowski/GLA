create or replace package GL_UTILS as

procedure CHANGE_CURRENT_USER_PW(
    p_new_password IN VARCHAR2);


procedure CREATE_USER(
     p_user_name                     IN      VARCHAR2,
    p_first_name                    IN      VARCHAR2,
    p_last_name                     IN      VARCHAR2,
    p_email_address                 IN      VARCHAR2,
    p_web_password                  IN      VARCHAR2);


procedure SEND_MAIL(
       p_to        varchar2,
       p_from      varchar2,
       p_subj      varchar2,
       p_body_html varchar2);

function get_comments(p_gl_id number) return clob;

procedure add_comments(p_gl_id number, p_comment varchar2);

procedure send_daily_newsleter;

function get_daily_newsleter(p_day date, p_login varchar2) return clob;

end;
