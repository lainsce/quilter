#!/usr/bin/env python3

import os
import subprocess

schemadir = os.path.join(os.environ['MESON_INSTALL_PREFIX'], 'share', 'glib-2.0', 'schemas')

if not os.environ.get('DESTDIR'):
    print('Compiling gsettings schemas...')
    subprocess.call(['glib-compile-schemas', schemadir], shell=False)

    print('Recaching mimetype handlers...')
    subprocess.call(['update-desktop-database'], shell=False)

    print('Rebuilding desktop icons cache...')
    subprocess.call(['gtk-update-icon-cache', '/usr/share/icons/hicolor/'], shell=False)

    print('Rebuilding font cache...')
    subprocess.call(['fc-cache -f /usr/share/fonts/truetype/quilt/'], shell=True)
