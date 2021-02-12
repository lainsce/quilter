install_data(
    join_paths('icons', '128', meson.project_name() + '.svg'),
    install_dir: join_paths(get_option('datadir'), 'icons', 'hicolor', 'scalable', 'apps')
)

install_data(
    join_paths('icons', '128', meson.project_name() + 'Devel.svg'),
    install_dir: join_paths(get_option('datadir'), 'icons', 'hicolor', 'scalable', 'apps')
)

install_data(
    join_paths('icons', '16', meson.project_name() + '-symbolic.svg'),
    install_dir: join_paths(get_option('datadir'), 'icons', 'hicolor', 'symbolic', 'apps')
)

install_data(
    meson.project_name() + '.gschema.xml',
    install_dir: join_paths(get_option('datadir'), 'glib-2.0', 'schemas')
)

msgfmt = find_program('msgfmt')
podir = join_paths(meson.source_root(), 'po')
desktop_conf = configuration_data()
desktop_conf.set('icon', app_id)
desktop_file = custom_target('desktop-file',
  input: configure_file(
    input: meson.project_name() + '.desktop.in',
    output: '@BASENAME@' + '.desktop.in',
    configuration: desktop_conf
  ),
  output: '@0@.desktop'.format(app_id),
  install: true,
  install_dir: join_paths(get_option('datadir'), 'applications'),
  command: [msgfmt, '--desktop',
    '--template', '@INPUT@', '-d', podir, '-o', '@OUTPUT@',
    '--keyword=X-GNOME-FullName', '--keyword=X-Geoclue-Reason',
    '--keyword=Name', '--keyword=GenericName', '--keyword=Comment', '--keyword=Keywords'
  ]
)
# Validate Desktop file
desktop_file_validate = find_program('desktop-file-validate', required: false)
if desktop_file_validate.found()
  test(
    'validate-desktop',
    desktop_file_validate,
    args: [
      desktop_file.full_path()
    ]
  )
endif

i18n.merge_file(
    input: meson.project_name() + '.appdata.xml.in',
    output: meson.project_name() + '.appdata.xml',
    po_dir: join_paths(meson.source_root(), 'po', 'extra'),
    install: true,
    install_dir: join_paths(get_option('datadir'), 'metainfo')
)

install_data(
    join_paths('schemes', meson.project_name() + '.xml'),
    install_dir: join_paths(get_option('datadir'), 'gtksourceview-4', 'styles')
)

install_data(
    join_paths('schemes', meson.project_name() + '-sepia.xml'),
    install_dir: join_paths(get_option('datadir'), 'gtksourceview-4', 'styles')
)

install_data(
    join_paths('schemes', meson.project_name() + '-dark.xml'),
    install_dir: join_paths(get_option('datadir'), 'gtksourceview-4', 'styles')
)

install_data(
    join_paths('font', 'QuiltMono.ttf'),
    install_dir: join_paths(get_option('datadir'), 'fonts', 'truetype', 'quilt')
)

install_data(
    join_paths('font', 'QuiltZwei.ttf'),
    install_dir: join_paths(get_option('datadir'), 'fonts', 'truetype', 'quilt')
)

install_data(
    join_paths('font', 'QuiltVier.ttf'),
    install_dir: join_paths(get_option('datadir'), 'fonts', 'truetype', 'quilt')
)

install_subdir(
    'plugin/highlight.js',
    install_dir: join_paths(get_option('datadir'), meson.project_name())
)

install_subdir(
    'plugin/katex',
    install_dir: join_paths(get_option('datadir'), meson.project_name())
)

install_subdir(
    'plugin/font',
    install_dir: join_paths(get_option('datadir'), meson.project_name())
)


install_subdir(
    'plugin/center_headers',
    install_dir: join_paths(get_option('datadir'), meson.project_name())
)


install_subdir(
    'plugin/mermaid',
    install_dir: join_paths(get_option('datadir'), meson.project_name())
)

install_subdir(
    'wordlist',
    install_dir: join_paths(get_option('datadir'), meson.project_name())
)

# Resources
resources = gnome.compile_resources(
  'resources',
  'app.gresource.xml',
  gresource_bundle: true,
  source_dir: meson.current_build_dir()
)
