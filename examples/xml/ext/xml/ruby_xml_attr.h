/* $Id: ruby_xml_attr.h,v 1.1 2006/02/21 20:40:16 roscopeco Exp $ */

/* Please see the LICENSE file for copyright and distribution information */

#ifndef __RUBY_XML_ATTR__
#define __RUBY_XML_ATTR__

extern VALUE cXMLAttr;

typedef struct ruby_xml_attr {
  xmlAttrPtr attr;
  VALUE xd;
  int is_ptr;
} ruby_xml_attr;

void ruby_xml_attr_free(ruby_xml_attr *rxn);
void ruby_init_xml_attr(void);
VALUE ruby_xml_attr_new(VALUE class, VALUE xd, xmlAttrPtr attr);
VALUE ruby_xml_attr_new2(VALUE class, VALUE xd, xmlAttrPtr attr);
VALUE ruby_xml_attr_name_get(VALUE self);
#endif
