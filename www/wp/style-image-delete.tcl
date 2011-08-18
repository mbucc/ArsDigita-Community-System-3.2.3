# $Id: style-image-delete.tcl,v 3.0.4.1 2000/04/28 15:11:42 carsten Exp $
# File:        style-image-delete.tcl
# Date:        28 Nov 1999
# Author:      Jon Salz <jsalz@mit.edu>
# Description: Add an image.
# Inputs:      style_id, file_name

set user_id [ad_maybe_redirect_for_registration]

set_the_usual_form_variables

set db [ns_db gethandle]

wp_check_style_authorization $db $style_id $user_id

ns_db dml $db "delete from wp_style_images where style_id = $style_id and file_name = '$QQfile_name'"

ad_returnredirect "style-view.tcl?style_id=$style_id"
