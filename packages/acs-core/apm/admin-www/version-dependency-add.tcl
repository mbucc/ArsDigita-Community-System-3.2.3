ad_page_contract {
    Adds a dependency to a version of a package.
    @author Jon Salz [jsalz@arsdigita.com]
    @date 17 April 2000
    @cvs-id version-dependency-add.tcl,v 1.4.2.3 2000/07/21 03:55:45 ron Exp
} {
    {version_id:integer}
    dependency_type
}

db_1row apm_package_info_by_version_id_and_package {
    select p.package_key, p.package_url, 
    v.package_name, v.version_name
    from   apm_packages p, apm_package_versions v
    where  v.version_id = :version_id
    and    v.package_id = p.package_id
}

doc_body_append "[apm_header -form "action=version-dependency-add-2.tcl" [list "version-view.tcl?version_id=$version_id" "$package_name $version_name"] [list "version-dependencies.tcl?version_id=$version_id" "Dependencies"] "Add a Dependency"]

[export_form_vars version_id dependency_type]

<script language=javascript>
// Invoked when the user selects a service from the select list.
function selectService(which) {
    // Select the radio button next to the list of services.
    var form = document.forms\[0\];
    form.which\[0\].checked = 1;

    // Fill in the text fields according to the service selected (the URL
    // is before the semicolon; the version number is after it)
    value = which.options\[which.selectedIndex\].value;
    semi = value.indexOf(';');
    form.service_url.value = value.substring(0, semi);
    form.service_version.value = value.substring(semi + 1);
}
</script>

<blockquote>
<table cellspacing=0 cellpadding=0>
<tr><td><input type=radio name=which value=service>&nbsp;</td><td>$package_name ${dependency_type}s the following service:</td></tr>

<tr><td></td><td>
<select name=service_select size=8 onChange=\"selectService(this)\">
"

db_foreach apm_all_service_url {
    select distinct service_url, service_version
    from   apm_package_dependencies
    order by service_url, apm_version_order(service_version)
} {
    doc_body_append "<option value=\"$service_url;$service_version\">$service_url, version $service_version\n"
}


db_release_unused_handles
doc_body_append "</select>
</td></tr>

<tr><td><input type=radio name=which value=other>&nbsp;</td><td>$package_name ${dependency_type}s the following other service:</td></tr>
<tr><td></td><td><input name=service_url size=60 onFocus=\"form.which\[1\].checked = 1\">, version <input name=service_version size=10 onFocus=\"form.which\[1\].checked = 1\"></td></tr>

</table>
</blockquote>

<center>
<input type=submit value=\"Add Dependency\">
</center>

[ad_footer]
"

