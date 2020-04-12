project('com.github.lainsce.quilter', 'vala', 'c', version: '2.2.4')

gnome = import('gnome')
i18n = import('i18n')

add_global_arguments(
    '-DGETTEXT_PACKAGE="@0@"'.format (meson.project_name()),
    language:'c'
)

asresources = gnome.compile_resources(
    'as-resources', join_paths('data', 'app.gresource.xml'),
    source_dir: 'data',
    c_name: 'as'
)

executable(
    meson.project_name(),
    'src/Application.vala',
    'src/MainWindow.vala',
    'src/Widgets/HeaderBar.vala',
    'src/Widgets/SourceView.vala',
    'src/Widgets/WebView.vala',
    'src/Widgets/StatusBar.vala',
    'src/Widgets/SearchBar.vala',
    'src/Widgets/SideBar.vala',
    'src/Widgets/SideBarBox.vala',
    'src/Widgets/Preferences.vala',
    'src/Widgets/Cheatsheet.vala',
    'src/Plugins/PluginManager.vala',
    'src/Plugins/Plugin.vala',
    'src/Plugins/Image.vala',
    'src/Plugins/Filep.vala',
    'src/Styles/quilter.vala',
    'src/Styles/quilterdark.vala',
    'src/Styles/quiltersepia.vala',
    'src/Constants/AppSettings.vala',
    'src/Services/FileManager.vala',
    'src/Services/ExportUtils.vala',
    'src/Services/DialogUtils.vala',
    asresources,
    dependencies: [
        dependency('granite'),
        dependency('gobject-2.0'),
        dependency('gtksourceview-3.0'),
        dependency('gtk+-3.0'),
        dependency('webkit2gtk-4.0'),
        dependency('gtkspell3-3.0'),
        dependency('libmarkdown')
    ],
    vala_args: [
        '--vapidir=' + meson.source_root() + '/vapi/',
    ],
    install : true
)

# Add in a post install script
meson.add_install_script('meson/post_install.py', join_paths(get_option('prefix'), get_option('datadir')))

# Add subfolders for Meson to look
subdir('data')
subdir('po')