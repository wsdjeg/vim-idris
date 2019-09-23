function! s:IdrisCommand(...)
    let idriscmd = shellescape(join(a:000))
    return system("idris --client " . idriscmd)
endfunction

" Text near cursor position that needs to be passed to a command.
" Refinment of `expand(<cword>)` to accomodate differences between
" a (n)vim word and what Idris requires.
function! s:currentQueryObject()
    let word = expand("<cword>")
    if word =~ '^?'
        " Cut off '?' that introduces a hole identifier.
        let word = strpart(word, 1)
    endif
    return word
endfunction

function! idris#reload(p)
    w
    let file = expand("%:p")
    let tc = s:IdrisCommand(":l", file)
    if (! (tc is ""))
        call IWrite(tc)
    else
        if (a:q==0)
            echo "Successfully reloaded " . file
            call IWrite("")
        endif
    endif
    return tc

endfunction

function! idris#addMissing()
    let view = winsaveview()
    w
    let cline = line(".")
    let word = expand("<cword>")
    let tc = IdrisReload(1)

    if (tc is "")
        let result = s:IdrisCommand(":am!", cline, word)
        if (! (result is ""))
            call IWrite(result)
        else
            e
            call winrestview(view)
        endif
    endif
endfunction

function! idris#docFold(lineNum)
    let line = getline(a:lineNum)

    if line =~ "^\s*|||"
        return "1"
    endif

    return "0"
endfunction


function! idris#showType()
    w
    let word = s:currentQueryObject()
    let cline = line(".")
    let tc = idris#reloadToLine(cline)
    if (! (tc is ""))
        echo tc
    else
        let ty = s:IdrisCommand(":t", word)
        call IWrite(ty)
    endif
    return tc
endfunction

function! idris#proofSearch(hint)
    let view = winsaveview()
    w
    let cline = line(".")
    let word = s:currentQueryObject()
    let tc = idris#reload(1)

    if (a:hint==0)
        let hints = ""
    else
        let hints = input ("Hints: ")
    endif

    if (tc is "")
        let result = s:IdrisCommand(":ps!", cline, word, hints)
        if (! (result is ""))
            call IWrite(result)
        else
            e
            call winrestview(view)
        endif
    endif
endfunction
