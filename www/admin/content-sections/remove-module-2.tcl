# $Id: remove-module-2.tcl,v 3.0.4.1 2000/04/28 15:08:30 carsten Exp $
# File:     /admin/content-sections/module-remove-2.tcl
# Date:     01/01/2000
# Contact:  tarik@arsdigita.com
# Purpose:  removes association between module and the group

set_the_usual_form_variables
# group_id, section_key, confirm_button

ad_scope_error_check
set db [ns_db gethandle]
ad_scope_authorize $db $scope none group_admin none

if { [string compare $confirm_button yes]!=0 } {
    ad_returnredirect "content-section-edit.tcl?[export_url_scope_vars section_key]"
    return
}

ns_db dml $db "begin transaction"

ns_db dml $db "
delete from content_section_links
where from_section_id=(select section_id
                       from content_sections
                       where scope='group'
                       and group_id=$group_id
                       and section_key='$QQsection_key')
or to_section_id=(select section_id
                  from content_sections
                  where scope='group'
                  and group_id=$group_id
                  and section_key='$QQsection_key')
"

ns_db dml $db "
delete from content_files
where section_id=(select section_id
                  from content_sections
                  where scope='group'
                  and group_id=$group_id
                  and section_key='$QQsection_key')
"

ns_db dml $db "
delete from content_sections
where scope='group'
and group_id=$group_id
and section_key='$QQsection_key'
"

ns_db dml $db "end transaction"

ad_returnredirect index.tcl



