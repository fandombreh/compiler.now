#include <string>
#include <vector>
#include <filesystem>
#include <fstream>
#include <cstdlib>
#include <nlohmann/json.hpp>

using json = nlohmann::json;
namespace fs = std::filesystem;

std::string compile_files(const std::vector<std::string>& file_paths, const std::vector<std::string>& languages) {
    std::string output_exe = "compiled.exe";
    std::string command;
    std::vector<std::string> cpp_files, c_files, py_files, rs_files, js_files;
    bool use_cpp = false, use_sdl = false;

    // Categorize files
    for (const auto& file : file_paths) {
        if (file.ends_with(".cpp")) {
            cpp_files.push_back(file);
            std::ifstream src(file);
            std::string content((std::istreambuf_iterator<char>(src)), std::istreambuf_iterator<char>());
            if (content.find("SDL_") != std::string::npos) use_sdl = true;
            use_cpp = true;
        } else if (file.ends_with(".c")) {
            c_files.push_back(file);
            use_cpp = true;
        } else if (file.ends_with(".py")) {
            py_files.push_back(file);
        } else if (file.ends_with(".rs")) {
            rs_files.push_back(file);
        } else if (file.ends_with(".js")) {
            js_files.push_back(file);
        }
    }

    // Determine primary compilation strategy
    if (use_cpp || std::find(languages.begin(), languages.end(), "cpp") != languages.end() || 
        std::find(languages.begin(), languages.end(), "c") != languages.end()) {
        command = "g++ -o " + output_exe + " ";
        if (use_sdl) command += "-lSDL2 ";

        // Handle Python with pybind11
        if (std::find(languages.begin(), languages.end(), "python") != languages.end() && !py_files.empty()) {
            std::ofstream wrapper("py_wrapper.cpp");
            wrapper << "#include <pybind11/embed.h>\n";
            wrapper << "namespace py = pybind11;\n";
            wrapper << "int main() {\n";
            wrapper << "    py::scoped_interpreter guard{};\n";
            for (const auto& file : py_files) {
                wrapper << "    py::exec(R\"(" << std::ifstream(file).rdbuf() << ")\"));\n";
            }
            wrapper << "    return 0;\n";
            wrapper << "}\n";
            wrapper.close();
            cpp_files.push_back("py_wrapper.cpp");
            command += "-I/usr/include/python3.10 -lpython3.10 ";
        }

        // Handle Rust
        if (std::find(languages.begin(), languages.end(), "rust") != languages.end() && !rs_files.empty()) {
            for (const auto& file : rs_files) {
                std::system(("rustc --crate-type=staticlib -o libtemp.a " + file).c_str());
                command += "libtemp.a ";
            }
        }

        // Handle JavaScript
        if (std::find(languages.begin(), languages.end(), "javascript") != languages.end() && !js_files.empty()) {
            for (const auto& file : js_files) {
                std::system(("pkg " + file + " -o temp_js").c_str());
                command += "temp_js.o ";
            }
        }

        // Add C and C++ files
        for (const auto& file : cpp_files) command += file + " ";
        for (const auto& file : c_files) command += file + " ";
    } else if (std::find(languages.begin(), languages.end(), "python") != languages.end() && !py_files.empty()) {
        command = "pyinstaller --onefile " + py_files[0];
    } else if (std::find(languages.begin(), languages.end(), "rust") != languages.end() && !rs_files.empty()) {
        command = "rustc -o " + output_exe + " " + rs_files[0];
    } else if (std::find(languages.begin(), languages.end(), "javascript") != languages.end() && !js_files.empty()) {
        command = "pkg " + js_files[0] + " -o " + output_exe;
    } else {
        json response;
        response["message"] = "No valid compilation strategy found";
        return response.dump();
    }

    int result = std::system(command.c_str());
    if (result == 0 && fs::exists(output_exe)) {
        json response;
        response["message"] = "Compilation successful";
        response["exeUrl"] = "/downloads/" + output_exe;
        return response.dump();
    } else {
        json response;
        response["message"] = "Compilation failed";
        return response.dump();
    }
}

int main() {
    // Simulated server handling (integrate with Godot or HTTP server)
    return 0;
}
