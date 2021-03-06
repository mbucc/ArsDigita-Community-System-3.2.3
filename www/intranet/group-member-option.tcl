# /www/intranet/group-member-option.tcl

ad_page_contract {
    Offers a user the chance to join a group before continuing
    to a scoped page. Hack to bypass the need for someone to 
    explicitly belong to a group for scoping to work.

    @param group_id group we're joining
    @param continue_url where to go if we join
    @param cancel_url where to go if we decide not to join
    @param role role in which to join. This is defaulted on the next
    page (group-member-option-2) if it's left empty

    @author mbryzek@arsdigita.com
    @creation-date 4/4/2000

    @cvs-id group-member-option.tcl,v 3.4.6.5 2000/09/22 01:38:20 kevin Exp
} {
    group_id:integer,notnull
    continue_url:notnull
    cancel_url:notnull
    { role "" }
}


set user_id [ad_maybe_redirect_for_registration]

set group_name [db_string group_name \
	"select group_name from user_groups where group_id = :group_id"]
db_release_unused_handles

set page_title "You are not a group member"
set context_bar [ad_context_bar_ws "Join group"]

set page_body "
You must be a member of the group, \"$group_name,\" to access the function you requested.
Do you want to join this group now?

<p>

[im_yes_no_table group-member-option-2 group-member-option-2 [list group_id role continue_url cancel_url]]

"

doc_return  200 text/html [im_return_template]
