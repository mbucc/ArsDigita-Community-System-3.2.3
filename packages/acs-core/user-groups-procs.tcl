# packages/acs-core/user-groups-procs.tcl
ad_library {

    Procedures to support the grouping of users
    into arbitrary groups of arbitrary type.

    @cvs-id user-groups-procs.tcl,v 1.5.2.14 2000/08/26 19:46:56 cnk Exp

}

proc_doc ad_generate_helper_table_name {group_type} {
    Generates the helper table name from the group_type.  the name is generated by adding suffix _info to the name of the group_type
} {
    return "[string trim $group_type]_info"
}

proc_doc ad_user_group_helper_table_name {group_type} {
    Returns the name of the extended attribute (a.k.a. helper) table
    for the specified user_group_type; if there is no helper table for the
    specified user_group_type, it creates one and returns the name.
} {

    set helper_table_name [ad_generate_helper_table_name $group_type]

    #
    # Query the data dictionary to make sure that the helper table
    # actually exists.
    #
    set helper_table_exists_p [db_string user_tables_count {
	select count(*)
	from user_tables
	where table_name = upper(:helper_table_name)
    }]
    
    if { !$helper_table_exists_p } {
	
	db_dml create_new_helper_table "create table $helper_table_name (group_id integer)"

    }

    return $helper_table_name
}

proc_doc ad_user_group_authorized_admin { user_id group_id } {
    Returns 1 if the user has a role of administrator. 0 otherwise. 
} {
    set n_rows [db_string user_admin_member_of_group {
	select count(*) from user_group_map where user_id = :user_id and group_id = :group_id and lower(role) = 'administrator'
    }]

    if { $n_rows > 0 } {
	return 1
    } else {
	return 0
    }
} 

proc_doc ad_user_group_authorized_admin_or_site_admin { user_id group_id } { 
    Returns 1 if the user has a role of administrator for the
    specified group OR if the user is a site-wide administrator. 0
    otherwise.
} {
    if [ad_administrator_p $user_id] {
	return 1
    } else {
	return [ad_user_group_authorized_admin $user_id $group_id]
    }
}

proc_doc ad_user_group_member { group_id {user_id ""} } { 
    Returns 1 if user is a member of the group. 0 otherwise.
} {

    if [empty_string_p $user_id] {
	set user_id [ad_verify_and_get_user_id]
    }

    set n_rows [db_string user_member_of_group {
	select decode(count(*),0,0,1) from user_group_map where user_id = :user_id and group_id = :group_id
    }]

    if { $n_rows > 0 } {
	return 1
    } else {
	return 0
    }
} 

proc_doc ad_user_group_member_cache { group_id user_id } { 
    Wraps util_memoize around ad_user_group_member.  Gets its own db
    handle if necessary.  Returns 1 if user is a member of the group. 0
    otherwise.
} {
    return [util_memoize "ad_user_group_member $group_id $user_id" [ad_parameter CacheTimeout ug 600]]
}

proc_doc ad_administration_group_member { module {submodule ""} {user_id ""} } {
    Returns 1 if user is a member of the administration group.  0 otherwise.
} {
    set group_id [ad_administration_group_id $module $submodule]
    if {[empty_string_p $group_id]} {
	return 0
    } else {
	return [ad_user_group_member $group_id $user_id]
    }
}

ad_proc ad_administration_group_add { 
    pretty_name 
    module 
    {submodule "" } 
    {url ""} 
    {multi_role_p "f"} 
    {group_id ""} 
} {
    Creates an administration group. Returns: The group_id of the new
    group if it is created; The group_id of an old group if there was
    already a administration group for this module and submodule; 0
    otherwise. Notice that unique short_name for group is genereted from
    pretty_name

    @param pretty_name pretty name of the group
    @param module module this is created for, ie. 'classifieds'
    @param submodule submodule this is created for, ie. 'equipment', 'jobs', 'wtr'
    @param url url of the module administration page
    @param permission system which type of permission system you would like to run (basic or advanced)
    @param group_id group id of the new group. One will be generated if it is not specified
    
} {
    set extra_values [ns_set create]
    ns_set put $extra_values module $module
    ns_set put $extra_values submodule $submodule
    ns_set put $extra_values url $url
    set group_id [ad_user_group_add -multi_role_p $multi_role_p -extra_values "$extra_values" -group_id "$group_id" "administration" "$pretty_name"]

    ns_set free $extra_values

    if { $group_id == 0} {
	# see if this group is defined already
	set group_id [db_string group_id_for_module_and_submodule {
	    select group_id from administration_info where module=:module and submodule=:submodule
	} -default 0]
    }

    return $group_id
}

