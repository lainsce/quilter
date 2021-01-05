project('quilter',
        'rust',
        version: '4.0.0',
        license: 'gpl3')

i18n = import('i18n')
gnome = import('gnome')

base_id = 'com.github.lainsce.quilter'

dependency('glib-2.0', version: '>= 2.56')
dependency('gio-2.0', version: '>= 2.56')
dependency('gdk-pixbuf-2.0')
dependency('gtk+-3.0', version: '>= 3.24.7')
dependency('libhandy-1')
glib_compile_resources = find_program('glib-compile-resources', required: true)
glib_compile_schemas = find_program('glib-compile-schemas', required: true)
desktop_file_validate = find_program('desktop-file-validate', required: false)
appstream_util = find_program('appstream-util', required: false)
cargo = find_program('cargo', required: false)
cargo_script = find_program('build-aux/cargo.sh')

version = meson.project_version()
prefix = get_option('prefix')
bindir = prefix / get_option('bindir')
localedir = prefix / get_option('localedir')

datadir = prefix / get_option('datadir')
pkgdatadir = datadir / meson.project_name()
iconsdir = datadir / 'icons'
podir = meson.source_root() / 'po'
gettext_package = meson.project_name()

if get_option('profile') == 'development'
  profile = ''
  name_suffix = ' (Devel)'
  vcs_tag = run_command('git', 'rev-parse', '--short', 'HEAD').stdout().strip()
  if vcs_tag == ''
    version_suffix = '-devel'
  else
    version_suffix = '-@0@'.format(vcs_tag)
  endif
else
  profile = ''
  name_suffix = ''
  version_suffix = ''
endif

application_id = '@0@@1@'.format(base_id, profile)

meson.add_dist_script(
  'build-aux/dist-vendor.sh',
  meson.build_root() / 'meson-dist' / meson.project_name() + '-' + version,
  meson.source_root()
)

subdir('data')
subdir('po')
subdir('src')

meson.add_install_script('build-aux/meson_post_install.py')

