create or replace PACKAGE GL_UTILS AS

  PROCEDURE CHANGE_CURRENT_USER_PW(p_new_password IN VARCHAR2);

  PROCEDURE CREATE_USER(p_user_name     IN VARCHAR2
                       ,p_first_name    IN VARCHAR2
                       ,p_last_name     IN VARCHAR2
                       ,p_email_address IN VARCHAR2);

  PROCEDURE SEND_MAIL(p_to        VARCHAR2
                     ,p_from      VARCHAR2
                     ,p_subj      VARCHAR2
                     ,p_body_html VARCHAR2);

  FUNCTION get_comments(p_gl_id NUMBER) RETURN CLOB;

  PROCEDURE add_comments(p_gl_id   NUMBER
                        ,p_comment VARCHAR2);

  PROCEDURE send_daily_newsleter(p_event_id number);

  FUNCTION get_daily_newsleter(p_day   DATE
                              ,p_login VARCHAR2
                              ,p_event_id number) RETURN CLOB;

END;
