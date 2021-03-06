# /tcl/ecommerce-utilities.tcl
ad_library {

    Utilities for the ecommerce module.

    @author Eve Andersson (eveander@arsdigita.com)
    @creation-date  April, 1999
    @cvs-id ecommerce-utilities.tcl,v 3.3.2.6 2000/08/17 17:37:17 seb Exp
}

ad_proc ec_zero_if_null { the_value } { Returns Zero if Null } {
    if { [empty_string_p $the_value] } {
	return "0"
    } else {
	return $the_value
    }
}

ad_proc ec_na_if_null { the_value } { Returns N/A if Null } {
    if { [empty_string_p $the_value] } {
	return "N/A"
    } else {
	return $the_value
    }
}

ad_proc ec_nbsp_if_null {the_value} { Return nonbreaking space } {
    if { [empty_string_p $the_value] } {
	return "&nbsp;"
    } else {
	return $the_value
    }
}

ad_proc ec_pretty_price { the_price {currency ""} {zero_if_null_p "f"} } {
    returns a nicely formatted price } {  

  if { [empty_string_p $currency] } {
	set currency [ad_parameter Currency ecommerce]
    }
    if { [empty_string_p $the_price] } {
	if { $zero_if_null_p == "t" } {
	    set formatted_price "0.00"
	} else {
	    return ""
	}
    } else {
	set formatted_price [format "%0.2f" $the_price]
	# if the formatted price is negative but rounds to zero, it shows up as -0.00,
	# so in that case I'll bash it to 0.00
	if { [string compare $formatted_price "-0.00"] == 0 } {
	    set formatted_price "0.00"
	}
    }

    if { $currency == "USD" } {
	return "\$$formatted_price"
    } else {
	return "$formatted_price $currency"
    }
}

ad_proc ec_pretty_column_type { column_type } { Get Pretty Column Type } {
    if { $column_type == "integer" } {
	return "Integer"
    } elseif { $column_type == "number" } {
	return "Real Number"
    } elseif { $column_type == "date" } {
	return "Date"
    } elseif { $column_type == "varchar(200)" } {
	return "Text - Up to 200 Characters"
    } elseif { $column_type == "varchar(4000)" } {
	return "Text - Up to 4000 Characters"
    } else {
	return "Boolean (Yes or No)"
    }
}

ad_proc ec_custom_product_field_form_element { field_identifier column_type {default_value ""} } { Get Custom Form Element } {
    if { $column_type == "integer" || $column_type == "number"} {
	return "<input type=text name=\"ec_custom_fields.$field_identifier\" value=\"$default_value\" size=5>"
    } elseif { $column_type == "date" } {
	return [ad_dateentrywidget ec_custom_fields.$field_identifier $default_value]
    } elseif { $column_type == "varchar(200)" } {
	return "<input type=text name=\"ec_custom_fields.$field_identifier\" value=\"$default_value\" size=50 maxlength=200>"
    } elseif { $column_type == "varchar(4000)" } {
	return "<textarea wrap name=\"ec_custom_fields.$field_identifier\" rows=4 cols=60>$default_value</textarea>"
    } else {
	# it's boolean
	set to_return ""
	if { [string tolower $default_value] == "t" || [string tolower $default_value] == "y" || [string tolower $default_value] == "yes"} {
	    append to_return "<input type=radio name=\"ec_custom_fields.$field_identifier\" value=t checked>Yes &nbsp;"
	} else {
	    append to_return "<input type=radio name=\"ec_custom_fields.$field_identifier\" value=t>Yes &nbsp;"
	}
	if { [string tolower $default_value] == "f" || [string tolower $default_value] == "n" || [string tolower $default_value] == "no"} {
	    append to_return "<input type=radio name=\"ec_custom_fields.$field_identifier\" value=f checked>No"
	} else {
	    append to_return "<input type=radio name=\"ec_custom_fields.$field_identifier\" value=f>No"
	}
	return $to_return
    }
}

# the_value should just be a number (no percent sign)
ad_proc ec_percent_to_decimal { the_value } { Converts PCT to dec equiv } {
    if { [empty_string_p $the_value] } {
	return ""
    } else {
	return [expr double($the_value)/100]
    }
}

