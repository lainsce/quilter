# ![icon](data/icon.png) Quilter
## Focus on your writing.
[![Get it on AppCenter](https://appcenter.elementary.io/badge.svg)](https://appcenter.elementary.io/com.github.lainsce.quilter)

![Screenshot](data/shot.png)

## Dependencies

Please make sure you have these dependencies first before building.

```
granite
gtk+-3.0
gtksourceview-3.0
meson
```

## Building

Simply clone this repo, then:

```
$ meson build && cd build
$ mesonconf -Dprefix=/usr
$ sudo ninja install
```
