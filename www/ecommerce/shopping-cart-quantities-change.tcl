#  www/ecommerce/shopping-cart-quantities-change.tcl
ad_page_contract {

    Changes the quantity of an item in an order. An item is a unique
    combination of product_id, Color, Size, and Style. In addition,
    each item is represented by a row in the database, so changing
    quantities involves inserting and deleting rows.
    
    @quantity -- an array whose keys are tcl lists of product_id, color, size, and style
    @param return_url -- optional, probably will take the user back to process_order_quantity_shipping.tcl 
    @author original author unknown (eveander@arsdigita.com?)
    @author heavily modified by jgoler@arsdigita.com
    @author hbrock@arsdigita.com
    @creation-date
    @cvs-id shopping-cart-quantities-change.tcl,v 3.3.2.8 2000/09/22 01:37:31 kevin Exp
} {
    return_url:optional
    quantity:array,naturalnum
}


set user_session_id [ec_get_user_session_id]



if { $user_session_id == 0 } {
    doc_return  200 text/html "[ad_header "No Cart Found"]<h2>No Shopping Cart Found</h2>
    <p>
    We could not find any shopping cart for you.  This may be because you have cookies 
    turned off on your browser.  Cookies are necessary in order to have a shopping cart
    system so that we can tell which items are yours.

    <p>
    <i>In Netscape 4.0, you can enable cookies from Edit -> Preferences -> Advanced. <br>

    In Microsoft Internet Explorer 4.0, you can enable cookies from View -> 
    Internet Options -> Advanced -> Security. </i>

    <p>

    [ec_continue_shopping_options]
    "
    return
}

set order_id [db_string get_order_id "select order_id from ec_orders where order_state='in_basket' and user_session_id=:user_session_id" -default ""]

# if order_id is null, this probably means that they got to this page by pushing back
# so just return them to their empty cart

if { [empty_string_p $order_id] } {
    ad_returnredirect "shopping-cart.tcl"
    return
}

# set product_id_list [db_list get_product_ids "select unique product_id from ec_items where order_id=:order_id"]

# # if product_id_list is empty, this probably means that they got to this page by pushing back
# # so just return them to their empty cart

# if { [llength $product_id_list] == 0 } {
#     ad_returnredirect "shopping-cart.tcl"
#     return
# }

db_foreach get_products_w_attribs  "
    select i.product_id, 
           i.color_choice, 
           i.size_choice, 
           i.style_choice, 
           count(*) as r_quantity
      from ec_orders o, 
           ec_items i
     where o.order_id=i.order_id
       and o.user_session_id=:user_session_id
       and o.order_state='in_basket'
  group by i.product_id, 
           i.color_choice, 
           i.size_choice, 
           i.style_choice
         " {

    set pid_bak $product_id

    set real_quantity([list $product_id $color_choice $size_choice $style_choice]) $r_quantity
}

# You could call a transaction here, but why bother the database
# when you can just check with a foreach whether there are any passed-in
# item combinations that don't match combinations already in the database.
# If we find any such combinations, it means the user's passed in data is
# stale and we should redirect back to the shopping cart.

foreach product_color_size_style [array names quantity] {

    if { ![info exists real_quantity($product_color_size_style)] } {
	
	if { [info exists return_url] } {
	    ad_returnredirect $return_url
	} else {
	    ad_returnredirect shopping-cart.tcl
	}
	return
	    
    }
}

# quantity_to_add might be negative
# also there are two special cases that may come about, for instace,
# when a user pushes "Back" to get here after having altered their cart
# (1) if quantity($product_id) exists but real_quantity($product_id)
#     doesn't exist, then ignore it (we're going to miss that
#     product_id anyway when looping through product_id_list)
# (2) if real_quantity($product_id) exists but quantity($product_id)
#     doesn't exist then quantity_to_add will be 0

#    set product_id [lindex $product_color_size_style 0]
#    set color_choice [lindex $product_color_size_style 1]
#    set size_choice [lindex $product_color_size_style 2]
#    set style_choice [lindex $product_color_size_style 3]

	 
db_transaction {

    foreach product_color_size_style [array names quantity] {

	set quantity_to_add "[expr $quantity($product_color_size_style) - $real_quantity($product_color_size_style)]"

	set product_id [lindex $product_color_size_style 0]
	set color_choice [lindex $product_color_size_style 1]
	set size_choice [lindex $product_color_size_style 2]
	set style_choice [lindex $product_color_size_style 3]

	if { $quantity_to_add > 0 } {
	    set remaining_quantity $quantity_to_add
	    while { $remaining_quantity > 0 } {
	  
		db_dml insert_new_quantity_to_add "insert into ec_items
		(item_id, product_id, color_choice, size_choice, style_choice, order_id, in_cart_date)
		values
		(ec_item_id_sequence.nextval, :product_id, :color_choice, :size_choice, :style_choice, :order_id, sysdate)
		"
		set remaining_quantity [expr $remaining_quantity - 1]
	    }
	} elseif { $quantity_to_add < 0 } {
	    set remaining_quantity [expr abs($quantity_to_add)]
	
	    set rows_to_delete [list]
	    while { $remaining_quantity > 0 } {
	    # determine the rows to delete in ec_items (the last instance of this product within this order)
		if { [llength $rows_to_delete] > 0 } {
		    set extra_condition "and item_id not in ([join $rows_to_delete ", "])"
		} else {
		    set extra_condition ""
		}
		lappend rows_to_delete [db_string get_rows_to_delete "
         select max(item_id) 
           from ec_items 
          where product_id=:product_id
            and color_choice [ec_decode $color_choice "" "is null" "= :color_choice"]
            and size_choice [ec_decode $size_choice "" "is null" "= :size_choice"]
            and style_choice [ec_decode $style_choice "" "is null" "= :style_choice"]
            and order_id=:order_id $extra_condition
            "]

		set remaining_quantity [expr $remaining_quantity - 1]
	    }
	    db_dml delete_from_ec_items "delete from ec_items where item_id in ([join $rows_to_delete ", "])"
	}
	# otherwise, do nothing
    }
    
}

db_release_unused_handles

if { [info exists return_url] } {
    ad_returnredirect $return_url
} else {
    ad_returnredirect shopping-cart.tcl
}


