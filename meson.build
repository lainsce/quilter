project('io.github.lainsce.Quilter', ['vala', 'c'], version: '3.2.0')
gnome = import('gnome')
i18n = import('i18n')

add_project_arguments([
		'--target-glib=2.40',
	],
	language: 'vala',
)

if get_option('profile') == 'development'
  name_prefix = '(Development) '
  profile = 'Devel'
else
  name_prefix = ''
  profile = ''
endif

app_id = 'io.github.lainsce.Quilter@0@'.format(profile)

conf = configuration_data()
conf.set_quoted('APP_ID', app_id)
conf.set_quoted('G_LOG_DOMAIN', 'io.github.lainsce.Quilter@0@'.format(profile))
conf.set_quoted('NAME_PREFIX', name_prefix)
conf.set_quoted('PACKAGE_NAME', meson.project_name())
conf.set_quoted('PACKAGE_VERSION', meson.project_version())
conf.set_quoted('PROFILE', profile)
conf.set_quoted('VERSION', meson.project_version())
conf.set_quoted('GETTEXT_PACKAGE', meson.project_name())
conf.set_quoted('DATADIR', join_paths(get_option('prefix'), get_option('datadir')))
conf.set_quoted('GNOMELOCALEDIR', join_paths(get_option('prefix'), get_option('localedir')))
configure_file(output: 'config.h', configuration: conf)
config_h_dir = include_directories('.')


add_project_arguments(
    '-include', 'config.h',
    '-DGETTEXT_PACKAGE="@0@"'.format(meson.project_name()),
    language: 'c'
)

asresources = gnome.compile_resources(
    'as-resources', 'data/app.gresource.xml',
    source_dir: 'data',
    c_name: 'as'
)

sources = files(
    'src/Application.vala',
    'src/MainWindow.vala',
    'src/Widgets/HeaderBar.vala',
    'src/Widgets/HeaderBarButton.vala',
    'src/Widgets/SourceView.vala',
    'src/Widgets/WebView.vala',
    'src/Widgets/StatusBar.vala',
    'src/Widgets/SearchBar.vala',
    'src/Widgets/SideBar.vala',
    'src/Widgets/SideBarBox.vala',
    'src/Widgets/Preferences.vala',
    'src/Plugins/PluginManager.vala',
    'src/Plugins/Plugin.vala',
    'src/Plugins/Image.vala',
    'src/Plugins/Filep.vala',
    'src/Plugins/Checkbox.vala',
    'src/Plugins/CheckboxChecked.vala',
    'src/Plugins/Highlighter.vala',
    'src/Plugins/Superscript.vala',
    'src/Plugins/Subscript.vala',
    'src/Styles/quilter.vala',
    'src/Styles/quilterdark.vala',
    'src/Styles/quiltersepia.vala',
    'src/Constants/AppSettings.vala',
    'src/Services/FileManager.vala',
    'src/Services/ExportUtils.vala',
    'src/Services/DialogUtils.vala',
)

cc = meson.get_compiler('c')
libmarkdown = cc.find_library('markdown', required: true)
dependencies = [
    dependency('gio-2.0'),
    dependency('gtk+-3.0'),
    dependency('glib-2.0'),
    dependency('gobject-2.0'),
    dependency('gee-0.8'),
    dependency('libhandy-1'),
    dependency('gtksourceview-4'),
    dependency('webkit2gtk-4.0'),
    dependency('gtkspell3-3.0'),
    dependency('libhandy-1'),
    libmarkdown,
    cc.find_library('m', required: true)
]

executable(
    meson.project_name(),
    sources,
    asresources,
    dependencies: dependencies,
    vala_args: [meson.source_root() + '/vapi/libmarkdown.vapi', meson.source_root() + '/src/Config.vapi'],
    install : true
)

subdir('data')
subdir('po')

meson.add_install_script('build-aux/post_install.py', join_paths(get_option('prefix'), get_option('datadir')))
