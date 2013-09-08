#  www/admin/ecommerce/problems/resolve-2.tcl
ad_page_contract {
  This page confirms that a problems in the problem log is resolved.

  @author Jesse (jkoontz@arsdigita.com)
  @creation-date July 21, 1999
  @cvs-id resolve-2.tcl,v 3.1.6.3 2000/08/18 21:46:58 stevenp Exp
} {
  problem_id:integer,notnull
}

# we need them to be logged in
set user_id [ad_verify_and_get_user_id]

if {$user_id == 0} {
    
    set return_url "[ad_conn url]?[export_entire_form_as_url_vars]"

    ad_returnredirect "/register.tcl?[export_url_vars return_url]"
    return
}



db_dml unused "update ec_problems_log set resolved_by=:user_id, resolved_date=sysdate where problem_id = :problem_id"

ad_returnredirect index.tcl