proc_doc ad_user_group_add { 
    {-approved_p t}
    {-existence_public_p f}
    {-multi_role_p f}
    {-new_member_policy "closed"} 
    {-extra_values ""}
    {-group_id ""}
    group_type
    group_name
} {
    Creates a new group. Returns: The groud_id of the group if created
    or it existed already (double click protection); 0 on failure.

    @param group_type: type of group

    @param group_name: pretty name

    @param approved_p (optional): is this an approved group?

    @param existence_public_p (optional): Is the existence of this group public?

    @param new_member_policy (optional): How can members join? (wait, closed, open)

    @param permission_system(optional): What type of permission system (basic, advanced)

    @param extra_values (optional): A ns_set containing 
    extra values that should be stored for this
    group.  These are items that will go in the [set group_type]_info
    tables. The keys of the ns_set contain the column names. The values
    contain the values.

    @param group_id (optional): Group_id. If this is null, one will be created

} {
    # if no group_id specified, obtain one from the sequence.
    if [empty_string_p $group_id] {
	set group_id [db_nextval user_group_sequence]
    } else {
	# see if it's already there (double-click protection)
	
	set n_rows [db_string user_group_id_exists {
	    select count(*) from user_groups where group_id = :group_id
	}]
	    
	if { $n_rows == 1 } {
	    return $group_id
	}
    }

    db_transaction {
	set short_name [db_string short_name_from_group_name {
	    select short_name_from_group_name(:group_name) from dual
	}]
	    
	set creation_user [ad_get_user_id]
	set creation_ip_address [ns_conn peeraddr]

	db_dml user_group_insert {
	    insert into user_groups
	    (group_id, group_type, group_name, short_name, approved_p, existence_public_p, new_member_policy, multi_role_p,
	    creation_user, creation_ip_address, registration_date)
	    values (:group_id, :group_type, :group_name, :short_name,
	    :approved_p, :existence_public_p, :new_member_policy, :multi_role_p,
	    :creation_user, :creation_ip_address, sysdate)
	}
		
	# insert the extra values
	if { ![empty_string_p $extra_values] } {
	    
	    set bind_vars [ns_set copy $extra_values]
	    ns_set put $bind_vars group_id $group_id
	    db_dml user_group_info_insert "
	    insert into [set group_type]_info ([join [ad_ns_set_keys $bind_vars] ","]) 
	    values ([join [ad_ns_set_keys -colon $bind_vars] ","])
	    " -bind $bind_vars
	    ns_set free $bind_vars
	}
   } on_error {
       ns_log Error "$errmsg in ad-user_groups.tcl - ad_user_group_add insertion into user groups or insertion of extra values"
       db_abort_transaction
    }

    return $group_id
}

