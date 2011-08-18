# $Id: spam-confirm.tcl,v 3.4.2.2 2000/04/28 15:09:21 carsten Exp $
# spam-confirm.tcl
#
# hqm@arsdigita.com
#
# A good thing to do before sending out 100,000 emails:
# ask user to confirm the outgoing spam before queuing it.
#

set_the_usual_form_variables

# spam_id, from_address, subject, 
# message, (optional) message_html, message_aol
# maybe send_date
# 
# if from_file_p=t, then get message texts from default filesystem location 
#
#
# maybe: users_sql_query     The SQL needed to get the list of target users
#        users_description   English descritpion of target users
# or else user_class_id, which can be passed to ad_user_class_query to generate a SQL query.
#
# maybe: template_p   If == 't', then run subst on the message subject and body. A scary
# prospect, but spam can only be created by site admins anyhow)

set db [ns_db gethandle]

set admin_user_id [ad_verify_and_get_user_id]
ad_maybe_redirect_for_registration

if {[info exists from_file_p] && [string compare $from_file_p "t"] == 0} {
    set message [get_spam_from_filesystem "plain"]
    set message_html [get_spam_from_filesystem "html"]
    set message_aol [get_spam_from_filesystem "aol"]
}

set message [spam_wrap_text $message 80]

set exception_count 0
set exception_text ""

if {[catch {ns_dbformvalue [ns_conn form] send_date datetime send_date} errmsg]} {
    incr exception_count
    append exception_text "<li>Please make sure your date is valid."
}


# Generate the SQL query from the user_class_id, if supplied
if {[info exists user_class_id] && ![empty_string_p $user_class_id]} {
    set users_sql_query [ad_user_class_query [ns_getform]]
    regsub {from users} $users_sql_query {from users_spammable users} users_sql_query

    set class_name [database_to_tcl_string $db "select name from user_classes where user_class_id = $user_class_id "]

    set sql_description [database_to_tcl_string $db "select sql_description from user_classes where user_class_id = $user_class_id "]
    set users_description "$class_name: $sql_description"
}

if { ![philg_email_valid_p $from_address] } {
    incr exception_count
    append exception_text "<li>The From address is invalid."
}


if {$exception_count > 0 } {
    ad_return_complaint $exception_count $exception_text
    return
}

ns_dbformvalue [ns_conn form] send_date datetime send_date

if {[info exists template_p] && [string match $template_p "t"]} {
   set template_pretty "Yes"
} else {
    set template_p "f"
    set template_pretty "No" 
}

ReturnHeaders

append pagebody "[ad_admin_header "Confirm sending spam"]

[ad_admin_context_bar [list "index.tcl" "Spam"] "confirm sending a spam"]

<hr>

<h2>Confirm Sending Spam</h2>

The following spam will be queued for delivery:


<p>
"



# strips ctrl-m's, makes linebreaks at >= 80 cols when possible, without
# destroying urls or other long strings
set message [spam_wrap_text $message 80]

append pagebody "

<form method=POST action=\"/admin/spam/spam.tcl\">

<blockquote>
<table border=1>
<tr><th align=right>User&nbsp;Class:</th><td> $users_description
</td></tr>
<tr><th align=right>Date:</th><td> $send_date </td></tr>

<tr><th align=right>From:</th><td>$from_address</td></tr>
<tr><th align=right>Template?</th><td>$template_pretty</td></tr>

<tr><th align=right>Subject:</th><td>$subject</td></tr>

<tr><th align=right valign=top>Plain Text Message:</th><td>
<pre>[ns_quotehtml $message]</pre>
</td></tr>

"
if {[info exists message_html] && ![empty_string_p $message_html]} {
    append pagebody "<tr><th align=right valign=top>HTML Message:</th>
<td>
$message_html
</td>
</tr>"
}

if {[info exists message_aol] && ![empty_string_p $message_aol]} {
    append pagebody "<tr><th align=right valign=top>AOL Message:</th>
<td>
$message_aol
</td>
</tr>"
}


append pagebody "
</table>

</blockquote>
<center>
<input type=submit value=\"Send Spam\">

</center>

[export_form_vars users_sql_query users_description spam_id from_address subject message message_html message_aol send_date template_p]
</form>
<p>

<i>The SQL query will be</i>
<pre>$users_sql_query</pre>
"

set count_users_query "select count(*) from ($users_sql_query)"
set total_users [database_to_tcl_string $db $count_users_query]

append pagebody "
and will send email to $total_users users.
[ad_admin_footer]"


ns_write $pagebody
