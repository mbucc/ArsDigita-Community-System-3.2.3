# File:        index.tcl
# Package:     developer-support
# Author:      jsalz@mit.edu
# Date:        22 June 2000
# Description: Index page for developer support.
#
# index.tcl,v 1.1.4.1 2000/07/14 04:51:42 jsalz Exp

ad_page_variables {
    { request_limit 25 }
}

set enabled_p [nsv_get ds_properties enabled_p]

doc_body_append "[ad_header "Developer Support"]

<h3>Developer Support</h3>
[ad_admin_context_bar "Developer Support"]
<hr>

<ul>
<li>Collection of developer support information is currently
[ad_decode $enabled_p 1 \
    "on (<a href=\"set-enabled?enabled_p=0\">turn it off</a>)" \
    "off (<a href=\"set-enabled?enabled_p=1\">turn it on</a>)"]
<li>Collection of developer support information is currently
restricted to the following IP addresses:
<ul type=disc>
"

set enabled_ips [nsv_get ds_properties enabled_ips]
set includes_this_ip_p 0
if { [llength $enabled_ips] == 0 } {
    doc_body_append "<li><i>(none)</i>\n"
} else {
    foreach ip $enabled_ips {
	if { [string match $ip [ns_conn peeraddr]] } {
	    set includes_this_ip_p 1
	}
	if { [regexp {[\*\?\[\]]} $ip] } {
	    doc_body_append "<li>IPs matching the pattern \"<code>$ip</code>\"\n"
	} else {
	    doc_body_append "<li>$ip\n"
	}
    }
}
if { !$includes_this_ip_p } {
    doc_body_append "<li><a href=\"add-ip.tcl?ip=[ns_conn peeraddr]\">add your IP, [ns_conn peeraddr]</a>\n"
}

set requests [nsv_array names ds_request]

doc_body_append "
</ul>
<li>Information is being swept every [ad_parameter DataSweepInterval "developer-support" 900] sec
and has a lifetime of [ad_parameter DataLifetime "developer-support" 900] sec
</ul>

<h3>Available Request Information</h3>
<blockquote>
"

if { [llength $requests] == 0 } {
    doc_body_append "There is no request information available."
} else {
    doc_body_append "
<table cellspacing=0 cellpadding=0>
<tr bgcolor=#AAAAAA>
<th>Time</th>
<th>Duration</th>
<th>IP</th>
<th>Request</th>
</tr>
"

    set colors {white #EEEEEE}
    set counter 0
    set show_more 0
    foreach request [lsort -decreasing -dictionary $requests] {
	if { [regexp {^([0-9]+)\.conn$} $request "" id] } {
	    if { $request_limit > 0 && $counter > $request_limit } {
		incr show_more
		continue
	    }

	    if { [info exists conn] } {
		unset conn
	    }
	    array set conn [nsv_get ds_request $request]

	    if { [catch {
		set start [ns_fmttime [nsv_get ds_request "$id.start"] "%T"]
	    }] } {
		set start "?"
	    }

	    if { [info exists conn(startclicks)] && [info exists conn(endclicks)] } {
		set duration "[expr { ($conn(endclicks) - $conn(startclicks)) / 1000 }] ms"
	    } else {
		set duration ""
	    }

	    if { [info exists conn(peeraddr)] } {
		set peeraddr $conn(peeraddr)
	    } else {
		set peeraddr ""
	    }

	    if { [info exists conn(method)] } {
		set method $conn(method)
	    } else {
		set method "?"
	    }

	    if { [info exists conn(url)] } {
		if { [string length $conn(url)] > 50 } {
		    set url "[string range $conn(url) 0 46]..."
		} else {
		    set url $conn(url)
		}
	    } else {
		set conn(url) ""
	    }

	    if { [info exists conn(query)] && ![empty_string_p $conn(query)] } {
		if { [string length $conn(query)] > 50 } {
		    set query "?[string range $conn(query) 0 46]..."
		} else {
		    set query "?$conn(query)"
		}
	    } else {
		set query ""
	    }

	    doc_body_append "
<tr bgcolor=[lindex $colors [expr { $counter % [llength $colors] }]]>
<td align=center>&nbsp;$start&nbsp;</td>
<td align=right>&nbsp;$duration&nbsp;</td>
<td>&nbsp;$peeraddr&nbsp;</td>
<td><a href=\"request-info?request=$id\">[ns_quotehtml "$method $url$query"]</a></td>
</tr>
"
            incr counter
        }
    }
    if { $show_more > 0 } {
	doc_body_append "<tr><td colspan=4 align=right><a href=\"index?request_limit=0\"><i>show $show_more more requests</i></td></tr>\n"
    }

    doc_body_append "</table>\n"
}

doc_body_append "

</blockquote>
[ad_footer]
"

