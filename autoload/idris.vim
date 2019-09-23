let s:BUFFER = SpaceVim#api#import('vim#buffer')

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

function! idris#refine()
    let view = winsaveview()
    w
    let cline = line(".")
    let word = expand("<cword>")
    let tc = idris#reload(1)

    let name = input ("Name: ")

    if (tc is "")
        let result = s:IdrisCommand(":ref!", cline, word, name)
        if (! (result is ""))
            call IWrite(result)
        else
            e
            call winrestview(view)
        endif
    endif
endfunction

function! IdrisAddMissing()
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

function! IdrisCaseSplit()
    let view = winsaveview()
    let cline = line(".")
    let word = expand("<cword>")
    let tc = IdrisReloadToLine(cline)

    if (tc is "")
        let result = s:IdrisCommand(":cs!", cline, word)
        if (! (result is ""))
            call IWrite(result)
        else
            e
            call winrestview(view)
        endif
    endif
endfunction

function! IdrisMakeWith()
    let view = winsaveview()
    w
    let cline = line(".")
    let word = s:currentQueryObject()
    let tc = IdrisReload(1)

    if (tc is "")
        let result = s:IdrisCommand(":mw!", cline, word)
        if (! (result is ""))
            call IWrite(result)
        else
            e
            call winrestview(view)
            call search("_")
        endif
    endif
endfunction

function! IdrisMakeCase()
    let view = winsaveview()
    w
    let cline = line(".")
    let word = s:currentQueryObject()
    let tc = IdrisReload(1)

    if (tc is "")
        let result = s:IdrisCommand(":mc!", cline, word)
        if (! (result is ""))
            call IWrite(result)
        else
            e
            call winrestview(view)
            call search("_")
        endif
    endif
endfunction

function! IdrisAddClause(proof)
    let view = winsaveview()
    w
    let cline = line(".")
    let word = expand("<cword>")
    let tc = IdrisReloadToLine(cline)

    if (tc is "")
        if (a:proof==0)
            let fn = ":ac!"
        else
            let fn = ":apc!"
        endif

        let result = s:IdrisCommand(fn, cline, word)
        if (! (result is ""))
            call IWrite(result)
        else
            e
            call winrestview(view)
            call search(word)

        endif
    endif
endfunction

function! IdrisEval()
    w
    let tc = IdrisReload(1)
    if (tc is "")
        let expr = input ("Expression: ")
        let result = s:IdrisCommand(expr)
        call IWrite(" = " . result)
    endif
endfunction
function! IdrisMakeLemma()
    let view = winsaveview()
    w
    let cline = line(".")
    let word = s:currentQueryObject()
    let tc = IdrisReload(1)

    if (tc is "")
        let result = s:IdrisCommand(":ml!", cline, word)
        if (! (result is ""))
            call IWrite(result)
        else
            e
            call winrestview(view)
            call search(word, "b")
        endif
    endif
endfunction

function! IdrisResponseWin()
    if (!bufexists("idris-response"))
        botright 10split
        badd idris-response
        b idris-response
        let g:idris_respwin = "active"
        set buftype=nofile
        wincmd k
    elseif (bufexists("idris-response") && g:idris_respwin == "hidden")
        botright 10split
        b idris-response
        let g:idris_respwin = "active"
        wincmd k
    endif
endfunction

function! IdrisHideResponseWin()
    let g:idris_respwin = "hidden"
endfunction

function! IdrisShowResponseWin()
    let g:idris_respwin = "active"
endfunction

function! IWrite(str)
    if (bufexists("idris-response"))
        let bufnr = bufnr("idris-response")
        let lines = split(a:str, '\n')
        call s:BUFFER.buf_set_lines(bufnr, 0 , -1, 0, lines)
    else
        echo a:str
    endif
endfunction

function! IdrisReloadToLine(cline)
    return IdrisReload(1)
    "w
    "let file = expand("%:p")
    "let tc = s:IdrisCommand(":lto", a:cline, file)
    "if (! (tc is ""))
    "  call IWrite(tc)
    "endif
    "return tc
endfunction