# the value returned is just a number (no percent sign)
ad_proc ec_decimal_to_percent { the_decimal_number } { Converts dec to pct } {
    if { [empty_string_p $the_decimal_number] } {
	return ""
    } else {
	return [expr $the_decimal_number * 100]
    }
}

ad_proc ec_message_if_null { the_value } { Give Null Message } {
    if { [empty_string_p $the_value] } {
	return "None Defined"
    } else {
	return $the_value
    }
}


ad_proc ec_choose_n_random {choices_list n_to_choose chosen_list} { Get Random Choices } {
    if { $n_to_choose == 0 } {  return $chosen_list    } else {
        set chosen_index [randomRange [llength $choices_list]]
        set new_chosen_list [lappend chosen_list [lindex $choices_list $chosen_index]]
        set new_n_to_choose [expr $n_to_choose - 1]
        set new_choices_list [lreplace $choices_list $chosen_index $chosen_index]
        return [ec_choose_n_random $new_choices_list $new_n_to_choose $new_chosen_list]
    }   
}

ad_proc ec_generate_random_string { {string_length 10} } { Returns a random string } {
    # leave out characters that might be confusing like l and 1, O and 0, etc.
    set choices "ABCDEFGHIJKLMNPQRSTUVWXYZabcdefghijmnopqrstuvwxyz23456789"
    set choices_length [string length $choices]
    set random_string ""
    for {set i 0} {$i < $string_length} {incr i} {
	set chosen_index [randomRange $choices_length]
	append random_string [string index $choices $chosen_index]
    }
    return $random_string
} 

ad_proc ec_PrettyBoolean {t_or_f} { Returns Yes or No instead of t/f } {
    if { $t_or_f == "t" || $t_or_f == "T" } {
	return "Yes"
    } elseif { $t_or_f == "f" || $t_or_f == "F" } {
	return "No"
    } else {
	return ""
    }
}

ad_proc ec_display_as_html { text_to_display } { Formats text as HTML } {
    regsub -all "\\&" $text_to_display "\\&amp;" html_text
    regsub -all "\>" $html_text "\\&gt;" html_text
    regsub -all "\<" $html_text "\\&lt;" html_text
    regsub -all "\n" $html_text "<br>\n" html_text
    # get rid of stupid ^M's
    regsub -all "\r" $html_text "" html_text
    return $html_text
}


ad_proc ec_linked_thumbnail_if_it_exists { dirname {border_p "t"} {link_to_product_p "f"} } { 
This looks at dirname to see if the thumbnail is there and if
 so returns an html fragment that links to the bigger version
 of the picture (or to product.tcl if link_to_product_p is "t").
Otherwise it returns the empty string. } {

    set linked_thumbnail ""

    if { $border_p == "f" } {
	set border_part_of_img_tag " border=0 "
    } else {
	set border_part_of_img_tag ""
    }

    # see if there's an image file (and thumbnail)

    # Get the directory where dirname is stored
    regsub -all {[a-zA-Z]} $dirname "" product_id
    set subdirectory [ec_product_file_directory $product_id]
    set file_path "$subdirectory/$dirname"
    set product_data_directory "[ad_parameter EcommerceDataDirectory ecommerce][ad_parameter ProductDataDirectory ecommerce]"

    set full_dirname "$product_data_directory$file_path"

    if { [file exists "$full_dirname/product-thumbnail.jpg"] } {
	set thumbnail_size [ns_jpegsize "$full_dirname/product-thumbnail.jpg"]

	if { $link_to_product_p == "f" } {
	    # try to link to a product.jpg or product.gif

	    if { [file exists "$full_dirname/product.jpg"] } {
		set linked_thumbnail "<a href=\"/product-file/$file_path/product.jpg\"><img $border_part_of_img_tag width=[lindex $thumbnail_size 0] height=[lindex $thumbnail_size 1] src=\"/product-file/$file_path/product-thumbnail.jpg\"></a>"
	    } elseif { [file exists "$full_dirname/product.gif"] } {
		set linked_thumbnail "<a href=\"/product-file/$file_path/product.gif\"><img $border_part_of_img_tag width=[lindex $thumbnail_size 0] height=[lindex $thumbnail_size 1] src=\"/product-file/$file_path/product-thumbnail.jpg\"></a>"
	    }
	} else {
	    set linked_thumbnail "<a href=\"product?[export_url_vars product_id]\"><img $border_part_of_img_tag width=[lindex $thumbnail_size 0] height=[lindex $thumbnail_size 1] src=\"/product-file/$file_path/product-thumbnail.jpg\"></a>"
	}
    }

    return $linked_thumbnail
}

