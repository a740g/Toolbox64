# TOOLBOX64

This is A740G's Toolbox. A collection of libraries for [QB64-PE](https://github.com/QB64-Phoenix-Edition/QB64pe).

## USAGE

This works best when it is used as a [Git submodule](https://git-scm.com/book/en/v2/Git-Tools-Submodules):

- Open Terminal and change to your project directory using an appropriate OS command
- Run `git submodule add https://github.com/a740g/Toolbox64 include` to add this repository as a [Git submodule](https://git-scm.com/book/en/v2/Git-Tools-Submodules) in the `include` subdirectory
- Run `git submodule update --init --recursive` to initialize, fetch and checkout git submodules

Assuming you made this a [Git submodule](https://git-scm.com/book/en/v2/Git-Tools-Submodules) in a directory called `include` in your source tree, do the following:

```vb
' At the top of your code include the library_name.bi file (if it has one)
'$Include:'include/library_name.bi'

' Your code here...

' At the bottom of your code include the library_name.bas file (if it has one)
'$Include:'include/library_name.bas'
```

## NOTES

- I made this for myself and as such, it is tailored to my coding style and conventions
- Expect this to keep changing and evolving
- This requires the latest version of [QB64-PE](https://github.com/QB64-Phoenix-Edition/QB64pe/releases/latest)
- All files here are in source-only form and will never include any binaries
- There is no directory structure. This lends itself well to the fact that you can conveniently use this as a [Git submodule](https://git-scm.com/book/en/v2/Git-Tools-Submodules)
- All library files have include guards. You can include these multiple times (even from your own include files)
- I do not use the `.bm` extension because GitHub does not syntax-highlight `.bm` files
- There is no documentation because I do not have the time to write those. The source code is (in most cases) self-documenting
- I use this in most of my QB64-PE projects. Those projects in most cases have a brief API documentaion and also should have good amounts of example code to get you started
