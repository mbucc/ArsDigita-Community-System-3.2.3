# www/admin/calendar/post-edit-2.tcl
ad_page_contract {
    Performs an update on a calendar item

    Number of queries: 1
    Number of dml: 1

    @author Philip Greenspun (philg@mit.edu)
    @author Sarah Ahmed (ahmeds@arsdigita.com)
    @creation-date 1998-11-18
    @cvs-id post-edit-2.tcl,v 3.2.2.3 2000/07/21 03:56:11 ron Exp
    
} {
    calendar_id:naturalnum
    category_id:naturalnum
    title
    body:allhtml
    html_p
    event_url
    event_email
    country_code
    {usps_abbrev ""}
    {zip_code ""}
}

# category_id, calendar_id, title, body, AOLserver ns_db magic vars that can be 
# kludged together to form release_date and expiration_date


if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

set user_id [ad_get_user_id]
if { $user_id == 0 } {
    ad_returnredirect "/register/index.tcl"
    return
}



set exception_count 0
set exception_text ""



## Check for Naughty Input
if { $html_p && ![empty_string_p [ad_check_for_naughty_html $body]] } {

    set naughty_tag_list [ad_parameter_all_values_as_list NaughtyTag antispam]
    set naughty_tag_string [join $naughty_tag_list " "]
    
    ## I like exception_text so much better than scope_error or whatever crap it used to be -MJS

    incr exception_count
    append exception_text "You attempted to submit one of these forbidden HTML tags: $naughty_tag_string"
    return
}





if [catch  { 

    ns_dbformvalue [ns_conn form] start_date date start_date         
    ns_dbformvalue [ns_conn form] end_date date end_date 
    
} errmsg] {
    
    incr exception_count
    append exception_text "<li>Please make sure your dates are valid."
    
} else {

    
    # we assume that the event ends at the very end of the end_date
    # we have to do the bogus 1000* and then rounding because of Stupid Oracle
    # driver truncation errors (doesn't like big fractions)

    set end_date_with_time "$end_date  11:59:59"

    set query_expire "select round(1000*(to_date(:end_date_with_time, 'YYYY-MM-DD HH24:MI:SS')  - to_date(:start_date, 'YYYY-MM-DD')))  from dual"

    set expire_laterthan_future_p [db_string expire $query_expire]

    if {$expire_laterthan_future_p <= 0} {

	incr exception_count

	append exception_text "<li>Please make sure the end date is later than the start date."
    }
}

# now start_date and end_date are set

if { ![info exists title] || $title == ""} {
    incr exception_count
    append exception_text "<li>Please enter a title."
}

if { ![info exists body] || $body == "" } {
    incr exception_count
    append exception_text "<li>Please enter the full story."
}

if { [info exists event_email] && ![empty_string_p $event_email] && ![philg_email_valid_p $event_email] } {
    incr exception_count
    append exception_text "<li>The event contact email address that you typed doesn't look right to us.  Examples of valid email addresses are 
    <ul>
    <li>Alice1234@aol.com
    <li>joe_smith@hp.com
    <li>pierre@inria.fr
    </ul>
    "
}

if { [info exists event_url] && ![philg_url_valid_p $event_url] } {
    set event_url ""
}

if {$exception_count > 0} { 
    ad_return_complaint $exception_count $exception_text
    return
}

set param_DaysFromEndToExpiration [ad_parameter DaysFromEndToExpiration calendar 3]


db_transaction {
    
    db_dml calendar_update 	{ update calendar
	set category_id = :category_id, title=:title, 
	body=:body, html_p=:html_p,
	start_date = :start_date, 
	end_date = to_date(:end_date_with_time, 'YYYY-MM-DD HH24:MI:SS'), 
	expiration_date= to_date(:end_date_with_time, 'YYYY-MM-DD HH24:MI:SS') + :param_DaysFromEndToExpiration,
	event_url = :event_url, 
	event_email = :event_email, 
	country_code = :country_code, 
	usps_abbrev = :usps_abbrev, 
	zip_code = :zip_code
	where calendar_id = :calendar_id
    }
    
} on_error {
    
    # update failed; let's see if it was because of duplicate submission
    
    ns_log Error "/calendar/admin/post-edit-2.tcl choked:  $errmsg"
    
    ad_return_error "Insert Failed" "The Database did not like what you typed.  This is probably a bug in our code.  Here's what the database said:
    <blockquote>
    <pre>
    $errmsg
    </pre>
    </blockquote>
    "
    return
}

db_release_unused_handles

ad_returnredirect "item.tcl?calendar_id=$calendar_id"

## END FILE post-edit-2.tcl