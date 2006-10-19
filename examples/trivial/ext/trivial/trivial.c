#include "ruby.h"
	
void Init_trivial() {
  rb_define_class("MyClass", rb_cObject);
}