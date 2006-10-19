/* $Id: ruby_xml_xpointer_context.h,v 1.1 2006/02/21 20:40:16 roscopeco Exp $ */

/* Please see the LICENSE file for copyright and distribution information */

#ifndef __RUBY_XML_XPOINTER_CONTEXT__
#define __RUBY_XML_XPOINTER_CONTEXT__

extern VALUE cXMLXPointerContext;
extern VALUE eXMLXPointerContextInvalidPath;

typedef struct ruby_xml_xpointer_context {
  VALUE xd;
  xmlXPathContextPtr ctxt;
} ruby_xml_xpointer_context;

void ruby_init_xml_xpointer_context(void);

#endif
