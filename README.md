# Mathdown
A lightweight syntax for matrices.
Outputs [MathML](https://en.wikipedia.org/wiki/MathML) format.

## Syntax
`1 2 3
3 2 8`
produces
![](images/mat1.png | width=400)

You can also use [Markdown](https://en.wikipedia.org/wiki/Markdown)-style text emphasis
- `_<text>_` or `*<text>*` for _italic_
- `__<text>__` or `**<text>**` for __bold__
- `___<text>___` or `***<text>***` for ___italic and bold___

`***1*** 2 __3__
3 _2_ 8`
produces
![](images/mat2.png width=400)

## Usage
`mathdown -i input.mth -o output.xml`

### Parameters
- `-i <file path>` Specifies the input path
- `-o <file path>` Specifies the output pathfile
- `-s` Uses square brackets
- `-r` Uses round brackets
