# A GTK 3 window with one text field, for tests/broadway.test.sh: shows it
# once <folder>/go exists, writes the text to <folder>/value.txt on every
# change and quits once <folder>/quit exists (or after 90 s).
import os
import sys

import gi
gi.require_version('Gtk', '3.0')
from gi.repository import GLib, Gtk  # noqa: E402

folder = sys.argv[1]


def changed(entry):
    with open(os.path.join(folder, 'value.txt'), 'w') as f:
        f.write(entry.get_text())


def show():
    if not os.path.exists(os.path.join(folder, 'go')):
        return True
    window = Gtk.Window()
    entry = Gtk.Entry()
    window.add(entry)
    window.set_default_size(400, 60)
    window.move(0, 0)
    entry.connect('changed', changed)
    window.show_all()
    entry.grab_focus()
    return False


def quit_when_asked():
    if os.path.exists(os.path.join(folder, 'quit')):
        Gtk.main_quit()
        return False
    return True


GLib.timeout_add(100, show)
GLib.timeout_add(100, quit_when_asked)
GLib.timeout_add(90000, Gtk.main_quit)
Gtk.main()
