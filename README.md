# TOOLBOX64

[Toolbox64](https://github.com/a740g/Toolbox64) is a collection of libraries for [QB64-PE](https://www.qb64phoenix.com/) that I routinely uses in my QB64-PE projects.

## USAGE

This is best used as a [Git submodule](https://git-scm.com/book/en/v2/Git-Tools-Submodules). Follow these steps:

1. Open your terminal and navigate to your project directory.
2. Add this repository as a Git submodule in the `include` subdirectory:

    ```bash
    git submodule add https://github.com/a740g/Toolbox64 include
    ```

3. Initialize and fetch the submodule:

    ```bash
    git submodule update --init --recursive
    ```

If you've added `Toolbox64` as a submodule in a directory named include, you can include library files in your project as follows:

1. At the top of your code, include the .bi file (if available):

    ```vb
    '$Include:'include/library_name.bi'
    ```

2. Write your main code.

3. At the bottom of your code, include the .bas file (if available):

    ```vb
    '$Include:'include/library_name.bas'
    ```

## NOTES

- The code here is tailored to my coding style and conventions.
- It is a work in progress and will continue to evolve.
- Requires the latest version of [QB64-PE](https://github.com/QB64-Phoenix-Edition/QB64pe/releases/latest).
- All files are provided in source-only form; no binaries are included.
- All library files include proper guards, allowing them to be included multiple times, even from within other include files.
- Files use standard `.bi` and `.bas` extensions for better syntax highlighting on GitHub (not `.bm`).
- There is no formal documentation. Most of the code is self-explanatory. Example usage can often be found in my other QB64-PE projects, which include brief API references and example code.
