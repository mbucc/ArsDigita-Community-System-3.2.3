# /www/ticket/admin/domain-change-group.tcl
ad_page_contract {
    Change the group associated with a domain

    @param domain_id the ID of the project
    @param domain_name why this is passed in instead of pulled from the
           DB, I could not tell you
    @param group_id ID for the new group
    @param GS.group_type_restrict a variable that it doesn't seem is
           used anywhere this page is called
    @param GS.group_search a similarly superfluous looking variable

    @author original author unknown
    @author Kevin Scaldeferri (kevin@caltech.edu)
    @cvs-id domain-change-group.tcl,v 3.2.6.5 2000/09/22 01:39:25 kevin Exp
} {
    domain_id:integer,notnull
    {domain_name ""}
    {group_id:integer ""}
    {GS.group_type_restrict ""}
    {GS.group_search ""}
}
    
# -----------------------------------------------------------------------------

if {[empty_string_p $group_id]} { 
    # get one

    if {![empty_string_p $domain_name]} { 
        set title "Change owning group for $domain_name"
    } else { 
        set title "Change owning group for Domain ID $domain_id"
    }

    set context [list \
                     [list "/ticket/" "Ticket Tracker"] \
                     [list "/ticket/admin/" "Administration"] \
                     [list "/ticket/admin/domain-edit.tcl?domain_id=$domain_id" "Edit feature area"] \
                     [list {} "Change owning group"] ]

    
    set out "[ad_header $title]
 <h2>$title</h2>
 [ticket_context $context]
 <hr>
 [ticket_group_pick_widget ${GS.group_search} ${GS.group_type_restrict} "domain-change-group.tcl?domain_id=$domain_id&group_id="]
 [ad_footer]"
    
    doc_return  200 text/html $out
} else { 
    # got a group_id so update o rama

    db_dml group_update "
    update ticket_domains set group_id = :group_id 
    where domain_id = :domain_id" 

    ad_returnredirect "/ticket/admin/domain-edit.tcl?domain_id=$domain_id"
}
    
