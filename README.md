# Quilter — Ergo/Cogito Port

A focused Markdown editor, rewritten in [Ergo](https://github.com/lainsce/ergo) with the [Cogito](https://github.com/lainsce/ergo) GUI framework.

This is a port of the original [Quilter](https://github.com/lainsce/quilter) application from Vala/GTK4 to Ergo/Cogito.

## Features

- Clean, distraction-free Markdown editing
- File sidebar for quick document switching
- Open / Save / Save As with native file dialogs
- Live word, line, and character count in the status bar
- Custom SUM theme with light and dark mode support
- Appbar with quick-access action buttons

## Requirements

### Build Ergo + Cogito

1. Clone the Ergo repository:

```sh
git clone https://github.com/lainsce/ergo.git
```

2. Install dependencies:

```sh
# Ubuntu/Debian
sudo apt install meson ninja-build libfreetype-dev \
  libwayland-dev libxkbcommon-dev libdrm-dev libegl-dev \
  libpulse-dev libxtst-dev libasound2-dev \
  libx11-dev libxext-dev libxrandr-dev libxcursor-dev \
  libxfixes-dev libxi-dev libxss-dev cmake pkg-config

# macOS (Homebrew)
brew install meson ninja sdl3 sdl3_ttf sdl3_image freetype
```

3. Build SDL3 and SDL3_ttf from source (Linux — if not packaged):

```sh
git clone --depth 1 https://github.com/libsdl-org/SDL.git /tmp/SDL3
cmake -S /tmp/SDL3 -B /tmp/SDL3/build -DCMAKE_INSTALL_PREFIX=/usr/local \
  -DCMAKE_BUILD_TYPE=Release -DSDL_SHARED=ON -DSDL_TEST=OFF -DSDL_EXAMPLES=OFF
cmake --build /tmp/SDL3/build -j$(nproc)
sudo cmake --install /tmp/SDL3/build

git clone --depth 1 https://github.com/libsdl-org/SDL_ttf.git /tmp/SDL3_ttf
cmake -S /tmp/SDL3_ttf -B /tmp/SDL3_ttf/build -DCMAKE_INSTALL_PREFIX=/usr/local \
  -DCMAKE_BUILD_TYPE=Release -DSDL3TTF_SAMPLES=OFF
cmake --build /tmp/SDL3_ttf/build -j$(nproc)
sudo cmake --install /tmp/SDL3_ttf/build
sudo ldconfig
```

4. Build Ergo and Cogito:

```sh
cd ergo
CFLAGS="-D_GNU_SOURCE" meson setup ergo/build ergo
meson compile -C ergo/build

meson setup cogito/build cogito -Dc_args="-D_GNU_SOURCE"
meson compile -C cogito/build
```

### Run Quilter

From this directory, with the Ergo repo cloned alongside:

```sh
export ERGO_REPO=../ergo   # path to the lainsce/ergo clone
./build.sh run
```

Or manually:

```sh
export ERGO_CC_FLAGS="-D_GNU_SOURCE"
export ERGO_RAYLIB_FLAGS="-lm -lpthread -ldl -lrt -lX11"
export ERGO_COGITO_CFLAGS="-I../ergo/cogito/src"
export ERGO_COGITO_FLAGS="-L../ergo/cogito/build -lcogito -Wl,-rpath,../ergo/cogito/build"
../ergo/ergo/build/ergo run main.ergo
```

## Project Structure

```
main.ergo           Quilter application source (Ergo)
quilter.sum         SUM theme (styling)
build.sh            Build helper script
ergo/               Ergo compiler runtime files
cogito/             Cogito framework bindings
```

## Architecture

The application is built using Ergo's declarative GUI model:

- **`cogito.appbar`** — Title bar with action buttons (New, Open, Save, Save As)
- **`cogito.textview`** — Main Markdown editing area
- **`cogito.list`** — Sidebar file list
- **`cogito.searchfield`** — Document search
- **`cogito.label`** — Status bar with word/line/char counts
- **SUM theming** — Custom styling with light/dark mode via `quilter.sum`

File I/O uses Ergo's standard library (`stdr.open_file_dialog`, `stdr.save_file_dialog`, `stdr.read_text_file`, `stdr.write_text_file`).

## License

GPLv3 — see [LICENSE](LICENSE).