proc_doc ad_permission_p { {module ""} {submodule ""} {action ""} {user_id ""} {group_id ""} } {
    For groups with basic administration: Returns 1 if user has a role
    of administrator or all; O otherwise. For groups with advanced
    administration: Returns 1 if user has authority for the action; 0
    otherwise.
} {

    if { ![empty_string_p $module] && ![empty_string_p $group_id] } {
	return -code error "specify either module or group_id, not both"
    }

    # If no user_id was specified, then use the ID of the logged-in
    # user.
    #
    if [empty_string_p $user_id] {
	set user_id [ad_verify_and_get_user_id]
    }

    # Identify the group. Either the group_id will be explicitly
    # specified or we derive it from the module by querying to
    # find out which group is the administration group for the
    # module. If submodule is specified in addition to module, then
    # find out which group is the administration group for the
    # submodule.
    #
    if { [empty_string_p $group_id] } {
	set group_id [ad_administration_group_id $module $submodule]

	# If we fail to find a corresponding group_id, return false.
	# This probably should raise an error but I (Michael Y) don't
	# want to risk breaking any more code right now.
	#
	if { [empty_string_p $group_id] } {
	    return 0
	}
    }

    # Next, find out if the group use basic or advanced (a.k.a.
    # multi-role) administration.
    #
    set multi_role_p [db_string multi_role_p_for_group_id {
	select multi_role_p from user_groups where group_id = :group_id
    }]

    if { $multi_role_p == "f" } {
	# If administration is basic, then return true if the user has
	# either the 'administrator' role or the 'all' role for the
	# group.
	#
	set permission_p [db_string user_admin_or_all_in_group_id {
	    select decode(count(*), 0, 0, 1) 
	    from user_group_map
	    where user_id = :user_id and group_id = :group_id and role in ('administrator', 'all')
	}]

    } else {
	# If administration is advanced, then check to see if the
	# user is an administrator; if not, make sure that action
	# was specified and then check to see if the user has a
	# role that is authorized to perform the specified action.
	#
	set permission_p [db_string user_admin_in_group_id {
	    select decode(count(*), 0, 0, 1) 
	    from user_group_map
	    where user_id = :user_id and group_id = :group_id and role = 'administrator'
	}]

	if { !$permission_p } {
	    if { [empty_string_p $action] } {
		return -code error "no action specified for group with multi-role administration (ID $group_id)"
	    }

	    set permission_p [db_string user_can_do_action_from_group_id {
		select decode(count(*), 0, 0, 1) 
		from user_group_action_role_map 
		where group_id = :group_id and action = :action 
		and role in (select role from user_group_map where group_id = :group_id and user_id = :user_id)
	    }]
	}
    }

    # If necessary, make a final check to see if the user is a
    # site-wide administrator.
    #
    if { !$permission_p } {
	set permission_p [ad_administrator_p $user_id]
    }

    return $permission_p
}

ad_proc -public ad_administration_group_id { module {submodule ""}} {
    Given the module and submodule of an administration group, returns
    the group_id.  Returns empty string if there isn't a group.
    
    @param module Which module to look up
    @param submodule An optional submodule to look up.
} {
    if ![empty_string_p $submodule] {
	set result [db_string administration_group_with_submodule {
	    select group_id 
	    from administration_info 
	    where module = :module 
	    and submodule = :submodule
	} -default ""]
    } else {
	set result [db_string administration_group_without_submodule {
	    select group_id 
	    from administration_info 
	    where module = :module
	    and submodule is null
	} -default ""]
    }
    return $result
}

proc_doc ad_administration_group_user_add { user_id role module submodule } {
    Adds a user to an administration group or updates his/her role. Returns: 1 on success; 0 on failure.
} {
    set group_id [ad_administration_group_id $module $submodule]
    if {[empty_string_p $group_id]} {
	return 0
    } else {
	return [ad_user_group_user_add $user_id $role $group_id] 
    }
}

proc_doc ad_user_group_user_add { user_id role group_id } {
    Maps the specified user to the specified group in the specified role; if the mapping already exists, does nothing.
} {
    
    set mapping_user [ad_get_user_id]
    set mapping_ip_address [ns_conn peeraddr]

    if { [catch {
	db_dml user_group_map_insert {
	    insert into user_group_map(user_id, group_id, role, mapping_user, mapping_ip_address)
	    values (:user_id, :group_id, :role, :mapping_user, :mapping_ip_address)
	} 
    } errmsg ] } {

	# if the insert failed for a reason other than the fact that the
	# mapping already exists, then raise the error
	#
	set n_rows [db_string user_group_mapping_exists {
	    select count(*) from user_group_map
	    where user_id = :user_id and group_id = :group_id and role = :role
	}]

    }

    if { [info exists n_rows] && $n_rows != 1} {
	# propagate the error 
	global errorInfo
	global errorCode
	return -code error -errorinfo $errorInfo -errorcode $errorCode $errmsg
    }
	    
    return 1
}

