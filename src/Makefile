all: ../bin/terminal

../bin/terminal: terminal
	cp terminal ../bin/terminal

terminal: terminal.c
	gcc -O3 -o terminal terminal.c -ltsm
