# /www/admin/gc/delete-ad.tcl
ad_page_contract {
    Lets the site administrator delete a user's classified ad.

    @param classified_ad_id which classified ad

    @author philg@mit.edu
    @cvs_id delete-ad.tcl,v 3.4.2.4 2000/09/22 01:35:20 kevin Exp
} {
    classified_ad_id:integer
}

set admin_id [ad_verify_and_get_user_id]

if { $admin_id == 0 } {
    ad_returnredirect "/register/"
    return
}



if {![db_0or1row ad_info "select ca.one_line, ca.full_ad, ca.domain_id, ad.domain, u.user_id, u.email, u.first_names, u.last_name
from classified_ads ca, users u, ad_domains ad
where ca.user_id = u.user_id
and ad.domain_id = ca.domain_id
and classified_ad_id = :classified_ad_id"]} {

    ad_return_error "Could not find Ad $classified_ad_id" "Either you are fooling around with the Location field in your browser or my code has a serious bug. "
    return 
}

# OK, we found the ad in the database if we are here...

if [ad_parameter EnabledP "member-value"] {
    set mistake_wad [mv_create_user_charge $user_id  $admin_id "classified_ad_mistake" $classified_ad_id [mv_rate ClassifiedAdMistakeRate]]
    set spam_wad [mv_create_user_charge $user_id $admin_id "classified_ad_spam" $classified_ad_id [mv_rate ClassifiedAdSpamRate]]
    set options [list [list "" "Don't charge user"] [list $mistake_wad "Mistake of some kind, e.g., duplicate posting"] [list $spam_wad "Spam or other serious policy violation"]]
    set member_value_section "<h3>Charge this user for his sins?</h3>
<select name=user_charge>\n"
    foreach sublist $options {
	set value [lindex $sublist 0]
	set visible_value [lindex $sublist 1]
	append member_value_section "<option value=\"[philg_quote_double_quotes $value]\">$visible_value\n"
    }
    append member_value_section "</select>
<br>
<br>
Charge Comment:  <input type=text name=charge_comment size=50>
<br>
<br>
<br>"
} else {
    set member_value_section ""
}


set page_content "[gc_header "Confirm Deletion"]

<h2>Confirm Deletion</h2>

of ad number $classified_ad_id in the
 <a href=\"domain-top?domain_id=$domain_id\"> $domain domain of [gc_system_name]</a>

<hr>

<form method=POST action=delete-ad-2>
[export_form_vars classified_ad_id]
$member_value_section
<P>
<center>
<input type=submit value=\"Yes, delete this ad.\">
</center>
</form>

<h3>$one_line</h3>

<blockquote>
$full_ad
<br>
<br>
-- <a href=\"/admin/users/one?user_id=$user_id\">$first_names $last_name</a> 
(<a href=\"mailto:$email\">$email</a>)
</blockquote>

[ad_admin_footer]"


doc_return  200 text/html $page_content