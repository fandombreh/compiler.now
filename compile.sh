#!/bin/bash

# Ensure compilers and libraries are installed
command -v g++ >/dev/null 2>&1 || { echo "G++ required"; exit 1; }
command -v rustc >/dev/null 2>&1 || { echo "Rustc required"; exit 1; }
command -v pkg >/dev/null 2>&1 || { echo "pkg required"; exit 1; }
command -v pyinstaller >/dev/null 2>&1 || { echo "PyInstaller required"; exit 1; }

# Read languages and files
LANGS=($(<languages.txt)) # Assume languages are passed via a file
FILES=("${@:1}")

CPP_FILES=()
C_FILES=()
PY_FILES=()
RS_FILES=()
JS_FILES=()
SDL_FLAGS=""
PYBIND_FLAGS=""
USE_CPP=0

# Categorize files
for file in "${FILES[@]}"; do
    if [[ $file == *.cpp ]]; then
        CPP_FILES+=("$file")
        if grep -q "SDL_" "$file"; then
            SDL_FLAGS="-lSDL2"
        fi
        USE_CPP=1
    elif [[ $file == *.c ]]; then
        C_FILES+=("$file")
        USE_CPP=1
    elif [[ $file == *.py ]]; then
        PY_FILES+=("$file")
    elif [[ $file == *.rs ]]; then
        RS_FILES+=("$file")
    elif [[ $file == *.js ]]; then
        JS_FILES+=("$file")
    fi
done

# Determine compilation strategy
if [ $USE_CPP -eq 1 ] || [[ " ${LANGS[*]} " =~ "cpp" ]] || [[ " ${LANGS[*]} " =~ "c" ]]; then
    COMMAND="g++ -o compiled.exe $SDL_FLAGS"
    
    # Handle Python
    if [[ " ${LANGS[*]} " =~ "python" ]] && [ ${#PY_FILES[@]} -gt 0 ]; then
        echo "#include <pybind11/embed.h>" > py_wrapper.cpp
        echo "namespace py = pybind11;" >> py_wrapper.cpp
        echo "int main() {" >> py_wrapper.cpp
        echo "    py::scoped_interpreter guard{};" >> py_wrapper.cpp
        for file in "${PY_FILES[@]}"; do
            echo "    py::exec(R\"($(cat $file))\"));" >> py_wrapper.cpp
        done
        echo "    return 0;" >> py_wrapper.cpp
        echo "}" >> py_wrapper.cpp
        CPP_FILES+=("py_wrapper.cpp")
        PYBIND_FLAGS="-I/usr/include/python3.10 -lpython3.10"
    fi

    # Handle Rust
    if [[ " ${LANGS[*]} " =~ "rust" ]] && [ ${#RS_FILES[@]} -gt 0 ]; then
        for file in "${RS_FILES[@]}"; do
            rustc --crate-type=staticlib -o libtemp.a "$file"
            CPP_FILES+=("libtemp.a")
        done
    fi

    # Handle JavaScript
    if [[ " ${LANGS[*]} " =~ "javascript" ]] && [ ${#JS_FILES[@]} -gt 0 ]; then
        for file in "${JS_FILES[@]}"; do
            pkg "$file" -o temp_js
            CPP_FILES+=("temp_js.o")
        done
    fi

    # Add C and C++ files
    COMMAND="$COMMAND ${CPP_FILES[*]} ${C_FILES[*]} $PYBIND_FLAGS"
elif [[ " ${LANGS[*]} " =~ "python" ]] && [ ${#PY_FILES[@]} -gt 0 ]; then
    COMMAND="pyinstaller --onefile ${PY_FILES[0]}"
elif [[ " ${LANGS[*]} " =~ "rust" ]] && [ ${#RS_FILES[@]} -gt 0 ]; then
    COMMAND="rustc -o compiled.exe ${RS_FILES[0]}"
elif [[ " ${LANGS[*]} " =~ "javascript" ]] && [ ${#JS_FILES[@]} -gt 0 ]; then
    COMMAND="pkg ${JS_FILES[0]} -o compiled.exe"
else
    echo "{\"message\": \"No valid compilation strategy found\"}"
    exit 1
fi

$COMMAND
if [ $? -eq 0 ] && [ -f compiled.exe ]; then
    echo "{\"message\": \"Compilation successful\", \"exeUrl\": \"/downloads/compiled.exe\"}"
else
    echo "{\"message\": \"Compilation failed\"}"
fi
