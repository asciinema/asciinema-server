#!/usr/bin/env python

import sys
import os
import pty
import signal
import tty
import array
import termios
import fcntl
import select
import time

class TimedFile(object):
    '''File wrapper that records write times in separate file.'''

    def __init__(self, filename):
        mode = 'wb'
        self.data_file = open(filename, mode)
        self.time_file = open(filename + '.time', mode)
        self.old_time = time.time()

    def close(self):
        self.data_file.close()
        self.time_file.close()

    def write(self, data):
        self.data_file.write(data)
        now = time.time()
        delta = now - self.old_time
        self.time_file.write("%f %d\n" % (delta, len(data)))
        self.old_time = now


class Recorder(object):
    '''Pseudo-terminal recorder.

    Creates new pseudo-terminal for spawned process
    and saves stdin/stderr (and timing) to files.
    '''

    def __init__(self, filename, command):
        self.master_fd = None
        self.filename = filename
        self.command = command

    def run(self):
        self.open_files()
        self.write_stdout('\n~ Asciicast recording started.\n')
        success = self.spawn()
        self.write_stdout('\n~ Asciicast recording finished.\n')
        self.close_files()
        return success

    def open_files(self):
        self.stdin_file = TimedFile(self.filename + '.stdin')
        self.stdout_file = TimedFile(self.filename + '.stdout')

    def close_files(self):
        self.stdin_file.close()
        self.stdout_file.close()

    def spawn(self):
        '''Create a spawned process.

        Based on pty.spawn() from standard library.
        '''

        assert self.master_fd is None

        pid, master_fd = pty.fork()
        self.master_fd = master_fd

        if pid == pty.CHILD:
            os.execlp(self.command[0], *self.command)

        old_handler = signal.signal(signal.SIGWINCH, self._signal_winch)

        try:
            mode = tty.tcgetattr(pty.STDIN_FILENO)
            tty.setraw(pty.STDIN_FILENO)
            restore = 1
        except tty.error: # This is the same as termios.error
            restore = 0

        self._set_pty_size()

        try:
            self._copy()
        except (IOError, OSError):
            if restore:
                tty.tcsetattr(pty.STDIN_FILENO, tty.TCSAFLUSH, mode)

        os.close(master_fd)
        self.master_fd = None
        signal.signal(signal.SIGWINCH, old_handler)

        return True

    def _signal_winch(self, signal, frame):
        '''Signal handler for SIGWINCH - window size has changed.'''

        self._set_pty_size()

    def _set_pty_size(self):
        '''
        Sets the window size of the child pty based on the window size
        of our own controlling terminal.
        '''

        assert self.master_fd is not None

        # Get the terminal size of the real terminal, set it on the pseudoterminal.
        buf = array.array('h', [0, 0, 0, 0])
        fcntl.ioctl(pty.STDOUT_FILENO, termios.TIOCGWINSZ, buf, True)
        fcntl.ioctl(self.master_fd, termios.TIOCSWINSZ, buf)

    def _copy(self):
        '''Main select loop.

        Passes control to self.master_read() or self.stdin_read()
        when new data arrives.
        '''

        assert self.master_fd is not None
        master_fd = self.master_fd

        while 1:
            try:
                rfds, wfds, xfds = select.select([master_fd, pty.STDIN_FILENO], [], [])
            except select.error, e:
                if e[0] == 4:   # Interrupted system call.
                    continue

            if master_fd in rfds:
                data = os.read(self.master_fd, 1024)
                self.handle_master_read(data)

            if pty.STDIN_FILENO in rfds:
                data = os.read(pty.STDIN_FILENO, 1024)
                self.handle_stdin_read(data)

    def handle_master_read(self, data):
        '''Handles new data on child process stdout.'''

        self.write_stdout(data)
        self.stdout_file.write(data)

    def handle_stdin_read(self, data):
        '''Handles new data on child process stdin.'''

        self.write_master(data)
        self.stdin_file.write(data)

    def write_stdout(self, data):
        '''Writes to stdout as if the child process had written the data.'''

        os.write(pty.STDOUT_FILENO, data)

    def write_master(self, data):
        '''Writes to the child process from its controlling terminal.'''

        master_fd = self.master_fd
        assert master_fd is not None
        while data != '':
            n = os.write(master_fd, data)
            data = data[n:]


def main():
    filename = 'typescript'

    if len(sys.argv) > 1:
        command = sys.argv[1:]
    else:
        command = os.environ['SHELL'].split()

    rec = Recorder(filename, command)
    rec.run()

if __name__ == '__main__':
    main()
