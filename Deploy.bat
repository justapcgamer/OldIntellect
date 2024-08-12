@echo off
echo Compiling, this might take a while (up to 15 minutes). This window will close when done.
nuitka Executor.py --standalone --deployment --enable-plugin=pyqt5