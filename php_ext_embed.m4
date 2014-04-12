dnl
dnl $Id$
dnl
dnl This file contains helper autoconf functions for php_ext_embed
dnl

ext_embed_files_header=ext_embed_libs.h

AC_DEFUN([PHP_EXT_EMBED_CHECK_VALID],[
  if test "$PHP_EXT_EMBED_DIR" = ""; then
    AC_MSG_ERROR([PHP_EXT_EMBED_DIR is not set])
  fi
])


dnl
dnl PHP_EXT_EMBED_NEW_EXTENSION(extname, sources [, shared [, sapi_class [, extra-cflags [, cxx [, zend_ext]]]]])
dnl
dnl Includes an extension in the build.
dnl 
dnl It is a wrapper for PHP_NEW_EXTENSION to inculude php_ext_embed.c
dnl
dnl "extname" is the name of the ext/ subdir where the extension resides.
dnl "sources" is a list of files relative to the subdir which are used
dnl to build the extension.
dnl "shared" can be set to "shared" or "yes" to build the extension as
dnl a dynamically loadable library. Optional parameter "sapi_class" can
dnl be set to "cli" to mark extension build only with CLI or CGI sapi's.
dnl "extra-cflags" are passed to the compiler, with 
dnl @ext_srcdir@ and @ext_builddir@ being substituted.
dnl "cxx" can be used to indicate that a C++ shared module is desired.
dnl "zend_ext" indicates a zend extension.
AC_DEFUN([PHP_EXT_EMBED_NEW_EXTENSION],[
  PHP_EXT_EMBED_CHECK_VALID()

  PHP_NEW_EXTENSION($1, [$2 $PHP_EXT_EMBED_DIR/php_ext_embed.c], $3, $4, $5, $6, $7)

  case $host_alias in
    *linux*[)]
      dnl FIXME tricky way to add custom command after build for Linux
      cat >>Makefile.objects<<EOF
	objcopy $php_ext_embed_libs $phplibdir/$1.so
EOF
      ;;
  esac
])

dnl
dnl PHP_EXT_EMBED_INIT(extname)
dnl
dnl check dependencies
dnl
dnl "extname" is the name of the ext/ subdir where the extension resides.
AC_DEFUN([PHP_EXT_EMBED_INIT],[
  PHP_EXT_EMBED_CHECK_VALID()

  AC_MSG_CHECKING([whether php_ext_embed_dir is correct])
  if test -f "$PHP_EXT_EMBED_DIR/php_ext_embed.h"; then
    AC_MSG_RESULT([yes])
  else
    AC_MSG_ERROR([php_ext_embed.h is not exist])
  fi

  PHP_ADD_INCLUDE($PHP_EXT_EMBED_DIR)
 
  dnl TODO Checking libelf? and add libs
  AC_MSG_CHECKING([whether libelf is found])

  dnl TODO PHP_ADD_EXTENSION_DEP('?')
])

dnl
dnl PHP_EXT_EMBED_ADD_LIB(extname, sources)
dnl
dnl Includes php lib to extension
dnl
dnl "extname" is the name of the ext/ subdir where the extension resides.
dnl "sources" is a list of files relative to the subdir which need to be
dnl           embeded to extension
AC_DEFUN([PHP_EXT_EMBED_ADD_LIB],[
  php_ext_upper_name=translit($1,a-z-,A-Z_)
  AC_MSG_RESULT(Generate embed files header)
  echo "" > $ext_embed_files_header

  echo "/* Generated by php-ext-embed don't edit it */"	>> $ext_embed_files_header
  echo "" 												>> $ext_embed_files_header
  echo "#ifndef _PHP_EXT_EMBED_${php_ext_upper_name}_"	>> $ext_embed_files_header
  echo "#define _PHP_EXT_EMBED_${php_ext_upper_name}_"	>> $ext_embed_files_header
  echo ""											>> $ext_embed_files_header
  echo "php_ext_lib_entry ext_$1_embed_files[[]] = {"		>> $ext_embed_files_header

  php_ext_embed_libs=
  case $host_alias in
    *darwin*[)]
      MD5_CMD=md5
      ;;
	*[)]
      MD5_CMD=md5sum
      ;;
  esac

  for ac_src in $2; do
    if test -f "$ac_src"; then
	  dummy_filename="extension://$1/$ac_src"
	  dnl TODO Linux
	  section_name=ext.`echo $dummy_filename | $MD5_CMD`
	  section_name=${section_name:0:16}
      echo "	{"						>> $ext_embed_files_header
	  echo "		\"$ac_src\"",			>> $ext_embed_files_header
	  echo "		\"$dummy_filename\""	>> $ext_embed_files_header
	  echo "		\"$section_name\"",		>> $ext_embed_files_header
	  echo "	},"						>> $ext_embed_files_header
      PHP_GLOBAL_OBJS="$PHP_GLOBAL_OBJS $ac_src"
	  shared_objects_$1="$shared_objects_$1 $ac_src"

	  case $host_alias in
	  	*darwin*[)]
		  dnl Tricky way. There is no way to hook it link stage :(
		  dnl so there are warnings when compile with mac
		  LDFLAGS="$LDFLAGS -Wl,-sectcreate,__text,${section_name},${ac_src}"
	  	;;
	  	*[)]
		  php_ext_embed_libs="$php_ext_embed_libs --add-section "${section_name}=${ac_src}""
	  	;;
	  esac
	else
	  AC_MSG_WARN([lib file $ac_src not found, ignored])
	fi
  done
  echo "	{NULL, NULL, NULL}"										>> $ext_embed_files_header
  echo "};"											>> $ext_embed_files_header
  echo ""											>> $ext_embed_files_header
  echo "#endif"										>> $ext_embed_files_header
])
