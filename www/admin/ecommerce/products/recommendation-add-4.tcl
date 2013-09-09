#  www/admin/ecommerce/products/recommendation-add-4.tcl
ad_page_contract {
  Recommend a product.

  @author eveander@arsdigita.com
  @creation-date Summer 1999
  @cvs-id recommendation-add-4.tcl,v 3.1.6.3 2001/01/12 18:47:37 khy Exp
} {
  product_id:integer,notnull
  user_class_id:integer
  recommendation_text:html
  recommendation_id:integer,notnull,verify
  categorization
}

# we need them to be logged in
ad_maybe_redirect_for_registration
set user_id [ad_get_user_id]

# we only want to insert this into the last level of the categorization
set category_id ""
set subcategory_id ""
set subsubcategory_id ""
if { [llength $categorization] == 1 } {
    set category_id [lindex $categorization 0]
} elseif { [llength $categorization] == 2 } {
    set subcategory_id [lindex $categorization 1]
} elseif { [llength $categorization] == 3 } {
    set subsubcategory_id [lindex $categorization 2]
}

# see if recommendation is already in the database, in which case they
# pushed submit twice, so just redirect

set n_occurrences [db_string n_occurrences_select "select count(*) from ec_product_recommendations where recommendation_id=:recommendation_id"]

if { $n_occurrences > 0 } {
    ad_returnredirect "recommendations.tcl"
    return
}

set peeraddr [ns_conn peeraddr]

db_dml recommendation_insert "insert into ec_product_recommendations
(recommendation_id, product_id, user_class_id, recommendation_text, active_p, category_id, subcategory_id, subsubcategory_id, 
last_modified, last_modifying_user, modified_ip_address)
values
(:recommendation_id, :product_id, :user_class_id, :recommendation_text, 't', :category_id, :subcategory_id, :subsubcategory_id,
sysdate, :user_id, :peeraddr)
"

ad_returnredirect "recommendations.tcl"
