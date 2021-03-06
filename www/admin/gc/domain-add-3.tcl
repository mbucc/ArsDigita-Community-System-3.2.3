# domain-add-3.tcl

ad_page_contract {
    @author
    @creation-date
    @cvs-id domain-add-3.tcl,v 3.3.2.5 2001/01/10 18:54:43 khy Exp
} {
    domain_id:integer,notnull,verify
    domain
    insert_form_fragments:allhtml
    default_expiration_days 
    wtb_common_p
    auction_p
    geocentric_p
    submit
}

# user error checking

set exception_text ""
set exception_count 0

if { [info exists insert_for_fragments] && [string length $insert_form_fragments] > 4000 } {
    incr exception_count
    append exception_text "<li>Please limit you form fragment for ad parameters to 4000 characters."
}

if { $exception_count > 0 } { 
  ad_return_complaint $exception_count $exception_text
  return
}

ns_set delkey [ns_conn form] submit

set sql_statement_and_bind_vars [util_prepare_update ad_domains domain_id $domain_id [ns_conn form]]
set sql_statement [lindex $sql_statement_and_bind_vars 0]
set bind_vars [lindex $sql_statement_and_bind_vars 1]

if [catch { db_dml domain_add $sql_statement -bind $bind_vars} errmsg] {
	    ad_return_error "Failure to update domain information" "The database rejected the attempt:
	    <blockquote>
    <pre>
    $errmsg
    </pre>
    </blockquote>
    "
    return
}

db_release_unused_handles

ad_returnredirect "index.tcl"
