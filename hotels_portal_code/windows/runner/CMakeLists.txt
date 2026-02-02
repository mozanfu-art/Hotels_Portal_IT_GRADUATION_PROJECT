cmake_minimum_required(VERSION 3.14...3.25)
project(runner LANGUAGES CXX)

# Define the application target name (must match top-level BINARY_NAME)
set(BINARY_NAME "hotel_booking_app")

# Set FLUTTER_MANAGED_DIR for generated files
set(FLUTTER_MANAGED_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../flutter")

# === Compilation settings function ===
# Applies standard build settings to a target
function(APPLY_STANDARD_SETTINGS TARGET)
  target_compile_features(${TARGET} PUBLIC cxx_std_17)
  target_compile_options(${TARGET} PRIVATE /W4 /WX /wd"4100" /wd"4005")
  target_compile_options(${TARGET} PRIVATE /EHsc)
  target_compile_definitions(${TARGET} PRIVATE "_HAS_EXCEPTIONS=1")
  target_compile_definitions(${TARGET} PRIVATE "_CRT_SECURE_NO_WARNINGS")
  target_compile_definitions(${TARGET} PRIVATE "$<$<CONFIG:Debug>:_DEBUG>")
endfunction()

# === Application executable ===
add_executable(${BINARY_NAME} WIN32
  "flutter_window.cpp"
  "main.cpp"
  "utils.cpp"
  "win32_window.cpp"
  "${FLUTTER_MANAGED_DIR}/generated_plugin_registrant.cc"
  "Runner.rc"
  "runner.exe.manifest"
)

# Apply the standard compilation settings
APPLY_STANDARD_SETTINGS(${BINARY_NAME})

# Set C++ standard explicitly
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# Use multithreaded dynamic runtime to match Firebase libraries
set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>DLL")

# Add preprocessor definitions for Flutter version
target_compile_definitions(${BINARY_NAME} PRIVATE
  "FLUTTER_VERSION=\"${FLUTTER_VERSION}\""
  "FLUTTER_VERSION_MAJOR=${FLUTTER_VERSION_MAJOR}"
  "FLUTTER_VERSION_MINOR=${FLUTTER_VERSION_MINOR}"
  "FLUTTER_VERSION_PATCH=${FLUTTER_VERSION_PATCH}"
  "FLUTTER_VERSION_BUILD=${FLUTTER_VERSION_BUILD}"
  "NOMINMAX"
)

# Link dependency libraries
target_link_libraries(${BINARY_NAME} PRIVATE flutter flutter_wrapper_app dwmapi.lib)

# Suppress LNK4099 warnings for missing PDB files
target_link_options(${BINARY_NAME} PRIVATE "/ignore:4099")

# Include directories
target_include_directories(${BINARY_NAME} PRIVATE "${CMAKE_SOURCE_DIR}")

# Run Flutter build steps
# Removed flutter_assemble dependency to fix CMake error as flutter_assemble target does not exist in this context.
# add_dependencies(${BINARY_NAME} flutter_assemble)
