# Find CUDA

if(MSVC)
  # Setting this to true brakes Visual Studio builds.
  set(CUDA_ATTACH_VS_BUILD_RULE_TO_CUDA_FILE OFF CACHE BOOL "CUDA_ATTACH_VS_BUILD_RULE_TO_CUDA_FILE")
endif()

set(CUDA_FIND_QUIETLY TRUE)
find_package(CUDA 9.0)

if(CUDA_FOUND)
  message(STATUS "Found CUDA Toolkit v${CUDA_VERSION_STRING}")
  set(HAVE_CUDA TRUE)

  # CUDA_ARCH_BIN is a space separated list of versions to include in output so-file. So you can set CUDA_ARCH_BIN = 10 11 12 13 20
  # Also user can specify virtual arch in parenthesis to limit instructions set,
  # for example CUDA_ARCH_BIN = 11(11) 12(11) 13(11) 20(11) 21(11) -> forces using only sm_11 instructions.
  # The CMake scripts interpret XX as XX (XX). This allows user to omit parenthesis.
  # Arch 21 is an exceptional case since it doesn't have own sm_21 instructions set.
  # So 21 = 21(21) is an invalid configuration and user has to explicitly force previous sm_20 instruction set via 21(20).
  # CUDA_ARCH_BIN adds support of only listed GPUs. As alternative CMake scripts also parse 'CUDA_ARCH_PTX' variable,
  # which is a list of intermediate PTX codes to include in final so-file. The PTX code can/will be JIT compiled for any current or future GPU.
  # To add support of older GPU for kinfu, I would embed PTX 11 and 12 into so-file. GPU with sm_13 will run PTX 12 code (no difference for kinfu)

  # Find a complete list for CUDA compute capabilities at http://developer.nvidia.com/cuda-gpus
  
  # For a list showing CUDA toolkit version support for compute capabilities see: https://en.wikipedia.org/wiki/CUDA
  # or the nvidia release notes ie: 
  # https://docs.nvidia.com/cuda/cuda-toolkit-release-notes/index.html#cuda-general-new-features
  # or
  # https://docs.nvidia.com/cuda/cuda-toolkit-release-notes/index.html#deprecated-features
  if(NOT ${CUDA_VERSION_STRING} VERSION_LESS "11.1")
    set(__cuda_arch_bin "3.5 3.7 5.0 5.2 5.3 6.0 6.1 6.2 7.0 7.2 7.5 8.0 8.6")
  elseif(NOT ${CUDA_VERSION_STRING} VERSION_LESS "11.0")
    set(__cuda_arch_bin "3.5 3.7 5.0 5.2 5.3 6.0 6.1 6.2 7.0 7.2 7.5 8.0")
  elseif(NOT ${CUDA_VERSION_STRING} VERSION_LESS "10.0")
    set(__cuda_arch_bin "3.0 3.2 3.5 3.7 5.0 5.2 5.3 6.0 6.1 6.2 7.0 7.2 7.5")
  elseif(NOT ${CUDA_VERSION_STRING} VERSION_LESS "9.0")
    set(__cuda_arch_bin "3.0 3.2 3.5 3.7 5.0 5.2 5.3 6.0 6.1 6.2 7.0 7.2")
  endif()

  set(CUDA_ARCH_BIN ${__cuda_arch_bin} CACHE STRING "Specify 'real' GPU architectures to build binaries for, BIN(PTX) format is supported")

  set(CUDA_ARCH_PTX "" CACHE STRING "Specify 'virtual' PTX arch to build PTX intermediate code for. Example: 1.0 1.2 or 10 12")
  #set(CUDA_ARCH_PTX "1.1 1.2" CACHE STRING "Specify 'virtual' PTX arch to build PTX intermediate code for. Example: 1.0 1.2 or 10 12")

  # Guess this macros will be included in cmake distributive
  include(${PCL_SOURCE_DIR}/cmake/CudaComputeTargetFlags.cmake)
  APPEND_TARGET_ARCH_FLAGS()

  # Prevent compilation issues between recent gcc versions and old CUDA versions
  list(APPEND CUDA_NVCC_FLAGS "-D_FORCE_INLINES")
  
  # Allow calling a constexpr __host__ function from a __device__ function.
  list(APPEND CUDA_NVCC_FLAGS "--expt-relaxed-constexpr")
endif()
