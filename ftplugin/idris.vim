if bufname('%') == "idris-response"
    finish
endif

if exists("b:did_ftplugin")
    finish
endif

function! IdrisFold(lineNum)
    return idris#docFold(a:lineNum)
endfunction

setlocal comments=s1:{-,mb:-,ex:-},:\|\|\|,:--
setlocal commentstring=--%s
setlocal iskeyword+=?
setlocal wildignore+=*.ibc
setlocal foldmethod=expr
setlocal foldexpr=IdrisFold(v:lnum)
call idris#startRepl()

let b:did_ftplugin = 1
