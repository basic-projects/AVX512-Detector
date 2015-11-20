# AVX512-Detector
Small utility to detect AVX512 and new Intel Skylake processor features. For Win64.

Small information utility for Win64.
Written in assembler, used FASM (Flat Assembler) translator,
FDBG debugger, and FASM Editor Integrated Development Environment
were used.
Detects some new features, supported by Skylake Xeon processor:
Advanced Vector Extension AVX512 and Cache Flush optimization
to control NV memory at address space.
Note.
NV (aka NVDIMM) is Non-Volatile Dual In Line Memory Module,
new hybrid RAM/Flash memory standard.

Небольшая информационная утилита для Win64.
Написана на ассемблере, использовался транслятор FASM
(Flat Assembler), отладчик FDBG и среда разработки FASM Editor.
Утилита детектирует некоторые новые возможности процессоров
Xeon Skylake:
векторное расширение AVX512 и оптимизированные методы очистки
кэш-памяти, необходимые для управления NV памятью в адресном
пространстве.
Примечание.
NV или NVDIMM означает Non-Volatile Dual In Line Memory Module,
это гибридные модули памяти, совмещающие преимущества оперативной
памяти и энергонезависимой Flash памяти.
