# File: /general-links/link-add-3.tcl
# Date: 2/01/2000
# Author: tzumainn@arsdigita.com 
#
# Purpose: 
#  Step 3 of 4 in adding link and its association
#
# $Id: link-add-3.tcl,v 3.0.4.1 2000/03/15 02:12:12 tzumainn Exp $
#--------------------------------------------------------

if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

ad_page_variables {on_which_table on_what_id item {module ""} return_url link_id association_id link_title url {link_description ""} {category_id_list -multiple-list}}

ad_return_top_of_page "
[ad_header "Confirm Link to $item (Step 3 of 3)"]

<h2>Confirm Link to $item (Step 3 of 3)</h2>

[ad_context_bar_ws [list $return_url $item] "Confirm Link to $item (Step 3 of 3)"]

<hr>
"

set db [ns_db gethandle]

set category_list "<ul>"
set n_categories 0

if ![empty_string_p [lindex $category_id_list 0]] {
    set category_name_list [database_to_tcl_list $db "select category from categories where category_id in ([join $category_id_list ", "]) order by category"]

    foreach category_name $category_name_list {
	incr n_categories
	if ![empty_string_p $category_name] {
	    append category_list "<li> $category_name"
	}
    }
}

ns_db releasehandle $db

if { $n_categories == 0 } {
    append category_list "<li><i>None</i>"
}
append category_list "</ul>"

set approval_policy [ad_parameter DefaultLinkApprovalPolicy]
if { $approval_policy != "open" } {
    set approval_text "<p><i>Your link must be approved by an administrator before it becomes visible to users.</i>"
} else {
    set approval_text ""
}

set rating_html "<select name=rating>"
set current_rating 0
while { $current_rating <= 10 } {
    append rating_html "<option type=radio name=rating value=\"$current_rating\">$current_rating "
    
    incr current_rating
}
append rating_html "</select>"

ns_write "
Here is how your link will appear:

<blockquote>
<a href=\"$url\"><b>$link_title</b></a> - <b>No ratings</b> - more (<i>This will link to additional features about the link</i>)

<p>It will be associated with the following categories:
$category_list
$approval_text
<form action=\"link-add-4.tcl\" method=post>
[export_form_vars on_which_table on_what_id module return_url link_id association_id link_title url link_description category_id_list item]
Please rate this link:
$rating_html
</blockquote>
<p>
<center>
<input type=submit name=submit value=\"Confirm Link Addition\">
</center>
</form>

[ad_footer]
"


