#include <string>
#include <vector>
#include <filesystem>
#include <fstream>
#include <cstdlib>
#include <nlohmann/json.hpp>

using json = nlohmann::json;
namespace fs = std::filesystem;

std::string compile_files(const std::vector<std::string>& file_paths, const std::string& main_lang, const std::vector<std::string>& additional_langs) {
    std::string output_exe = "compiled.exe";
    std::string command = "g++ -o " + output_exe + " ";
    std::vector<std::string> cpp_files;
    std::vector<std::string> other_files;

    // Categorize files
    for (const auto& file : file_paths) {
        if (file.ends_with(".cpp")) {
            cpp_files.push_back(file);
            std::ifstream src(file);
            std::string content((std::istreambuf_iterator<char>(src)), std::istreambuf_iterator<char>());
            if (content.find("SDL_") != std::string::npos) {
                command += "-lSDL2 ";
            }
            if (content.find("pybind11") != std::string::npos) {
                command += "-I/usr/include/python3.10 -lpython3.10 ";
            }
        } else if (file.ends_with(".c")) {
            cpp_files.push_back(file); // C files can be linked with C++
        } else {
            other_files.push_back(file);
        }
    }

    // Handle additional languages
    for (const auto& lang : additional_langs) {
        if (lang == "python") {
            for (const auto& file : other_files) {
                if (file.ends_with(".py")) {
                    // Embed Python using pybind11
                    std::ofstream wrapper("py_wrapper.cpp");
                    wrapper << "#include <pybind11/embed.h>\n";
                    wrapper << "namespace py = pybind11;\n";
                    wrapper << "int main() {\n";
                    wrapper << "    py::scoped_interpreter guard{};\n";
                    wrapper << "    py::exec(R\"(" << std::ifstream(file).rdbuf() << ")\"));\n";
                    wrapper << "    return 0;\n";
                    wrapper << "}\n";
                    wrapper.close();
                    cpp_files.push_back("py_wrapper.cpp");
                    command += "-I/usr/include/python3.10 -lpython3.10 ";
                }
            }
        } else if (lang == "rust") {
            for (const auto& file : other_files) {
                if (file.ends_with(".rs")) {
                    std::system(("rustc --crate-type=staticlib -o libtemp.a " + file).c_str());
                    command += "libtemp.a ";
                }
            }
        } else if (lang == "javascript") {
            for (const auto& file : other_files) {
                if (file.ends_with(".js")) {
                    std::system(("pkg " + file + " -o temp_js").c_str());
                    command += "temp_js.o ";
                }
            }
        }
    }

    // Compile C++ files
    for (const auto& file : cpp_files) {
        command += file + " ";
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
