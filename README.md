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

Install the Ergo compiler and Cogito library from https://github.com/lainsce/ergo following its README instructions.

## Run

```sh
./build.sh run
```

Or directly:

```sh
ergo run main.ergo
```

## Project Structure

```
main.ergo       Quilter application source (Ergo)
quilter.sum     SUM theme (styling)
build.sh        Build helper script
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
