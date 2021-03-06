#  www/ecommerce/gift-certificate.tcl
ad_page_contract {
    @param gift_certificate_id
    @param usca_p

  @author
  @creation-date
  @cvs-id gift-certificate.tcl,v 3.2.2.5 2000/08/18 21:46:33 stevenp Exp
} {
    gift_certificate_id:integer
    usca_p:optional 
}





# we need them to be logged in
set user_id [ad_verify_and_get_user_id]

if {$user_id == 0} {
    
    set return_url "[ad_conn url]?[export_entire_form_as_url_vars]"

    ad_returnredirect "/register?[export_url_vars return_url]"
    return
}



# user session tracking
set user_session_id [ec_get_user_session_id]

ec_create_new_session_if_necessary [export_url_vars gift_certificate_id]

ec_log_user_as_user_id_for_this_session

if { [db_0or1row get_gc_info "select purchased_by, amount, recipient_email, certificate_to, certificate_from, certificate_message from ec_gift_certificates where gift_certificate_id=:gift_certificate_id"] == 0} {

    set gift_certificate_summary "Invalid Gift Certificate ID"


} else {


    if { $user_id != $purchased_by } {
	set gift_certificate_summary "Invalid Gift Certificate ID"
    } else {

	set gift_certificate_summary "
	Gift Certificate #:
	$gift_certificate_id
	<p>
	Status:
	"
	
	set status [ec_gift_certificate_status $gift_certificate_id]
	
	if { $status == "Void" || $status == "Failed Authorization" } {
	    append gift_certificate_summary "<font color=red>$status</font>"
	} else {
	    append gift_certificate_summary "$status"
	}
	
	append gift_certificate_summary "<p>
	Recipient:
	$recipient_email
	<p>
	To: $certificate_to<br>
	Amount:	[ec_pretty_price $amount]<br>
	From: $certificate_from<br>
	Message: $certificate_message
	"
    }
}
db_release_unused_handles
ad_return_template

