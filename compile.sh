#!/bin/bash

# Ensure compilers and libraries are installed
command -v g++ >/dev/null 2>&1 || { echo "G++ required"; exit 1; }
command -v rustc >/dev/null 2>&1 || { echo "Rustc required"; exit 1; }
command -v pkg >/dev/null 2>&1 || { echo "pkg required"; exit 1; }
command -v python3 >/dev/null 2>&1 || { echo "Python3 required"; exit 1; }

# Compile based on main language (C++) and additional languages
MAIN_LANG=$1
FILES=("${@:2}")
ADDITIONAL_LANGS=($(<additional_langs.txt)) # Assume additional languages are passed via a file

CPP_FILES=()
OTHER_FILES=()
SDL_FLAGS=""
PYBIND_FLAGS=""

# Categorize files
for file in "${FILES[@]}"; do
    if [[ $file == *.cpp || $file == *.c ]]; then
        CPP_FILES+=("$file")
        if grep -q "SDL_" "$file"; then
            SDL_FLAGS="-lSDL2"
        fi
        if grep -q "pybind11" "$file"; then
            PYBIND_FLAGS="-I/usr/include/python3.10 -lpython3.10"
        fi
    else
        OTHER_FILES+=("$file")
    fi
done

# Handle additional languages
for lang in "${ADDITIONAL_LANGS[@]}"; do
    case $lang in
        python)
            for file in "${OTHER_FILES[@]}"; do
                if [[ $file == *.py ]]; then
                    echo "#include <pybind11/embed.h>" > py_wrapper.cpp
                    echo "namespace py = pybind11;" >> py_wrapper.cpp
                    echo "int main() {" >> py_wrapper.cpp
                    echo "    py::scoped_interpreter guard{};" >> py_wrapper.cpp
                    echo "    py::exec(R\"($(cat $file))\"));" >> py_wrapper.cpp
                    echo "    return 0;" >> py_wrapper.cpp
                    echo "}" >> py_wrapper.cpp
                    CPP_FILES+=("py_wrapper.cpp")
                    PYBIND_FLAGS="-I/usr/include/python3.10 -lpython3.10"
                fi
            done
            ;;
        rust)
            for file in "${OTHER_FILES[@]}"; do
                if [[ $file == *.rs ]]; then
                    rustc --crate-type=staticlib -o libtemp.a "$file"
                    CPP_FILES+=("libtemp.a")
                fi
            done
            ;;
        javascript)
            for file in "${OTHER_FILES[@]}"; do
                if [[ $file == *.js ]]; then
                    pkg "$file" -o temp_js
                    CPP_FILES+=("temp_js.o")
                fi
            done
            ;;
        c)
            # C files are already included in CPP_FILES
            ;;
        *)
            echo "Unsupported additional language: $lang"
            exit 1
            ;;
    esac
done

# Compile all files
g++ -o compiled.exe "${CPP_FILES[@]}" $SDL_FLAGS $PYBIND_FLAGS

if [ $? -eq 0 ] && [ -f compiled.exe ]; then
    echo "{\"message\": \"Compilation successful\", \"exeUrl\": \"/downloads/compiled.exe\"}"
else
    echo "{\"message\": \"Compilation failed\"}"
fi
