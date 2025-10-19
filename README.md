# TOOLBOX64

[Toolbox64](https://github.com/a740g/Toolbox64) is a collection of libraries for [QB64-PE](https://www.qb64phoenix.com/) that I use regularly in my QB64-PE projects.

## USAGE

### Adding Toolbox64 to your own project

If you want to add Toolbox64 to an existing project, the simplest way is as a [Git submodule](https://git-scm.com/book/en/v2/Git-Tools-Submodules):

```bash
cd your-project
git submodule add https://github.com/a740g/Toolbox64 include
```

This will clone Toolbox64 into the `include` directory of your project.

### Cloning a project that already uses Toolbox64

If you clone a project that already has Toolbox64 as a submodule, you need to initialize and fetch it:

```bash
git submodule update --init --recursive
```

### Using the libraries in QB64-PE

Once Toolbox64 is available under the `include` directory, you can reference the libraries in your QB64-PE code:

1. At the top of your code, include the `.bi` file (if available):

    ```vb
    '$Include:'include/library_name.bi'
    ```

2. Write your main code.

3. At the bottom of your code, include the `.bas` file (if available):

    ```vb
    '$Include:'include/library_name.bas'
    ```

## NOTES

- The code follows my personal style and conventions.
- This is a work in progress and will continue to evolve.
- Requires the latest version of [QB64-PE](https://github.com/QB64-Phoenix-Edition/QB64pe/releases/latest).
- Source only — no binaries are included.
- All library files have proper include guards, so they can be safely included multiple times.
- Files use standard `.bi` and `.bas` extensions for better syntax highlighting on GitHub (not `.bm`).
- There is no formal documentation. Most code is self-explanatory, and you can find examples and brief API references in my other QB64-PE projects.
