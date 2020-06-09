project('com.github.lainsce.quilter', 'vala', 'c', version: '3.0.0')

gnome = import('gnome')
i18n = import('i18n')

add_global_arguments([
        '-DGETTEXT_PACKAGE="@0@"'.format(meson.project_name()),
        '-DHANDY_USE_UNSTABLE_API'
    ],
    language:'c'
)

asresources = gnome.compile_resources(
    'as-resources', join_paths('data', 'app.gresource.xml'),
    source_dir: 'data',
    c_name: 'as'
)

cc = meson.get_compiler('c')
libmarkdown = cc.find_library('markdown', required: true)

executable(
    meson.project_name(),
    'src/Application.vala',
    'src/MainWindow.vala',
    'src/Widgets/HeaderBar.vala',
    'src/Widgets/SideHeaderBar.vala',
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
    asresources,
    dependencies: [
        dependency('gobject-2.0'),
        dependency('gtksourceview-4'),
        dependency('gtk+-3.0'),
        dependency('webkit2gtk-4.0'),
        dependency('gtkspell3-3.0'),
        dependency('granite', version: '>=5.4.0'),
        dependency('libhandy-1', version: '>=0.80.0'),
        libmarkdown,
    ],
    vala_args: [
        meson.source_root() + '/vapi/libmarkdown.vapi',
    ],
    install : true
)

meson.add_install_script('meson/post_install.py', join_paths(get_option('prefix'), get_option('datadir')))

subdir('data')
subdir('po')
