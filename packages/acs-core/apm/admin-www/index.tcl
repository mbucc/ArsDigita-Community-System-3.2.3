ad_page_contract {
    Index page for the package manager.

    @param orderyby The parameter to order everything in the page by.
    @param owned_by Display packages owned by whom.
    @author Jon Salz [jsalz@arsdigita.com]
    @cvs-id index.tcl,v 1.5.2.5 2000/07/22 08:37:27 ron Exp
} {
    { orderby "package_key" }
    { owned_by "me" }
}

doc_body_append [apm_header]
set user_id [ad_get_user_id]
db_1row email_by_user_id {
    select email my_email from users where user_id = :user_id
}

set dimensional_list {
    {
	owned_by "Owned by:" everyone {
	    { me "Me" {where "exists (select 1 from apm_package_owners o where o.version_id = v.version_id and owner_url='mailto:$my_email')"} }
	    { everyone "Everyone" {where "1 = 1"} }
	}
    }
    {
	status "Status:" all {
	    {
		latest "Latest" {where "
                    (installed_p = 't' or enabled_p = 't' or not exists (
                        select 1 from apm_package_versions v2
                        where v2.package_id = v.package_id
                        and (v2.installed_p = 't' or v2.enabled_p = 't')
		and apm_version_order(v2.version_name) > apm_version_order(v.version_name)))"}
	    }
	    { all "All" {where "1 = 1"} }
	}
    }
}
# "latest" means that a version is installed or enabled, or there is no more latest version
# which is installed or enabled. Basically, any relevant package on the system.

switch $owned_by {
    me {
	set missing_text "<i>There are no packages belonging to you. Try <a href=\"index?[export_ns_set_vars "url" enabled]&enabled=all\">viewing all packages on the system</a> or
<a href=\"package-add\">adding your own package</a>.</i>"
    }
    everyone {
	set missing_text "<i>There are no packages on the system.</i>"
    }
}

doc_body_append "<center><table><tr><td>[ad_dimensional $dimensional_list]</td></tr></table></center>"

set table_def {
    { package_key "Key" "" "<td><a href=\"version-view?version_id=$version_id\">$package_key</a></td>" }
    { package_name "Name" "" "<td><a href=\"version-view?version_id=$version_id\">$package_name</a></td>" }
    { version_name "Ver." "" "" }
    { n_files "Files" "" {<td align=right>&nbsp;&nbsp;<a href=\"version-files?version_id=$version_id\">$n_files</a>&nbsp;</td>} }
    {
	status "Status" "" {<td align=center>&nbsp;&nbsp;[eval {
	    if { $installed_p == "t" } {
		if { $enabled_p == "t" } {
		    set status "Enabled"
		} else {
		    set status "Disabled"
		}
	    } elseif { $superseded_p } {
		set status "Superseded"
	    } else {
		set status "Uninstalled"
	    }
	    format $status
	}]&nbsp;&nbsp;</td>}
    }
    { maintained "Maintained" "" {<td align=center>[ad_decode $distribution_url "" "Locally" "Externally"]</td>} }
    {
	action "" "" {<td bgcolor=white>&nbsp;&nbsp;[eval {
	    if { $installed_p == "t" && $enabled_p == "t" && \
		    [string equal [apm_version_load_status $version_id] "needs_reload"] } {
		format "<a href=\"version-reload?version_id=$version_id\">reload</a>"
	    } elseif { $installed_p == "f" && !$superseded_p && $tarball_p } {
		format "<a href=\"version-install?version_id=$version_id\">install</a>"
	    } else {
		format ""
	    }
	}]&nbsp;&nbsp;</td>}
    }
}

doc_body_flush

set sql_qry "
        select   v.version_id, p.package_key, v.package_name, v.version_name, v.enabled_p,
                 v.installed_p, v.distribution_url,
            (select count(*) from apm_package_files f where f.version_id = v.version_id) n_files,
            (select count(*) from apm_package_versions v2
             where v2.package_id = v.package_id
             and   v2.installed_p = 't'
             and   apm_version_order(v2.version_name) > apm_version_order(v.version_name)) superseded_p,
            (select count(*) from dual where distribution_tarball is not null) tarball_p
        from     apm_packages p, apm_package_versions v
        where    v.package_id = p.package_id
        [ad_dimensional_sql $dimensional_list where and]
        [ad_order_by_from_sort_spec $orderby $table_def]
    "

set table [ad_table -Torderby $orderby -Tmissing_text $missing_text "apm_table" $sql_qry $table_def]

db_release_unused_handles

doc_body_append "<h3>Packages</h3><blockquote>$table</blockquote>
<ul>
<li><a href=\"package-add\">Create a new package</a>
<li><a href=\"package-load\">Load a new package from a URL</a>
<li><a href=\"package-scan\">Scan for new or modified packages</a>
<li><a href=\"write-all-specs\">Write new specification files for all installed, locally generated packages</a>
</ul>

"

# Build the list of files we're watching.
set watch_files [nsv_array names apm_reload_watch]
if { [llength $watch_files] > 0 } {
    doc_body_append "<h3>Watches</h3><ul>\n"
    foreach file [lsort $watch_files] {
	if { [string compare $file "."] } {
	    doc_body_append "<li>$file (<a href=\"file-watch-cancel?watch_file=[ns_urlencode $file]\">stop watching this file</a>)\n"
	}
    }
    doc_body_append "</ul>\n"
}

doc_body_append "
<h3>Other Features</h3>

<ul>
<li><a href=\"cvs-status\">Show the CVS status of non-up-to-date files in packages you own</a>
</ul>

<h3>Help</h3>

<blockquote>
A particular version of a package is <b>installed</b> if the files necessary to run it
are present in the filesystem.
It is <b>enabled</b> if it is scheduled to run at server startup
and deliverable by the request processor.

<p>If a Tcl library file (<tt>*-procs.tcl</tt>) is being <b>watched</b>,
the request processor monitors it, reloading it into running interpreters
whenever it is changed. This is useful while developing library code
(so you don't have to restart the server for your changes to take
effect). To watch a file, click its package key above, click <i>Manage file
information</i> on the next screen, and click <i>watch</i> next to
the file's name on the following screen.
</blockquote>

[ad_footer]
"

