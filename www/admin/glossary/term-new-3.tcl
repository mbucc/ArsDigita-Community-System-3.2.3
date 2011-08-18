# $Id: term-new-3.tcl,v 3.0.4.1 2000/04/28 15:09:07 carsten Exp $
if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

set user_id [ad_verify_and_get_user_id]
if { $user_id == 0 } {
    ad_returnredirect "/register/index.tcl"
    return
}

set_the_usual_form_variables

# term, definition

set exception_count 0
set exception_text ""

set db [ns_db gethandle]

if { ![info exists term] || [empty_string_p $QQterm]} {
    incr exception_count
    append exception_text "<li>You somehow got here without entering a term to define."
}
if { ![info exists definition] || [empty_string_p $QQdefinition] } {
    incr exception_count
    append exception_text "<li>You somehow got here without entering a definition."
}
if {$exception_count > 0} { 
    ad_return_complaint $exception_count $exception_text
    return
}



if [catch { ns_db dml $db "insert into glossary
(term, definition, author, approved_p, creation_date)
values
('$QQterm', '$QQdefinition', $user_id, 't', sysdate)" } errmsg] {
    # insert failed; let's see if it was because of duplicate submission
    if { [database_to_tcl_string $db "select count(*) from glossary where term = '$QQterm'"] == 0 } {
	ns_log Error "/glossary/term-new-3.tcl choked:  $errmsg"
	ad_return_error "Insert Failed" "The Database did not like what you typed.  This is probably a bug in our code.  Here's what the database said:
<blockquote>
<pre>
$errmsg
</pre>
</blockquote>
"
        return
    }
    # we don't bother to handle the cases where there is a dupe submission
    # because the user should be thanked or redirected anyway
}

ad_returnredirect "index.tcl"
