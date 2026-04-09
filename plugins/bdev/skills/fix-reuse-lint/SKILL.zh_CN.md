---
name: fix-reuse-lint
description: 通过添加版权和许可证头修复 REUSE lint 问题
---

运行 `reuse lint` 并根据要求修复项目。
当文件缺少版权声明时，
你需要阅读项目中的类似文件作为参考。
尽量模仿项目自身的风格
来修复许可证和版权声明。
如果项目本身没有明显的风格，
则使用 reuse annotate 命令为文件添加版权声明。
请参考项目中的文件来分析
文件内容应该声明为什么许可证。

```plaintext
Usage: reuse annotate [OPTIONS] PATH

  Add copyright and licensing into the headers of files.

  By using --copyright and --license, you can specify which copyright holders
  and licenses to add to the headers of the given files.

  By using --contributor, you can specify people or entity that contributed
  but are not copyright holder of the given files.

Options:
  -c, --copyright COPYRIGHT       Copyright statement, repeatable.
  -l, --license SPDX_IDENTIFIER   SPDX License Identifier, repeatable.
  --contributor CONTRIBUTOR       File contributor, repeatable.
  -y, --year YEAR                 Year of copyright statement.
  -s, --style [applescript|aspx|bat|bibtex|c|cpp|cppsingle|f|ftl|handlebars|haskell|html|jinja|julia|lisp|m4|ml|f90|plantuml|python|rst|semicolon|tex|man|vst|vim|xquery]
                                  Comment style to use.
  --copyright-prefix [spdx|spdx-c|spdx-string-c|spdx-string|spdx-string-symbol|spdx-symbol|string|string-c|string-symbol|symbol]
                                  Copyright prefix to use.
  -t, --template TEMPLATE         Name of template to use.
  --exclude-year                  Do not include year in copyright statement.
  --merge-copyrights              Merge copyright lines if copyright
                                  statements are identical.
  --single-line                   Force single-line comment style.
  --multi-line                    Force multi-line comment style.
  -r, --recursive                 Add headers to all files under specified
                                  directories recursively.
  --no-replace                    Do not replace the first header in the file;
                                  just add a new one.
  --force-dot-license             Always write a .license file instead of a
                                  header inside the file.
  --fallback-dot-license          Write a .license file to files with
                                  unrecognised comment styles.
  --skip-unrecognised             Skip files with unrecognised comment styles.
  --skip-existing                 Skip files that already contain REUSE
                                  information.
  --help                          Show the message and exit.
```
