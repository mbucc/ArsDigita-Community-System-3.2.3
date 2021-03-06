# /packages/acs-core/apm/admin-www/version-reload.tcl

ad_page_contract { 
    Marks all changed -procs.tcl files in a version for reloading.

    @param version_id The package to be processed.
    @author Jon Salz [jsalz@arsdigita.com]
    @date 9 May 2000
    @cvs-id version-reload.tcl,v 1.2.2.5 2000/07/22 08:42:53 ron Exp
} {
    {version_id:integer}
}

doc_body_append "[apm_header "Reload a Package"]
"

# files in $files.
apm_mark_version_for_reload $version_id files

if { [llength $files] == 0 } {
    doc_body_append "There are no changed files to reload in this package.<p>"
} else {
    doc_body_append "Marked the following file[ad_decode [llength $files] 1 "" "s"] for reloading:<ul>\n"
    foreach info $files {
	set file_id [lindex $info 0]
	set file [lindex $info 1]
	doc_body_append "<li>$file"
	if { [nsv_exists apm_reload_watch $file] } {
	    doc_body_append " (currently being watched)"
	} else {
	    # This file isn't being watched right now - provide a link setting a watch on it.
	    set files_to_watch_p 1
	    doc_body_append " (<a href=\"file-watch.tcl?file_id=$file_id\">watch this file</a>)"
	}
	doc_body_append "\n"
    }
    doc_body_append "</ul>\n"
}

if { [info exists files_to_watch_p] } {
    doc_body_append "If you know you're going to be modifying one of the above files frequently,
    select the \"watch this file\" link next to a filename to cause the interpreters to
    reload the file immediately whenever it is changed.<p>
"
}

doc_body_append "
<a href=\"/admin/apm/\">Return to the Package Manager</a>
[ad_footer]
"

