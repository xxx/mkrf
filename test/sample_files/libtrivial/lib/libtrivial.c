#include "ruby.h"
	
void Init_libtrivial() {
  rb_define_class("MyClass", rb_cObject);
}