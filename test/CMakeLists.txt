# Copyright (C) Huawei Technologies Co., Ltd. 2025. All rights reserved.
# SPDX-License-Identifier: MIT
target_compile_definitions(vatomic INTERFACE _GNU_SOURCE)

# All C code is C99 compliant expect for the dispatch macro. When a test uses
# that macro we do not set pedantic.
set(TEST_C_WARN_OPTS -Wall -Wextra -Werror -Wpedantic)
set(TEST_C_EXT_WARN_OPTS -Wall -Wextra -Werror)

if(CMAKE_SYSTEM_PROCESSOR MATCHES riscv)
    # 8- and 16-bit atomics are taken from the platform's libatomic library.
    link_libraries(atomic)
endif()

add_subdirectory(atomics_basic)
add_subdirectory(atomics_cxx)
add_subdirectory(atomics_gen)
add_subdirectory(atomics)
add_subdirectory(sanity)
