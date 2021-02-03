install_data(
    join_paths('icons', '128', 'io.github.lainsce.Quilter.svg'),
    install_dir: join_paths(get_option('datadir'), 'icons', 'hicolor', 'scalable', 'apps')
)

install_data(
    join_paths('icons', '128', 'io.github.lainsce.QuilterDevel.svg'),
    install_dir: join_paths(get_option('datadir'), 'icons', 'hicolor', 'scalable', 'apps')
)

install_data(
    join_paths('icons', '16', 'io.github.lainsce.Quilter-symbolic.svg'),
    install_dir: join_paths(get_option('datadir'), 'icons', 'hicolor', 'symbolic', 'apps')
)

install_data(
    'io.github.lainsce.Quilter.gschema.xml',
    install_dir: join_paths(get_option('datadir'), 'glib-2.0', 'schemas')
)

i18n.merge_file(
    input: 'io.github.lainsce.Quilter.desktop.in',
    output: 'io.github.lainsce.Quilter.desktop',
    po_dir: join_paths(meson.source_root(), 'po', 'extra'),
    type: 'desktop',
    install: true,
    install_dir: join_paths(get_option('datadir'), 'applications')
)

i18n.merge_file(
    input: 'io.github.lainsce.Quilter.appdata.xml.in',
    output: 'io.github.lainsce.Quilter.appdata.xml',
    po_dir: join_paths(meson.source_root(), 'po', 'extra'),
    install: true,
    install_dir: join_paths(get_option('datadir'), 'metainfo')
)

install_data(
    join_paths('schemes', 'io.github.lainsce.Quilter.xml'),
    install_dir: join_paths(get_option('datadir'), 'gtksourceview-4', 'styles')
)

install_data(
    join_paths('schemes', 'io.github.lainsce.Quilter-sepia.xml'),
    install_dir: join_paths(get_option('datadir'), 'gtksourceview-4', 'styles')
)

install_data(
    join_paths('schemes', 'io.github.lainsce.Quilter-dark.xml'),
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

