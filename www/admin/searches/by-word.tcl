# /www/admin/searches/by-word.tcl
ad_page_contract {
    @cvs-id by-word.tcl,v 3.1.6.5 2000/09/22 01:36:04 kevin Exp
} {
    query_string:notnull
}

set page_content "[ad_admin_header "Searches for the word $query_string"]

<h2>Searches for the word <i>$query_string</i></h2>

[ad_admin_context_bar [list "index.tcl" "User Searches"] "One Query"]

<hr>
<ul>"

set sql "
select 
 query_date, 
 users.user_id, users.first_names, users.last_name,
 decode(subsection, null, search_engine_name, subsection) location, 
 decode(n_results, null, '', n_results || ' results') n_results_string
from query_strings, users
where query_strings.user_id = users.user_id (+)
and query_strings.query_string = :query_string
order by query_date desc"

set items "" 
db_foreach word_query_select $sql {
    append items "<li>$query_date: 
<a href=\"by-location?location=[ns_urlencode $location]\">$location</a>
"
    if ![empty_string_p $user_id] { 
	append items " <a href=\"/admin/users/one?user_id=$user_id\">$first_names $last_name</a> "
    }
    append items $n_results_string
}

db_release_unused_handles

append page_content $items

append page_content "</ul>
[ad_admin_footer]
"

doc_return  200 text/html $page_content

