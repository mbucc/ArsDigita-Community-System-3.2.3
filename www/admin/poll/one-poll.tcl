# /admin/poll/one-poll.tcl 

ad_page_contract {
    Show info(e) about a single poll
    @param poll_id the ID of the poll
    @creation-date 10 July 2000 
    @author Mark Dalrymple (markd@arsdigita.com)
    @cvs-id one-poll.tcl,v 3.3.2.8 2001/01/11 20:16:20 khy Exp
} {
    poll_id:notnull,naturalnum
}

ad_maybe_redirect_for_registration


db_1row get_poll_info "
select name, description, start_date, end_date, require_registration_p
  from polls
 where poll_id = :poll_id
"

set page_html "
[ad_admin_header "One Poll: $name"]
<h2>One Poll: $name</h2>

[ad_admin_context_bar [list "/admin/poll" Polls] One]

<hr>

<ul>
<li>Name:  $name

<li>Description:  $description

<li>Dates:  [util_AnsiDatetoPrettyDate $start_date] to [util_AnsiDatetoPrettyDate $end_date]

<li>User entry page:  <a href=\"/poll/one-poll?[export_url_vars poll_id]\">/poll/one-poll?[export_url_vars poll_id]</a>

<li>Results page:  <a href=\"/poll/poll-results?[export_url_vars poll_id]\">/poll/poll-results?[export_url_vars poll_id]</a>

(if these look fishy, look at 
<a href=\"integrity-stats?[export_url_vars poll_id]\">integrity statistics</a>)

<li>Require Registration?  [util_PrettyBoolean $require_registration_p]

<br>
<br>

\[ <a href=\"poll-delete?[export_url_vars poll_id]\">delete</a> |
 <a href=\"poll-edit?[export_url_vars poll_id]\">edit</a> \] 
</ul>

<h3>Choices for this poll</h3>

<p>
<ul>
"

set count [db_string select_count "
select count(*) 
  from poll_choices 
 where poll_id = :poll_id
"]

set choice_id [db_string select_new_choice_id "select poll_choice_id_sequence.nextval from dual"]

append page_html "
<form method=post action=choice-new>
[export_form_vars poll_id]
[export_form_vars -sign choice_id]

<table border=1>
"

# construct a list of numbers so we can easily present a choice
# of ordering values

set order_list [list]
set loop_limit [expr $count + 1]

for { set i 1 } { $i <= $loop_limit } { incr i } {
    lappend order_list $i
}
    

# if we have existing items, make a table of a pop-up to
# determine ordering.  The <select> names are of the form
# order_$choice_id, and a regexp pulls out the choice ID
# in the page that handles this POST.

if { $count > 0 } {
 set i 1
db_foreach get_poll_choices "
select choice_id, label
  from poll_choices
 where poll_id = :poll_id
 order by sort_order
" {

    # don't use the absolute values of the sort_order, since they may
    # not necessarily be in sequential order.
   	append page_html "
<tr>
<td> <select name=order.$choice_id>
         [ad_generic_optionlist $order_list $order_list $i]
     </select>
<td> $label  <font size=-1>(<a href=choice-delete?[export_url_vars choice_id poll_id]>delete</a>)</font> \n
"
        incr i
    }

} else {

    # yeah, the page generated by this is a little ugly.

    append page_html "
<tr>
<td>
<td> You haven't defined any choices for this poll yet.
"
}

db_release_unused_handles

append page_html "

<tr>
<td> <select name=choice_new>
         [ad_generic_optionlist $order_list $order_list $i]
     </select>
<td> <input type=text name=label size=50>
<input type=submit name=action value=\"Define New Choice\">

<tr>
<td> <input type=submit name=action value=\"Change Ordering\">
<td> &nbsp;

</table>

</form>

<p>

</ul>

<p>
[ad_admin_footer]
"
doc_return  200 text/html $page_html
