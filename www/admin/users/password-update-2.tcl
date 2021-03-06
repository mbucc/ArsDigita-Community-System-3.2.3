ad_page_contract {
    @cvs-id password-update-2.tcl,v 3.2.2.4.2.4 2000/09/22 01:36:19 kevin Exp
} {
    user_id:integer,notnull
    first_names:notnull
    last_name:notnull
    password_1:notnull
    password_2:notnull
}


set exception_text ""
set exception_count 0

if { ![info exists password_1] || [empty_string_p $password_1] } {
    append exception_text "<li>You need to type in a password\n"
    incr exception_count
}

if { ![info exists password_2] || [empty_string_p $password_2] } {
    append exception_text "<li>You need to confirm the password that you typed.  (Type the same thing again.) \n"
    incr exception_count
}

if { [string compare $password_2 $password_1] != 0 } {
    append exception_text "<li>Your passwords don't match!  Presumably, you made a typo while entering one of them.\n"
    incr exception_count
}

if { $exception_count > 0 } {
    ad_return_complaint $exception_count $exception_text
    return
}

# If we are encrypting passwords in the database, do it now.
if  [ad_parameter EncryptPasswordsInDBP "" 0] { 
    set password_1 [ns_crypt $password_1 [ad_crypt_salt]]
}

set sql "update users set password = :password_1 where user_id = :user_id"

if [catch { db_dml password_update $sql } errmsg] {
    ad_return_error "Ouch!"  "The database choked on our update:
<blockquote>
$errmsg
</blockquote>
"
} else {

    set password $password_1
    set offer_to_email_new_password_link ""
    if {[ad_parameter EmailChangedPasswordP "" 1]} { 
	set offer_to_email_new_password_link "<a href=\"email-changed-password?[export_url_vars user_id password]\">Send user new password by email</a>"
    }


set page_content "[ad_admin_header "Password Updated"]

<h2>Password Updated</h2>

in [ad_site_home_link]

<hr>

You must inform the user of their new password as there is currently no 
other way for the user to find out.

You can return to <a href=\"one?[export_url_vars user_id]\">$first_names $last_name</a>

<p> $offer_to_email_new_password_link

[ad_admin_footer]
"


doc_return  200 text/html $page_content
}
