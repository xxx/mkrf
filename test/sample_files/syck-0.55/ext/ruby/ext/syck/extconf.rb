require "../../../../../../../lib/mkrf"

[ 'emitter.c', 'gram.c', 'gram.h', 'handler.c', 'node.c', 'syck.c', 'syck.h', 'token.c', 'bytecode.c', 'implicit.c', 'yaml2byte.c', 'yamlbyte.h' ].each do |codefile|
    `cp #{File::dirname $0}/../../../../lib/#{codefile} #{codefile}`
end

Mkrf::Generator.new('syck') do |g|
  g.include_header("st.h")
  g.add_source('*.c')         # We can actually do this in the contructor, but this tests add_source
end
