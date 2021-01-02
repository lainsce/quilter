fs = import('fs')

icon_sizes = ['16', '24', '32', '48', '64', '128']

configdir = fs.expanduser('~/.local/share/com.github.lainsce.quilter')

foreach i : icon_sizes
    install_data(
        join_paths('icons', i, 'com.github.lainsce.quilter.svg'),
        install_dir: join_paths(get_option('datadir'), 'icons', 'hicolor', i + 'x' + i, 'apps')
    )
endforeach

foreach i : icon_sizes
    install_data(
        join_paths('icons', i, 'com.github.lainsce.quilter.svg'),
        install_dir: join_paths(get_option('datadir'), 'icons', 'hicolor', i + 'x' + i + '@2', 'apps')
    )
endforeach

install_data(
    'com.github.lainsce.quilter.gschema.xml',
    install_dir: join_paths(get_option('datadir'), 'glib-2.0', 'schemas')
)

i18n.merge_file(
    input: 'com.github.lainsce.quilter.desktop.in',
    output: 'com.github.lainsce.quilter.desktop',
    po_dir: join_paths(meson.source_root(), 'po', 'extra'),
    type: 'desktop',
    install: true,
    install_dir: join_paths(get_option('datadir'), 'applications')
)

i18n.merge_file(
    input: 'com.github.lainsce.quilter.appdata.xml.in',
    output: 'com.github.lainsce.quilter.appdata.xml',
    po_dir: join_paths(meson.source_root(), 'po', 'extra'),
    install: true,
    install_dir: join_paths(get_option('datadir'), 'metainfo')
)

install_data(
    join_paths('schemes', 'com.github.lainsce.quilter.xml'),
    install_dir: join_paths(get_option('datadir'), 'gtksourceview-4', 'styles')
)

install_data(
    join_paths('schemes', 'com.github.lainsce.quilter-sepia.xml'),
    install_dir: join_paths(get_option('datadir'), 'gtksourceview-4', 'styles')
)

install_data(
    join_paths('schemes', 'com.github.lainsce.quilter-dark.xml'),
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
    install_dir: configdir
)

install_subdir(
    'plugin/font',
    install_dir: configdir
)

install_subdir(
    'plugin/center_headers',
    install_dir: configdir
)

install_subdir(
    'plugin/katex',
    install_dir: configdir
)

install_subdir(
    'plugin/mermaid',
    install_dir: configdir
)

install_subdir(
    'wordlist',
    install_dir: configdir
)

# Resources
resources = gnome.compile_resources(
  'resources',
  'com.github.lainsce.quilter.gresource.xml',
  gresource_bundle: true,
  source_dir: meson.current_build_dir()
)