proc_doc ad_user_group_role_add { group_id role} {
    Inserts a role into a user group.
} {
    
    set creation_user [ad_get_user_id]
    set creation_ip_address [ns_conn peeraddr]

    db_dml user_group_role_insert {
	insert into user_group_roles (group_id, role, creation_user, creation_ip_address) 
	select :group_id, :role, :creation_user, :creation_ip_address
	from dual 
	where not exists
	(select role from user_group_roles where group_id = :group_id and role = :role)
    }
}

proc_doc ad_administration_group_role_add { module submodule role } {
    Inserts a role into an administration group.
} {
    set group_id [ad_administration_group_id $module $submodule]
    if {[empty_string_p $group_id]} {
	return 0
    } else {
	ad_user_group_role_add $group_id $role
	return 1
    }
}

proc_doc ad_user_group_action_add {group_id action} {
    Inserts a action into a user_group.
} {
    set creation_user [ad_get_user_id]
    set creation_ip_address [ns_conn peeraddr]

    db_dml user_group_action_insert {
	insert into user_group_actions (group_id, action, creation_user, creation_ip_address) 
	select :group_id, :action, :creation_user, :creation_ip_address 
	from dual
	where not exists
	(select action from user_group_actions where group_id = :group_id and action = :action)
    }
}

proc_doc ad_administration_group_action_add { module submodule action } {
    Inserts an action into an administration group.
} {
    set group_id [ad_administration_group_id $module $submodule]
    if {[empty_string_p $group_id]} {
	return 0
    } else {
	ad_user_group_action_add $group_id $action
	return 1
    }
}

proc_doc ad_user_group_action_role_map {group_id action role} {
    Maps an action to a role a user group.
} {
    set creation_user [ad_get_user_id]
    set creation_ip_address [ns_conn peeraddr]
    
    db_dml user_group_action_role_map_insert {
	insert into user_group_action_role_map (group_id, role, action, creation_user, creation_ip_address) 
	select :group_id, :role, :action, :creation_user, :creation_ip_address 
	from dual
	where not exists
	(select role from user_group_action_role_map where group_id = :group_id and role = :role and action = :action)
    }
}

proc_doc ad_administration_group_action_role_map { module submodule action role } {
    Maps an action to a role in an administration group
} {
    set group_id [ad_administration_group_id $module $submodule]
    if {[empty_string_p $group_id]} {
	return 0
    } else {
	ad_user_group_action_role_map $group_id $action $role
	return 1
    }
}

proc_doc ad_user_group_type_field_form_element { field_name column_type {default_value ""} } {
    Creates a HTML form fragment of a type appropriate for the type of
    data expected (e.g. radio buttons if the type is boolean).  The
    column_type can be any of the following: integer, number, date, text
    (up to 4000 characters), text_short (up to 200 characters), boolean,
    and special (no form element will be provided).
} {
    if { $column_type == "integer" || $column_type == "number"} {
	return "<input type=text name=\"$field_name\" value=\"[philg_quote_double_quotes $default_value]\" size=5>"
    } elseif { $column_type == "date" } {
	return [ad_dateentrywidget $field_name $default_value]
    } elseif { $column_type == "text_short" } {
	return "<input type=text name=\"$field_name\" value=\"[philg_quote_double_quotes $default_value]\" size=30 maxlength=200>"
    } elseif { $column_type == "text" } {
	return "<textarea wrap name=\"$field_name\" rows=8 cols=50>$default_value</textarea>"
    } elseif { $column_type == "special" } {
	return "Special field."
    } else {
	# it's boolean
	set to_return ""
	if { [string tolower $default_value] == "t" || [string tolower $default_value] == "y" || [string tolower $default_value] == "yes"} {
	    append to_return "<input type=radio name=\"$field_name\" value=t checked>Yes &nbsp;"
	} else {
	    append to_return "<input type=radio name=\"$field_name\" value=t>Yes &nbsp;"
	}
	if { [string tolower $default_value] == "f" || [string tolower $default_value] == "n" || [string tolower $default_value] == "no"} {
	    append to_return "<input type=radio name=\"$field_name\" value=f checked>No"
	} else {
	    append to_return "<input type=radio name=\"$field_name\" value=f>No"
	}
	return $to_return
    }
}