ad_proc ec_best_price { product_id } { Returns the minimum price offered } {
    return [db_string get_min_price "select min(price) from ec_offers where product_id=:product_id"]
}

ad_proc ec_savings { product_id } { Returns savings over Retail price } {
    set retailprice [db_string get_retailprice "select retailprice from ec_custom_product_field_values where product_id=:product_id" -default ""]
    set bestprice [db_string get_best_price "select min(price) from ec_offers where product_id=:product_id"]
    if { ![empty_string_p $retailprice] && ![empty_string_p $bestprice] } {
	set savings [expr $retailprice - $bestprice]
    } else {
	set savings ""
    }
    return $savings
}

ad_proc ec_date_with_time_stripped { the_date } {Removes the time part of the date stamp (useful when using util_AnsiDatetoPrettyDate)} {
    if { [regexp {[^\ ]+} $the_date stripped_date ] } {
	return $stripped_date
    } else {
	# if the date isn't formatted like YYYY-MM-DD HH:MI:SS, then just return what we got in
	return $the_date
    }
}

ad_proc ec_user_audit_info { } {Returns User ID, IP Address, and date for audit trails} {
    return [list $user_id [ns_conn peeraddr] sysdate]
}

ad_proc ec_get_user_session_id {} { Gets the user session from cookies } {
    set headers [ns_conn headers]
    set cookie [ns_set get $headers Cookie]
    # grab the user_session_id from the cookie
    if { [regexp {user_session_id=([^;]+)} $cookie match user_session_id] } {
	return $user_session_id
    } else {
	return 0
    }
}

ad_proc ec_pretty_creditcard_type { creditcard_type } "Returns the credit card type based on the one-or-two-letter code for that type." {
    if { $creditcard_type == "a" || $creditcard_type == "ax"} {
	return "American Express"
    } elseif { $creditcard_type == "v" || $creditcard_type == "vs"} {
	return "Visa"
    } elseif { $creditcard_type == "m" || $creditcard_type == "mc"} {
	return "MasterCard"
    } else {
	return "Unknown"
    }
}


ad_proc ec_decode {args}  {  like decode in sql
 Takes the place of an if (or switch) statement -- convenient because it's compact and
 you don't have to break out of an append doc_body if you're in one.
 args: same order as in sql: first the unknown value, then any number of pairs denoting
 if the unknown value is equal to first element of pair, then return second element, then
if the unknown value is not equal to any of the first elements, return the last arg } {
    set args_length [llength $args]
    set unknown_value [lindex $args 0]
    
    # we want to skip the first & last values of args
    set counter 1
    while { $counter < [expr $args_length -2] } {
	if { [string compare $unknown_value [lindex $args $counter]] == 0 } {
	    return [lindex $args [expr $counter + 1]]
	}
	set counter [expr $counter + 2]
    }
    return [lindex $args [expr $args_length -1]]
}

ad_proc ec_last_second_in_the_day { the_date } "Returns the last second of the given day's date.  Input date should be in format YYYY-MM-DD HH24:MI:SS or YYYY-MM-DD." {
    regexp {^(....)-(..)-(..)} $the_date garbage year month day
    return "$year-$month-$day 23:59:59"
}

