# $Id: one-user-constraints.tcl,v 3.0 2000/02/06 03:25:37 ron Exp $
# called from ???

set_form_variables

set show_sql_p "t"

# check arguments -----------------------------------------------------

# $object_type   REQUIRED ARGUMENT
if { ![info exists owner] } {
    ns_returnerror 500 "Missing \$owner (format: OWBER)"
    return
}

# $order   OPTIONAL ARGUMENT, BUT NEED TO SET DEFAULT
if { ![info exists order] } {
    set order "constraint_name" 
}


# arguments OK, start building page ----------------------------------------

set page_name "Constraints owned by $owner"
ReturnHeaders
set db [cassandracle_gethandle]

ns_write "

[ad_admin_header "$page_name"]

<h2>$page_name</h2>

[ad_admin_context_bar  [list "/admin/monitoring" "Monitoring"] [list "/admin/monitoring/cassandracle" "Cassandracle"] [list "/admin/monitoring/cassandracle/users/" "Users"] [list "/admin/monitoring/cassandracle/users/user-owned-constraints.tcl" "Constraints" ] "One User Constraints"]

<!-- version 1.2, 2000-01-29, Dave Abercrombie -->
<hr>
"

# build the SQL and write out as comment
set constraint_query "
-- cassandracle/users/one-user-constraints.tcl
-- get constraints
-- http://oradoc.photo.net/ora81/DOC/server.815/a67790/ch2.htm#1175
-- I include all dba_constraint columns, but comment out those which I do not need
select 
     dc.constraint_name,
     dc.table_name,
     dc.constraint_type,
     -- use decode to decode these codes!
     decode(dc.constraint_type,'C','table check constraint',
                               'P','primary key',
                               'U','unique key',
                               'R','referential integrity',
                               'V','view check option',
                               'O','view with read only',
                               'unknown') as decoded_constraint_type,
     dc.search_condition,
     dc.r_owner,
     dc.r_constraint_name,
     -- get table name so we can make a link
     dc2.table_name as r_table_name,
     dc.delete_rule,
     dc.status,
     -- dc.deferrable,
     -- dc.deferred,
     dc.validated,
     -- dc.generated,
     -- dc.bad,
     dc.last_change
from 
     dba_constraints dc,
     -- inline view for performance
     -- this drops execution time from 40+ seconds 
     -- to a couple seconds, but limits retrival to 
     -- parents of the same owner as the child (which 
     -- is probably just fine)
     (select table_name, constraint_name 
      from dba_constraints 
      where owner = '$owner') dc2
where
     -- user (Tcl) specifies table and owner
     dc.owner = '$owner'
     -- obviously need outer join here since most 
     -- constraints are NOT foreign keys
     -- note that inline view dc2 already limited to current owner
     -- so we will not get table names if they are owned by others
and  dc.r_constraint_name = dc2.constraint_name (+)
order by
     $order
"
if { [string compare $show_sql_p "t" ]==0 } {
    ns_write "<!-- $constraint_query -->\n"
}

# I do not want to show an empty table,
# so I initialize a flag to a value of "f"
# then I flip it to 't' on the first row (after doing table header)
set at_least_one_row_already_retrieved "f"

# run query (already have db handle)
set selection [ns_db select $db $constraint_query]
while { [ns_db getrow $db $selection] } {
    set_variables_after_query

    if { [string compare $at_least_one_row_already_retrieved "f"]==0 } {

        # we get here only on first row,
        # so I start the table and flip the flag

        set at_least_one_row_already_retrieved "t"

        # table title
        ns_write "<p>This user has the following constraints</p>"


        # specify output columns
        # 1
        set description_columns [list "<a href=\"./one-user-constraints.tcl?owner=$owner&order=constraint_name\">Constraint<a/>" ] 
        lappend description_columns   "<a href=\"./one-user-constraints.tcl?owner=$owner&order=table_name\">Table</a>" 
        lappend description_columns   "<a href=\"./one-user-constraints.tcl?owner=$owner&order=constraint_type\">Type</a>" 
	# can not sort on LONG
        lappend description_columns   "Condition" 
        lappend description_columns   "<a href=\"./one-user-constraints.tcl?owner=$owner&order=r_table_name\">Parent</a>" 
        lappend description_columns   "<a href=\"./one-user-constraints.tcl?owner=$owner&order=delete_rule\">Delete Rule</a>" 
        lappend description_columns   "<a href=\"./one-user-constraints.tcl?owner=$owner&order=Status\">Status</a>" 
        lappend description_columns   "<a href=\"./one-user-constraints.tcl?owner=$owner&order=validated\">Validity</a>" 
        lappend description_columns   "<a href=\"./one-user-constraints.tcl?owner=$owner&order=last_change\">Changed</a>" 
        set column_html ""
        foreach column_heading $description_columns {
            append column_html "<th>$column_heading</th>"
        }

        # begin main table
        ns_write "
        <table border=1>
        <tr>$column_html</tr>
        "

    # end of first row tricks
    }

    # start row
    set row_html "<tr>\n"

    # 1) constraint_name
    append row_html "   <td>$constraint_name</td>\n"

    # 2) table_name - set lower case LINK since not in cut-and-paste
    set table_name "<a href=\"../objects/describe-table.tcl?object_name=$owner.$table_name\#constraints\">[string tolower $table_name]</a>"
    append row_html "   <td>$table_name</td>\n"

    # 3) decoded_constraint_type - set lower case since not on cut-paste-paste
    set decoded_constraint_type [string tolower $decoded_constraint_type]
    append row_html "   <td>$decoded_constraint_type</td>\n"

    # 4) search_condition - replace with non-breaking space if null
    if { [empty_string_p $search_condition] } {
	set search_condition "&nbsp;"
    } 
    append row_html "   <td>$search_condition</td>\n"

    # 5) r_table_name - replace with non-breaking space if null
    # othwise replace with link to parent
    if { [empty_string_p $r_table_name] } {
	set r_table_name "&nbsp;"
    } else {
	set r_table_name "<a href=\"../objects/describe-table.tcl?object_name=$r_owner.$r_table_name\">[string tolower $r_table_name]</a>"
    }
    append row_html "   <td>$r_table_name</td>\n"

    # 6) delete_rule - replace with non-breaking space if null
    #    else set to lower to save space since will not be cut-and-paste
    if { [empty_string_p $delete_rule] } {
	set delete_rule "&nbsp;"
    } else {
	set delete_rule [string tolower $delete_rule]
    }
    append row_html "   <td>$delete_rule</td>\n"

    # 7 status - set to lower case since it will not be cut-and-paste
    # never null
    set status [string tolower $status]
    append row_html "   <td>$status</td>\n"

    # 8 validated - set to lower case since it will not be cut-and-paste
    # never null
    set validated [string tolower $validated]
    append row_html "   <td>$validated</td>\n"

    # 9 last_change - never null
    append row_html "   <td>$last_change</td>\n"

    # close up row
    append row_html "</tr>\n"

    # write row
    ns_write "$row_html"
}


# close up table if present, otherwise indicate that there were none
if { [string compare $at_least_one_row_already_retrieved "t"]==0 } {
    ns_write "</table><p></p>\n"
} else {
    ns_write "<p>This user has no constraints! Why?.</p>"
}


ns_write "
<hr>
<H4>More information:</h4>
<p>See Oracle documentation about view <a target=second href=\"http://oradoc.photo.net/ora81/DOC/server.815/a67790/ch2.htm#1175\">dba_constraints</a> on which this page is based.</p>
[ad_admin_footer]
"
