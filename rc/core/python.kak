# http://python.org
# ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾

# Detection
# ‾‾‾‾‾‾‾‾‾

hook global BufCreate .*[.](py) %{
    set-option buffer filetype python
}

# Highlighters & Completion
# ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾

add-highlighter shared/ regions -default code python \
    double_string '"""' '"""'            '' \
    single_string "'''" "'''"            '' \
    double_string '"'   (?<!\\)(\\\\)*"  '' \
    single_string "'"   (?<!\\)(\\\\)*'  '' \
    comment       '#'   '$'              ''

add-highlighter shared/python/double_string fill string
add-highlighter shared/python/single_string fill string
add-highlighter shared/python/comment       fill comment

%sh{
    # Grammar
    values="True|False|None"
    meta="import|from"
    # Keyword list is collected using `keyword.kwlist` from `keyword`
    keywords="and|as|assert|break|class|continue|def|del|elif|else|except|exec"
    keywords="${keywords}|finally|for|global|if|in|is|lambda|not|or|pass|print"
    keywords="${keywords}|raise|return|try|while|with|yield"
    types="bool|buffer|bytearray|bytes|complex|dict|file|float|frozenset|int"
    types="${types}|list|long|memoryview|object|set|str|tuple|unicode|xrange"
    functions="abs|all|any|ascii|bin|callable|chr|classmethod|compile|complex"
    functions="${functions}|delattr|dict|dir|divmod|enumerate|eval|exec|filter"
    functions="${functions}|format|frozenset|getattr|globals|hasattr|hash|help"
    functions="${functions}|hex|id|__import__|input|isinstance|issubclass|iter"
    functions="${functions}|len|locals|map|max|memoryview|min|next|oct|open|ord"
    functions="${functions}|pow|print|property|range|repr|reversed|round"
    functions="${functions}|setattr|slice|sorted|staticmethod|sum|super|type|vars|zip"

    # Add the language's grammar to the static completion list
    printf %s\\n "hook global WinSetOption filetype=python %{
        set-option window static_words '${values}:${meta}:${keywords}:${types}:${functions}'
    }" | sed 's,|,:,g'

    # Highlight keywords
    printf %s "
        add-highlighter shared/python/code regex '\b(${values})\b' 0:value
        add-highlighter shared/python/code regex '\b(${meta})\b' 0:meta
        add-highlighter shared/python/code regex '\b(${keywords})\b' 0:keyword
        add-highlighter shared/python/code regex '\b(${functions})\b\(' 1:builtin
    "

    # Highlight types and attributes
    printf %s "
        add-highlighter shared/python/code regex '\b(${types})\b' 0:type
        add-highlighter shared/python/code regex '@[\w_]+\b' 0:attribute
    "
}

# Commands
# ‾‾‾‾‾‾‾‾

define-command -hidden python-indent-on-new-line %{
    evaluate-commands -draft -itersel %{
        # copy '#' comment prefix and following white spaces
        try %{ execute-keys -draft k <a-x> s ^\h*#\h* <ret> y jgh P }
        # preserve previous line indent
        try %{ execute-keys -draft \; K <a-&> }
        # cleanup trailing whitespaces from previous line
        try %{ execute-keys -draft k <a-x> s \h+$ <ret> d }
        # indent after line ending with :
        try %{ execute-keys -draft <space> k x <a-k> :$ <ret> j <a-gt> }
    }
}

# Initialization
# ‾‾‾‾‾‾‾‾‾‾‾‾‾‾

hook -group python-highlight global WinSetOption filetype=python %{ add-highlighter window ref python }

hook global WinSetOption filetype=python %{
    hook window InsertChar \n -group python-indent python-indent-on-new-line
    # cleanup trailing whitespaces on current line insert end
    hook window InsertEnd .* -group python-indent %{ try %{ execute-keys -draft \; <a-x> s ^\h+$ <ret> d } }
}

hook -group python-highlight global WinSetOption filetype=(?!python).* %{ remove-highlighter window/python }

hook global WinSetOption filetype=(?!python).* %{
    remove-hooks window python-indent
}
