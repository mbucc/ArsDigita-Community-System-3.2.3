# $Id: recommendation-text-edit-2.tcl,v 3.0.4.1 2000/04/28 15:08:53 carsten Exp $
# recommendation-text-edit-2.tcl
#
# by philg@mit.edu on July 18, 1999
#
# actually updates the row
# 

set_the_usual_form_variables

# recommendation_id, recommendation_text

# we need them to be logged in
set user_id [ad_verify_and_get_user_id]

if {$user_id == 0} {
    
    set return_url "[ns_conn url]?[export_entire_form_as_url_vars]"

    ad_returnredirect "/register.tcl?[export_url_vars return_url]"
    return
}

set db [ns_db gethandle]

ns_db dml $db "update ec_product_recommendations 
set recommendation_text = '$QQrecommendation_text', last_modified=sysdate, last_modifying_user='$user_id', modified_ip_address='[DoubleApos [ns_conn peeraddr]]'
where recommendation_id=$recommendation_id"

ad_returnredirect "recommendation.tcl?[export_url_vars recommendation_id]"