proc_doc ad_user_group_column_type_widget { {default ""} } {
    Returns an HTML form fragment containing all possible values of column_type
} {
    return "<select name=\"column_type\">
<option value=\"boolean\" [ec_decode $default "boolean" "selected" ""]>Boolean (Yes or No)
<option value=\"integer\" [ec_decode $default "integer" "selected" ""]>Integer (Whole Number)
<option value=\"number\" [ec_decode $default "number" "selected" ""]>Number (e.g., 8.35)
<option value=\"date\" [ec_decode $default "date" "selected" ""]>Date
<option value=\"text_short\" [ec_decode $default "text_short" "selected" ""]>Short Text (up to 200 characters)
<option value=\"text\" [ec_decode $default "text" "selected" ""]>Long Text (up to 4000 characters)
<option value=\"special\" [ec_decode $default "boolean" "special" ""]>Special (no form element will be provided)
</select> (used for user interface)
"
}

proc_doc ad_get_group_id {} {
    Returns the group_id cookie value. Returns 0 if the group_id
    cookie is missing, if the user is not logged in, or if the user is not
    a member of the group.
}  {
    # 1 verifies the user_id cookie 
    # 2 gets the group_id cookie
    # 3 verifies that the user_id is mapped to group_id 

    ns_share ad_group_map_cache

    set user_id [ad_verify_and_get_user_id]
    if { $user_id == 0 } {
	return 0
    }
    set headers [ns_conn headers]
    set cookie [ns_set get $headers Cookie]
    if { [regexp {ad_group_id=([^;]+)} $cookie {} group_id] } {
	if { [info exists ad_group_map_cache($user_id)] } {
	    # there exists a cached $user_id to $group_id mapping
	    if { [string compare $group_id $ad_group_map_cache($user_id)] == 0 } {
		return $group_id
	    } 
	}
	# we continue and hit db even if there was a cached group_id (but 
	# it didn't match) because the user might have just logged into 
	# a different group

	set group_member_p [db_string user_is_group_member {
	    select ad_group_member_p(:user_id, :group_id) from dual
	}]
	    
	if { $group_member_p == "t" } {
	    set ad_group_map_cache($user_id) $group_id
	    return $group_id
	} else {
	    # user is not in the group
	    return 0
	}
    } else {
	return 0
    }
}

proc_doc ad_get_group_info {} {
    Binds variables to user group properties. Assumes group_id is defined in the caller's environment.
}  {

    upvar group_id group_id 

    set vars_to_set [ns_set create]

    db_0or1row -set_id $vars_to_set user_group_star_from_group_id {
	select *
	from user_groups
	where group_id = :group_id
    }

    # see if there is an _info table for this user_group type
    set info_table_name [ad_user_group_helper_table_name $group_type] 

    if [db_table_exists $info_table_name] {
	db_0or1row -set_id $vars_to_set user_group_info_table_star_from_group_id {
	    select * 
	    from $info_table_name
	    where group_id = :group_id
	}
    }

    # Now, set the variables in the caller's environment
    ad_ns_set_to_tcl_vars -level 2 $vars_to_set

}

ad_proc -public ad_allow_group_type_creation_p {user_id group_type} {
    Checks to see if the specified user can create groups of the given type.
    
    @param user_id The user's id.
    @param group_type The group type's id.
    @return 1 if allowed, 0 otherwise.
} {

    # If the group is of status 'closed' then only site-wide admins can proceed.
    # If it is 'open' or 'wait' then anyone can proceed.
    
    if { [ad_administrator_p $user_id] || ([db_string ug_approve_ck {
	select approval_policy 
	from user_group_types 
	where group_type = :group_type
    }] != "closed") } {
	set approved_p 1
    } else {
	set approved_p 0
    }
    return $approved_p
}
