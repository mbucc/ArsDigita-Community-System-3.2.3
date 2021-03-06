#  www/admin/ecommerce/products/supporting-file-delete.tcl
ad_page_contract {
  Confirm delete of a file.

  @author Eve Andersson (eveander@arsdigita.com)
  @creation-date Summer 1999
  @cvs-id supporting-file-delete.tcl,v 3.2.2.1 2000/07/22 07:57:46 ron Exp
} {
  product_id:integer,notnull
  file
}

set product_name [ec_product_name $product_id]

doc_body_append "[ad_admin_header "Delete Supporting File for $product_name"]

<h2>Delete Supporting File for $product_name</h2>

[ad_admin_context_bar [list "../" "Ecommerce"] [list "index.tcl" "Products"] [list "one.tcl?[export_url_vars product_id]" $product_name] "Delete Supporting File"]

<hr>

Please confirm that you wish to delete this file.
"

if { $file == "product-thumbnail.jpg" } {
    doc_body_append "Note: this file is the thumbnail picture of the product.  If you delete it, the customer will not be able to see what the product looks like."
}

doc_body_append "<form method=post action=supporting-file-delete-2>
[export_form_vars file product_id]
<center>
<input type=submit value=\"Confirm\">
</center>
</form>

[ad_admin_footer]
"