drop table fm_element_validations ;
drop table fm_element_datamaps ;
drop table fm_form_element_map ;
drop table fm_element_attributes ;
drop table fm_elements cascade constraints;
drop sequence fm_elements_seq ;
drop table fm_element_options ;
drop table fm_element_option_sets ;
drop table fm_element_option_methods;
drop table fm_form_process_code ;
drop table fm_form_extensions ;
drop table fm_form_attributes ;
drop table fm_forms cascade constraints;
drop sequence fm_forms_seq ;
drop table fm_form_category_map ;
drop table fm_form_categories ;
drop sequence fm_form_categories_seq ;
drop table fm_datatypes;
drop table fm_widget_attributes ;
drop table fm_widgets ;

exec mc.delete_category('forms');