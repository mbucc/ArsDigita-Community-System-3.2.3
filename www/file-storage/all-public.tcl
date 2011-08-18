# /file-storage/all-public.tcl
#
# by philg@mit.edu July 24, 1999
# 
# provide an interface to the public files of all the users
#
# modified by randyg@arsdigita.com, January 2000 to make use of the 
# general permissions module
#
# $Id: all-public.tcl,v 3.3.2.1 2000/03/27 17:30:34 carsten Exp $

set local_user_id [ad_verify_and_get_user_id]

ad_maybe_redirect_for_registration

set db [ns_db gethandle]

set page_content "[ad_header "Public files summary"]

<h2>Public files summary</h2>

[ad_context_bar_ws [list "" [ad_parameter SystemName fs]] "Publically accessible files"]

<hr>

Users with files/folders in their personal directories:

"

# get the names of users who have stuff in their personal space

set selection [ns_db select $db "select u.user_id,
            u.first_names,
            u.last_name,
            count ( distinct fsf.file_id ) as n_files,
            round ( sum ( fsvl.n_bytes ) / 1024 ) as n_kbytes
       from users u,
            fs_files fsf,
            fs_versions_latest fsvl
      where fsf.file_id = fsvl.file_id
        and fsf.owner_id = u.user_id
        and ( fsf.public_p = 'f' or fsf.public_p is null )
        and fsf.group_id is null
        and ( fsf.folder_p = 'f' or fsf.folder_p is null )
        and fsf.deleted_p = 'f'
        and ad_general_permissions.user_has_row_permission_p ( $local_user_id, 'read', fsvl.version_id, 'FS_VERSIONS' ) = 't'
   group by u.user_id,
            u.first_names,
            u.last_name
   order by upper ( last_name ), upper ( first_names )"]

set persons_html "" 

while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    append persons_html "<li><a href=\"public-one-person?owner_id=$user_id\">$first_names $last_name</a>: $n_files files; $n_kbytes Kbytes\n"
}

append page_content "<ul> $persons_html </ul>"

set selection [ns_db select $db "select ug.group_id,
            ug.group_name,
            round ( sum ( fsvl.n_bytes ) / 1024 ) as n_kbytes
       from user_groups ug,
            fs_files fsf,
            fs_versions_latest fsvl
      where fsf.file_id = fsvl.file_id
        and ( fsf.public_p = 'f' or fsf.public_p is null )
        and fsf.deleted_p = 'f'
        and ( fsf.folder_p = 'f' or fsf.folder_p is null )
        and fsf.group_id = ug.group_id
        and ad_general_permissions.user_has_row_permission_p ( $local_user_id, 'read', fsvl.version_id, 'FS_VERSIONS' ) = 't'
   group by ug.group_id,
            ug.group_name"]

set group_html ""

while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    append group_html "<li><a href=\"public-one-group?[export_url_vars group_id]\">$group_name</a>:  $n_kbytes Kbytes\n"
}

if { ![empty_string_p $group_html] } {
    append page_content  "<nobr>Groups with files/folders stored: <ul>$group_html</ul>\n"
} 

if [ad_parameter PublicDocumentTreeP fs] {

    append page_content "<p>
Documents that are shared system wide:
<ul>
<li><a href=\"\">Shared [ad_system_name] document tree</a>
</ul>
<p>"  
  
}


append page_content "
[ad_footer [fs_system_owner]]
"

# release the database handle

ns_db releasehandle $db 

# serve the page

ns_return 200 text/html $page_content


