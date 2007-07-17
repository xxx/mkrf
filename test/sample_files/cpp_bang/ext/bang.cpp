#include <iostream>
#include <ruby.h>

VALUE rk_mBang;

static VALUE t_bang(VALUE self) {
  return rb_str_new2("Bang !");
}

extern "C" void Init_bang() {
  // define the class 'Hello'
  rk_mBang = rb_define_module("Bang");
  rb_define_singleton_method(rk_mBang, "bang", (VALUE(*)(...))t_bang, 0);
}

