require '../../../../../lib/mkrf'

def crash(str)
  printf(" extconf failure: %s\n", str)
  exit 1
end

Mkrf::Generator.new('libxml_so.bundle', '*.c') do |g|

  g.include_library('socket','socket')
  g.include_library('nsl','gethostbyname')

  unless g.include_library('z', 'inflate')
    crash('need zlib')
  else
    g.add_define('HAVE_ZLIB_H')
  end

  unless g.include_library('iconv','iconv_open') or 
         g.include_library('c','iconv_open') or
         g.include_library('recode','iconv_open') or
         g.include_library('iconv')
    crash(<<-EOL)
  need libiconv.

  	Install the libiconv or try passing one of the following options
  	to extconf.rb:

  	--with-iconv-dir=/path/to/iconv
  	--with-iconv-lib=/path/to/iconv/lib
  	--with-iconv-include=/path/to/iconv/include
  EOL
  end

  g.include_library('xml2', 'xmlParseDoc')
  has_header = g.include_header('libxml/xmlversion.h', 
                   '/opt/include/libxml2', 
                   '/usr/local/include/libxml2', 
                   '/usr/include/libxml2')

  unless g.include_library('xml2', 'xmlDocFormatDump')
    crash('Your version of libxml2 is too old.  Please upgrade.')
  end

  unless g.has_function? 'docbCreateFileParserCtxt'
    crash('Need docbCreateFileParserCtxt')
  end

end