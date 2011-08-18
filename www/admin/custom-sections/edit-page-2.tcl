# $Id: edit-page-2.tcl,v 3.0.4.1 2000/04/28 15:08:33 carsten Exp $
# File:     admin/custom-sections/edit-page-2.tcl
# Date:     12/30/99
# Contact:  ahmeds@arsdigita.com
# Purpose:  edits custom section page
#
# Note: if page is accessed through /groups pages then group_id and group_vars_set are already set up in 
#       the environment by the ug_serve_section. group_vars_set contains group related variables (group_id, 
#       group_name, group_short_name, group_admin_email, group_public_url, group_admin_url, group_public_root_url,
#       group_admin_root_url, group_type_url_p, group_context_bar_list and group_navbar_list)


set_the_usual_form_variables 0
# maybe scope, maybe scope related variables (user_id, group_id, on_which_group, on_what_id)
# section_id content_file_id , page_pretty_name, body, html_p

ad_scope_error_check

set db [ns_db gethandle]

ad_scope_authorize $db $scope admin group_admin none

set exception_count 0
set exception_text ""

if { [empty_string_p $page_pretty_name] } {
    incr exception_count
    append exception_text "<li>page_pretty_name cannot be empty"
}

if { $exception_count > 0 } { 
    ad_scope_return_complaint $exception_count $exception_text $db
    return
}

if [catch { 

    ns_ora clob_dml $db "
    update content_files
    set page_pretty_name='$QQpage_pretty_name',
    html_p = '$QQhtml_p',
    body = empty_clob()
    where content_file_id=$content_file_id
    returning body
    into :1" $body
    
} errmsg] {

    incr exception_count
    append exception_text "
    <li>Error occured while inserting data into database. Oracle returned error:
    <br>$errmsg
    "
    ad_scope_return_complaint $exception_count $exception_text $db
    return
    
} 

ad_returnredirect index.tcl?[export_url_vars section_id]

