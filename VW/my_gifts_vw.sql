CREATE OR REPLACE VIEW my_gifts_vw AS
SELECT decode(gle.status,'REZ','',decode(v('APP_USER'), gl.dodal, '<a href="f?p=1315:2:&APP_SESSION.::::P2_ROWID:'||gl.rowid||'"><img src="/i/menu/pencil16x16.gif" alt=""></a>', '')) edycja,
       gl.impreza_id,
       gl.nazwa,
       '<h3>'||gl.nazwa||'</h3>'||gl.opis || gl_utils.get_comments(gl.id) AS opis,
               decode(gl.link, NULL,NULL,'<a href="'||gl.link||'" target="_blank"><i class="fa fa-link"></i></a>') link,
               decode(gl.link, NULL,NULL,'href="'||gl.link||'"') link_href,
               gl.dodal,
               gl.data_dodania,
               decode(:APP_USER, gl.prezent_dla, '', decode(gl.zarezerwowal,:APP_USER,'Zarezerwowałeś ten prezent: '||gl.data_rezerwacji,'',decode(gle.status,'REZ','<a href="javascript:rezerwuje_prezent('''||gl.rowid||''');"><span class="fa fa-gift fa-5x"></span></a>','Rezerwacja będzie możliwa na etapie rezerwacji'))) rezerwuj,
               gl.zarezerwowal,
               gl.data_rezerwacji,
               gl.data_zmiany,
               decode(nvl(dbms_lob.getlength(gl.zdjecie), 0), 0, NULL, '<img style="border: 4px solid #CCC; -moz-border-radius: 4px; -webkit-border-radius: 4px;" ' || 'src="' || apex_util.get_blob_file_src('P2_ZDJECIE', gl.rowid) || '" height="120" width="120" alt="Zdjecie" title="Zdjecie" />') "ZDJECIE",
               decode(nvl(dbms_lob.getlength(gl.zdjecie), 0), 0, NULL, apex_util.get_blob_file_src('P2_ZDJECIE', gl.rowid)) zdjecie_no_style,
               gl.last_update_date,
               gl.mimetype,
               gl.filename,
               gl.prezent_dla,
               decode(upper(v('APP_USER')), upper(gl.zarezerwowal), apex_item.checkbox2(p_idx => 1, p_value => gl.kupione, p_attributes => decode(gl.kupione,'T','CHECKED','UNCHECKED')|| ' onchange="apex.event.trigger(document, ''kupione'', ''' ||gl.rowid||'''); void(0);"'), '') kupione,
               gle.status
FROM gift_list gl
LEFT OUTER JOIN gl_events gle ON gl.impreza_id = gle.id
WHERE (gle.id IS NOT NULL --
/*dotyczące imprez w których user bierze udział*/
       AND EXISTS
           (SELECT 1
            FROM gl_events_users eu,
                 gl_users u
            WHERE eu.user_id = u.id
                AND eu.event_id = gle.id
                AND upper(u.login) = upper(:APP_USER))--
 /*zakonczone*/
       AND ((gle.status = 'KON'
             AND upper(gl.dodal) = upper(:APP_USER)
             AND gl.zarezerwowal IS NULL)--
 /* rezerwacja */
            OR (gle.status = 'REZ'
                AND prezent_dla != :APP_USER
                AND nvl(upper(zarezerwowal),upper(:APP_USER)) = upper(:APP_USER))--
 /*planowanie*/
            OR (gle.status = 'ZGL'
                AND (upper(dodal) = upper(:APP_USER)
                     OR upper(prezent_dla) != upper(:APP_USER)))))
    OR (gle.id IS NULL
        AND upper(dodal) = upper(:APP_USER))
