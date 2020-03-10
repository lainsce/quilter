icon_sizes = ['16', '24', '32', '48', '64', '128']

foreach i : icon_sizes
    install_data(
        join_paths('icons', i, meson.project_name() + '.svg'),
        install_dir: join_paths(get_option('datadir'), 'icons', 'hicolor', i + 'x' + i, 'apps')
    )
endforeach

foreach i : icon_sizes
    install_data(
        join_paths('icons', i, meson.project_name() + '.svg'),
        install_dir: join_paths(get_option('datadir'), 'icons', 'hicolor', i + 'x' + i + '@2', 'apps')
    )
endforeach

install_data(
    meson.project_name() + '.gschema.xml',
    install_dir: join_paths(get_option('datadir'), 'glib-2.0', 'schemas')
)

i18n.merge_file(
    input: meson.project_name() + '.desktop.in',
    output: meson.project_name() + '.desktop',
    po_dir: join_paths(meson.source_root(), 'po', 'extra'),
    type: 'desktop',
    install: true,
    install_dir: join_paths(get_option('datadir'), 'applications')
)

i18n.merge_file(
    input: meson.project_name() + '.appdata.xml.in',
    output: meson.project_name() + '.appdata.xml',
    po_dir: join_paths(meson.source_root(), 'po', 'extra'),
    install: true,
    install_dir: join_paths(get_option('datadir'), 'metainfo')
)

install_data(
    join_paths('schemes', 'quilter.xml'),
    install_dir: join_paths(get_option('datadir'), 'gtksourceview-3.0', 'styles')
)

install_data(
    join_paths('schemes', 'quilter-sepia.xml'),
    install_dir: join_paths(get_option('datadir'), 'gtksourceview-3.0', 'styles')
)

install_data(
    join_paths('schemes', 'quilter-dark.xml'),
    install_dir: join_paths(get_option('datadir'), 'gtksourceview-3.0', 'styles')
)

install_data(
    join_paths('font', 'QuiltMono.ttf'),
    install_dir: join_paths(get_option('datadir'), 'fonts', 'truetype', 'quilt')
)

install_data(
    join_paths('font', 'QuiltVier.ttf'),
    install_dir: join_paths(get_option('datadir'), 'fonts', 'truetype', 'quilt')
)

install_subdir(
    'plugin/highlight.js',
    install_dir: join_paths([ get_option('prefix'), get_option('datadir'), 'com.github.lainsce.quilter' ])
)

install_subdir(
    'plugin/font',
    install_dir: join_paths([ get_option('prefix'), get_option('datadir'), 'com.github.lainsce.quilter' ])
)

install_subdir(
    'plugin/katex',
    install_dir: join_paths([ get_option('prefix'), get_option('datadir'), 'com.github.lainsce.quilter' ])
)
