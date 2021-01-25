#!/usr/bin/env python3

import os
import subprocess
import sys

if not os.environ.get('DESTDIR'):
    print('Compiling gsettings schemas...')
    subprocess.call(['glib-compile-schemas', os.path.join(sys.argv[1], 'glib-2.0', 'schemas')], shell=False)

    print('Recaching mimetype handlers...')
    subprocess.call(['update-desktop-database'], shell=False)

    print('Rebuilding desktop icons cache...')
    subprocess.call(['gtk-update-icon-cache', os.path.join(sys.argv[1], 'icons', 'hicolor')], shell=False)

    print('Rebuilding font cache...')
    subprocess.call(['fc-cache', '-f', os.path.join(sys.argv[1], 'fonts', 'truetype', 'quilt')], shell=True)