ad_proc ec_user_identification_summary { user_identification_id {link_to_new_window_p "f"} } { Get user Info } {
    if { $link_to_new_window_p == "t" } {
	set target_tag "target=user_window"
    } else {
	set target_tag ""
    }
    if { [db_0or1row get_row_exists "select user_id,first_names,last_name,email,other_id_info,postal_code from ec_user_identification where user_identification_id=:user_identification_id"]==0 } {

	return ""
    }
    
    if { ![empty_string_p $user_id] } {
	set user_name [db_string get_user_name "select first_names || ' ' || last_name from users where user_id=:user_id"]
	return "Registered user: <a $target_tag href=\"/admin/users/one?user_id=$user_id\">$user_name</a>."
    }

    set name_part_to_return ""
    if { ![empty_string_p $first_names] && ![empty_string_p $last_name] } {
	set name_part_to_return "Name: $first_names $last_name. "
    } elseif { ![empty_string_p $first_names] } {
	set name_part_to_return "First name: $first_names. "
    } elseif { ![empty_string_p $last_name] } {
	set name_part_to_return "Last name: $last_name. "
    }

    set email_part_to_return ""
    if { ![empty_string_p $email] } {
	set email_part_to_return "Email: $email. "
    }

    set postal_code_part_to_return ""
    if { ![empty_string_p $postal_code] } {
	set postal_code_part_to_return "Zip code: $postal_code. "
    }

    set other_id_info_part_to_return ""
    if { ![empty_string_p $other_id_info] } {
	set other_id_info_part_to_return "Other identifying info: $other_id_info"
    }

    set link_part_to_return " (<a $target_tag href=\"user-identification?user_identification_id=$user_identification_id\">user info</a>)"

    return "$name_part_to_return $email_part_to_return $postal_code_part_to_return $other_id_info_part_to_return $link_part_to_return"
}

ad_proc ec_export_entire_form_except args { Exports all but part of a form } {
    # exports entire form except the variables specified in args
    set hidden ""
    set the_form [ns_getform]
    for {set i 0} {$i<[ns_set size $the_form]} {incr i} {
        set varname [ns_set key $the_form $i]
	if { [lsearch -exact $args $varname] == -1 } {
	    set varvalue [ns_set value $the_form $i]
	    append hidden "<input type=hidden name=\"$varname\" value=\"[ad_quotehtml $varvalue]\">\n"
	}
    }
    return $hidden
}

# ugly_date should be in the format YYYY-MM-DD HH24:MI:SS
ad_proc ec_formatted_full_date { ugly_date } { Format Ugly Date to Pretty } {
    return "[util_AnsiDatetoPrettyDate [lindex [split $ugly_date " "] 0]] [lindex [split $ugly_date " "] 1]"
}

# ugly_date shoud be in the format YYYY-MM-DD HH24:MI:SS or just YYYY-MM-DD
ad_proc ec_formatted_date { ugly_date } { Format Ugly Date } {
    set split_date [split $ugly_date " "]
    if { [llength $split_date] == 1 } {
	return [util_AnsiDatetoPrettyDate $ugly_date]
    } else {
	return [ec_formatted_full_date $ugly_date]
    }
}

ad_proc ec_location_based_on_zip_code { zip_code } { Get location } {
        set sql "select state_code, city_name, county_name from zip_codes where zip_code=:zip_code"
    
    set city_list [list]
    if { [catch {
    db_foreach get_city_list $sql {
	
	lappend city_list "$city_name, $county_name County, $state_code"
}   } errmsg] } { return "Zip Code Table Not Installed" }
    
    return "[join $city_list " or "]"
}

ad_proc ec_pretty_mailing_address_from_args { line1 line2 city usps_abbrev zip_code country_code full_state_name attn phone phone_time } { get Pretty Mailing Address } {

    set lines [list $attn]
    if [empty_string_p $line2] {
	lappend lines $line1
    } elseif [empty_string_p $line1] {
	lappend lines $line2
    } else {
	lappend lines $line1
	lappend lines $line2
    }

    if { ![empty_string_p $country_code] && $country_code != "us" } {
	lappend lines "$city, $full_state_name $zip_code"

	lappend lines [ad_country_name_from_country_code $country_code]
    } else {
	lappend lines "$city, $usps_abbrev $zip_code"
    }

    lappend lines "$phone ([ec_decode $phone_time "D" "day" "E" "evening" ""])"
  
  return [join $lines "\n"]
}

