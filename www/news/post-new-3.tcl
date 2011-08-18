#
# /www/news/post-new-3.tcl
#
# process the input form for the new news item
#
# Author: jkoontz@arsdigita.com March 8, 2000
#
# $Id: post-new-3.tcl,v 3.2.2.1 2000/04/28 15:11:15 carsten Exp $

# Note: if page is accessed through /groups pages then group_id and 
# group_vars_set are already set up in the environment by the 
# ug_serve_section. group_vars_set contains group related variables
# (group_id, group_name, group_short_name, group_admin_email, 
# group_public_url, group_admin_url, group_public_root_url,
# group_admin_root_url, group_type_url_p, group_context_bar_list and
# group_navbar_list)

if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

set_form_variables
# maybe scope, maybe scope related variables (user_id, group_id, on_which_group, on_what_id)
# maybe return_url, name
# news_item_id, title, body, AOLserver ns_db magic vars that can be 
# kludged together to form release_date and expiration_date

ad_scope_error_check

if { ![info exists return_url] } {
    set return_url "index.tcl?[export_url_scope_vars]"
}

set db [ns_db gethandle]
set user_id [ad_scope_authorize $db $scope all all all ]

if { $user_id == 0 } {
    ad_returnredirect "/register/index.tcl?[export_url_scope_vars]"
    return
}

set creation_ip_address [ns_conn peeraddr]

set exception_count 0
set exception_text ""

if [catch  {
    ns_dbformvalue [ns_conn form] release_date date release_date
    ns_dbformvalue [ns_conn form] expiration_date date expiration_date} errmsg] {
    incr exception_count
    append exception_text "<li>Please make sure your dates are valid."
} else {
    set expire_laterthan_future_p [database_to_tcl_string $db "select to_date('$expiration_date', 'yyyy-mm-dd')  - to_date('$release_date', 'yyyy-mm-dd')  from dual"]
    if {$expire_laterthan_future_p <= 0} {
	incr exception_count
	append exception_text "<li>Please make sure the expiration date is later than the release date."
    }
}

# now release_date and expiration_date are set

if { ![info exists title] || [empty_string_p $title]} {
    incr exception_count
    append exception_text "<li>Please enter a title."
}
if { ![info exists body] || [empty_string_p $body] } {
    incr exception_count
    append exception_text "<li>Please enter the full story."
}

if {$exception_count > 0} { 
    ad_scope_return_complaint $exception_count $exception_text $db
    return
}

if { [ad_parameter ApprovalPolicy news] == "open"} {
    set approval_state "approved"
} else {
    set approval_state "disapproved"
}


if { ![exists_and_not_null scope] } {
    set scope "public"
}

set additional_clause ""
if { [string match $scope "group"] && ![empty_string_p $group_id] } {
    set additional_clause "and group_id = $group_id"
}

# Get the newsgroup_id for this board
set newsgroup_id [database_to_tcl_string_or_null $db "select newsgroup_id 
from newsgroups
where scope = '$scope' $additional_clause"]

# Check if there is no news group for this scope
if { [empty_string_p $newsgroup_id] } { 
    # Create the newsgroup for the group
    ns_db dml $db "insert into newsgroups (newsgroup_id, scope, group_id) values (newsgroup_id_sequence.nextval, '$scope', $group_id)"

    set newsgroup_id [database_to_tcl_string_or_null $db "select newsgroup_id 
    from newsgroups
    where scope = '$scope' $additional_clause"]
}

# Let's use data pipeline here to handle the clob for body, and the double click situation
set form_setid [ns_getform]
ns_set put $form_setid dp.news_items.news_item_id $news_item_id
ns_set put $form_setid dp.news_items.newsgroup_id $newsgroup_id
ns_set put $form_setid dp.news_items.title $title
ns_set put $form_setid dp.news_items.body.clob $body
ns_set put $form_setid dp.news_items.html_p $html_p
ns_set put $form_setid dp.news_items.approval_state $approval_state
ns_set put $form_setid dp.news_items.approval_date.expr sysdate
ns_set put $form_setid dp.news_items.release_date $release_date
ns_set put $form_setid dp.news_items.expiration_date $expiration_date
ns_set put $form_setid dp.news_items.creation_date.expr sysdate
ns_set put $form_setid dp.news_items.creation_user $user_id
ns_set put $form_setid dp.news_items.creation_ip_address $creation_ip_address

if [catch { dp_process -db $db -where_clause "news_item_id=$news_item_id" } errmsg] {
    ns_log Error "/news/post-edit-2.tcl choked:  $errmsg"
    ad_scope_return_error "Insert Failed" "The Database did not like what you typed.  This is probably a bug in our code.  Here's what the database said:
<blockquote>
<pre>
$errmsg
</pre>
</blockquote>
" $db
    return
}

# ad_dbclick_check_dml $db news news_item_id $news_item_id $return_url "
# insert into news
# (news_item_id, title, body, html_p, approved_p, release_date, expiration_date, creation_date, creation_user, creation_ip_address, [ad_scope_cols_sql]) 
# values 
# ($news_item_id, '$QQtitle', '$QQbody', '$html_p', '$approved_p', '$release_date', '$expiration_date', sysdate, $user_id, '$creation_ip_address', [ad_scope_vals_sql])
# " 

#if [catch { ns_db dml $db "insert into news
#(news_id, title, body, html_p, approved_p, release_date, expiration_date, creation_date, creation_user, creation_ip_address)
#values
#($news_id, '$QQtitle', '$QQbody', '$html_p', '$approved_p', '$release_date', '$expiration_date', sysdate, $user_id, '$creation_ip_address')" } errmsg] {
    # insert failed; let's see if it was because of duplicate submission
 #   if { [database_to_tcl_string $db "select count(*) from news where news_id = $news_id"] == 0 } {
#	ns_log Error "/news/post-new-3.tcl choked:  $errmsg"
#	ad_return_error "Insert Failed" "The Database did not like what you typed.  This is probably a bug in our code.  Here's what the database said:
#<blockquote>
#<pre>
#$errmsg
#</pre>
#</blockquote>
#"
#        return
#}
    # we don't bother to handle the cases where there is a dupe submission
    # because the user should be thanked or redirected anyway
#}

if { [ad_parameter ApprovalPolicy news] == "open"} {
    ad_returnredirect $return_url
} else {
    ns_return 200 text/html "
[ad_scope_header "Thank you" $db]

<h2>Thank you</h2>

for your submission to [ad_site_home_link]

<hr>

Your submission will be reviewed by 
[ad_parameter SystemOwner news [ad_system_owner]].

[ad_scope_footer]"
}

