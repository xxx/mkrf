#include "ruby.h"
	
void Init_trivial() {
  rb_define_class("Trivial", rb_cObject);
}