ad_proc ec_pretty_mailing_address_from_ec_addresses { address_id } { Gets Pretty Mailing Address } {
    if { [empty_string_p $address_id] } {
	return ""
    }

    if { [db_0or1row get_row_exists_p "select line1, line2, city, usps_abbrev, zip_code, country_code, full_state_name, attn, phone, phone_time from ec_addresses where address_id=:address_id"]==0 } {
	return ""
      }
      
    return [ec_pretty_mailing_address_from_args $line1 $line2 $city $usps_abbrev $zip_code $country_code $full_state_name $attn $phone $phone_time]
}

ad_proc ec_creditcard_summary { creditcard_id } { Returns Credit Card info } {
  
    if {  [db_0or1row get_creditcard_summary "select creditcard_type, creditcard_last_four, creditcard_expire, billing_zip_code from ec_creditcards where creditcard_id=:creditcard_id"] == 0 } {
	return ""
    }
    return "[ec_pretty_creditcard_type $creditcard_type]\nxxxxxxxxxxxx$creditcard_last_four\nexp: $creditcard_expire\nzip: $billing_zip_code"
}

ad_proc ec_elements_of_list_a_that_arent_in_list_b { list_a list_b } { Do a check and return list of a that are not in b } {
    set list_to_return [list]
    foreach list_a_element $list_a {
	if { [lsearch -exact $list_b $list_a_element] == -1 } {
	    lappend list_to_return $list_a_element
	}
    }
    return $list_to_return
}

ad_proc ec_first_element_of_list_a_that_isnt_in_list_b { list_a list_b } { Get First Element of A not in B} {
    foreach list_a_element $list_a {
	if { [lsearch -exact $list_b $list_a_element] == -1 } {
	    return $list_a_element
	}
    }
    return ""
}

# Gets the start and end date when the dates are supplied by ec_report_date_range_widget;
# if they're not supplied, it makes the first of this month be the start date and today
# be the end date.
# This proc uses uplevel and assumes the existence of db.
# If the date is supplied incorrectly or not supplied at all, it just returns the default
# dates (above), unless return_date_error_p (in the calling environment) is "t", in which case
# it returns 0
ad_proc ec_report_get_start_date_and_end_date { } { Report Get Start and End Date from Widgets } {
    uplevel {

	# get rid of leading zeroes in start%5fdate.day and
	# end%5fdate.day because it can't interpret 08 and
	# 09 (It thinks they're octal numbers)

	if { [info exists "start%5fdate.day"] } {
	    set "start%5fdate.day" [string trimleft [set "start%5fdate.day"] "0"]
	    set "end%5fdate.day" [string trimleft [set "end%5fdate.day"] "0"]
	    ns_set update $form "start%5fdate.day" [set start%5fdate.day]
	    ns_set update $form "end%5fdate.day" [set end%5fdate.day]
	}

	
	set current_year [ns_fmttime [ns_time] "%Y"]
	set current_month [ns_fmttime [ns_time] "%m"]
	set current_date [ns_fmttime [ns_time] "%d"]

	# it there's no time connected to the date, just the date argument to ns_dbformvalue,
	# otherwise use the datetime argument
	if [catch  { ns_dbformvalue [ns_conn form] start_date date start_date} errmsg ] {
	    if { ![info exists return_date_error_p] || $return_date_error_p == "f" } {
		set start_date "$current_year-$current_month-01"
	    } else {
		set start_date "0"
	    }    
	}
	if [catch  { ns_dbformvalue [ns_conn form] end_date date end_date} errmsg ] {
	    if { ![info exists return_date_error_p] || $return_date_error_p == "f" } {
		set end_date "$current_year-$current_month-$current_date"
	    } else {
		set end_date "0"
	    }
	}
	
	if { [string compare $start_date ""] == 0 } {
	    if { ![info exists return_date_error_p] || $return_date_error_p == "f" } {
		set start_date "$current_year-$current_month-01"
	    } else {
		set start_date "0"
	    }
	}
	if { [string compare $end_date ""] == 0 } {
	    if { ![info exists return_date_error_p] || $return_date_error_p == "f" } {
		set end_date "$current_year-$current_month-$current_date"
	    } else {
		set end_date "0"
	    }
	}
    }
}


