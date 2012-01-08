#!/usr/bin/env python
import intltool

APPNAME = "PovEdit"
VERSION = "0.1"
# Shamefully stolen from midori's wscript
try:
	git = Utils.cmd_output(['git','rev-parse','--short','HEAD'],silent=True)
	if git:
		VERSION = (VERSION + '-' + git).strip()
except:
	pass


top = "."
out = "build"

def set_options(opt):
	opt.tool_options('compiler_cc')
	opt.tool_options('vala')

def configure(conf):
	conf.check_tool('compiler_cc cc vala intltool')
	conf.check_cfg(package='glib-2.0',uselib_store='GLIB',atleast_version='2.10.0',mandatory=1,args='--cflags --libs')
	conf.check_cfg(package='gtk+-3.0',uselib_store='GTK',atleast_version='3.0.0',mandatory=1,args='--cflags --libs')
	conf.check_cfg(package='gtksourceview-3.0',uselib_store='GTKSOURCEVIEW',atleast_version='3.1.0',mandatory=1,args='--cflags --libs')
	conf.check_cfg(package='gio-2.0',uselib_store='GIO',atleast_version='2.10.0',mandatory=1,args='--cflags --libs')
	conf.check_cfg(package='gee-1.0',uselib_store='GEE',atleast_version='0.5.0',mandatory=1,args='--cflags --libs')
	conf.define('PACKAGE_NAME',APPNAME)
	conf.define('APPNAME',APPNAME)
	conf.define('VERSION',VERSION)
	conf.define('GETTEXT_PACKAGE',APPNAME)
	conf.write_config_header('config.h')
	
def build(bld):
	bld.add_subdirs('povedit')
	bld.add_subdirs('po')
	bld.install_files(bld.env['PREFIX']+'/share/licenses/'+'povedit','LICENSE')