ad_proc ec_order_status {  order_id } {  returns the status of the order for the customer } {
    # check shipping_method to see whether this was a shippable order
    set shippable_p [db_string get_shippable_p "select decode(shipping_method,'no shipping',0,1) as shippable_p from ec_orders where order_id=:order_id"]

    # we have to look at individual items
    set n_shipped_items 0
    set n_received_back_items 0
    set n_total_items 0
    set sql "select item_state, count(*) as n_items
    from ec_items
    where order_id=$order_id
    group by item_state"
    db_foreach get_individual_items $sql {
	
	if { $item_state == "shipped" || $item_state == "arrived" } {
	    set n_shipped_items [expr $n_shipped_items + $n_items]
	} elseif { $item_state == "received_back" } {
	    set n_received_back_items $n_items
	}
	set n_total_items [expr $n_total_items + $n_items]
    }
    # Possible combinations:
    # returned | shipped | blank | order status
    # ---------|---------|-------|-------------
    #   all         0        0     All Items Returned
    #    0         all       0     All Items Shipped
    #    0          0       all    In Progress
    #   some       some     some   Some Items Returned
    #   some       some      0     Some Items Returned
    #    0         some     some   Partial Shipment Made
    #   some        0       some   Some Items Returned
    # * Note: some of the above wording is changed if it
    #   is a non shippable order

    if { $n_shipped_items == $n_total_items } {
        if { $shippable_p } {
	    return "All Items Shipped"
	} else {
	    return "All Items Fullfilled"
	}
    } elseif { $n_received_back_items == $n_total_items } {
	return "All Items Returned"
    } elseif { $n_shipped_items == 0 && $n_received_back_items == 0 } {
	return "In Progress"
    } elseif { $n_received_back_items > 0 } {
	return "Some Items Returned"
    } elseif { $n_shipped_items > 0 } {
	return "Partial Shipment Made"
    } else {
	return "Unknown" 
    }
}


ad_proc ec_gift_certificate_status { gift_certificate_id } { 
    returns the status of the gift certificate for the customer } {
    db_1row get_gift_certificate_info "select 
    gift_certificate_state, user_id
    from ec_gift_certificates
    where gift_certificate_id=:gift_certificate_id"

    
    
    if { $gift_certificate_state == "confirmed" } {
	return "Not Yet Authorized"
    }

    if { $gift_certificate_state == "failed_authorization" } {
	return "Failed Authorization"
    }

    if { $gift_certificate_state == "authorized_plus_avs" || $gift_certificate_state == "authorized_minus_avs" } {
	if { [empty_string_p $user_id] } {
	    return "Authorized (not yet claimed)"
	} else {
	    return "Claimed by Recipient"
	}
    }
    
    if { $gift_certificate_state == "void" } {
	return "Void"
    }

    return "Unknown"
}

# returns a if a>=b or b if b>a
proc ec_max { a b } {
    if { $a >= $b } {
	return $a
    } else {
	return $b
    }
}

proc ec_min { a b } {
    if { $a >= $b } {
	return $b
    } else {
	return $a
    }
}

ad_proc ec_product_file_directory { product_id } "Returns the directory that that the product files are located under the ecommerce product data directory. This is the two lowest order digits of the product_id." {
    set id_length [string length $product_id]

    if { $id_length == 1 } {
	# zero pad the product_id
	return "0$product_id"
    } else {
	# return the lowest two digits
	return [string range $product_id [expr $id_length - 2] [expr $id_length - 1]]
    }
}

ad_proc ec_assert_directory {dir_path} "Checks that directory exists, if not creates it" {
    if { [file exists $dir_path] } {
	# Everything okay
	return 1
    } else {
	ns_mkdir $dir_path
	return 1
    }
}

ad_proc ec_leading_zeros {the_integer n_desired_digits} "Adds leading zeros to an integer to give it the desired number of digits" {
    return [format "%0${n_desired_digits}d" $the_integer]
}

ad_proc ec_leading_nbsp {the_integer n_desired_digits} "Adds leading nbsps to an integer to give it the desired number of digits" {
    set n_digits_to_add [expr $n_desired_digits - [string length $the_integer]]
    if {$n_digits_to_add <= 0} {
	return $the_integer
    } else {
	return [ec_leading_zeros "&nbsp;&nbsp;$the_integer" $n_desired_digits]
    }
}


