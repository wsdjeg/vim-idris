let s:BUFFER = SpaceVim#api#import('vim#buffer')
let s:JOB = SpaceVim#api#import('job')

function! s:idrisCommand(...)
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

function! idris#reload(q)
    silent! w
    let file = expand("%:p")
    let tc = s:idrisCommand(":l", file)
    if (! (tc is ""))
        call idris#write(tc)
    else
        if (a:q==0)
            echo "Successfully reloaded " . file
            call idris#write("")
        endif
    endif
    return tc

endfunction

function! idris#addMissing()
    let view = winsaveview()
    silent! w
    let cline = line(".")
    let word = expand("<cword>")
    let tc = idris#reload(1)

    if (tc is "")
        let result = s:idrisCommand(":am!", cline, word)
        if (! (result is ""))
            call idris#write(result)
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


function! s:remove_empty_line(str) abort
    let strs = map(split(a:str, "\n"), '!empty(v:val)')
    return join(strs, "\n")
endfunction

function! idris#showType()
    silent! w
    let word = s:currentQueryObject()
    let cline = line(".")
    let tc = idris#reloadToLine(cline)
    normal! :
    if !empty(tc)
        echo s:remove_empty_line(tc)
    else
        let ty = s:idrisCommand(":t", word)
        call idris#write(ty)
    endif
    return tc
endfunction

function! idris#proofSearch(hint)
    let view = winsaveview()
    silent! w
    let cline = line(".")
    let word = s:currentQueryObject()
    let tc = idris#reload(1)

    if (a:hint==0)
        let hints = ""
    else
        let hints = input ("Hints: ")
    endif

    if (tc is "")
        let result = s:idrisCommand(":ps!", cline, word, hints)
        if (! (result is ""))
            call idris#write(result)
        else
            e
            call winrestview(view)
        endif
    endif
endfunction

function! idris#refine()
    let view = winsaveview()
    silent! w
    let cline = line(".")
    let word = expand("<cword>")
    let tc = idris#reload(1)

    let name = input ("Name: ")

    if (tc is "")
        let result = s:idrisCommand(":ref!", cline, word, name)
        if (! (result is ""))
            call idris#write(result)
        else
            e
            call winrestview(view)
        endif
    endif
endfunction

function! idris#caseSplit()
    let view = winsaveview()
    let cline = line(".")
    let word = expand("<cword>")
    let tc = idris#reloadToLine(cline)

    if (tc is "")
        let result = s:idrisCommand(":cs!", cline, word)
        if (! (result is ""))
            call idris#write(result)
        else
            e
            call winrestview(view)
        endif
    endif
endfunction

function! idris#makeWith()
    let view = winsaveview()
    silent! w
    let cline = line(".")
    let word = s:currentQueryObject()
    let tc = idris#reload(1)

    if (tc is "")
        let result = s:idrisCommand(":mw!", cline, word)
        if (! (result is ""))
            call idris#write(result)
        else
            e
            call winrestview(view)
            call search("_")
        endif
    endif
endfunction

function! idris#makeCase()
    let view = winsaveview()
    silent! w
    let cline = line(".")
    let word = s:currentQueryObject()
    let tc = idris#reload(1)

    if (tc is "")
        let result = s:idrisCommand(":mc!", cline, word)
        if (! (result is ""))
            call idris#write(result)
        else
            e
            call winrestview(view)
            call search("_")
        endif
    endif
endfunction

function! idris#addClause(proof)
    let view = winsaveview()
    silent! w
    let cline = line(".")
    let word = expand("<cword>")
    let tc = idris#reloadToLine(cline)

    if (tc is "")
        if (a:proof==0)
            let fn = ":ac!"
        else
            let fn = ":apc!"
        endif

        let result = s:idrisCommand(fn, cline, word)
        if (! (result is ""))
            call idris#write(result)
        else
            e
            call winrestview(view)
            call search(word)

        endif
    endif
endfunction

function! idris#eval()
    silent! w
    let tc = idris#reload(1)
    if (tc is "")
        let expr = input ("Expression: ")
        let result = s:idrisCommand(expr)
        call idris#write(" = " . result)
    endif
endfunction

function! idris#makeLemma()
    let view = winsaveview()
    silent! w
    let cline = line(".")
    let word = s:currentQueryObject()
    let tc = idris#reload(1)

    if (tc is "")
        let result = s:idrisCommand(":ml!", cline, word)
        if (! (result is ""))
            call idris#write(result)
        else
            e
            call winrestview(view)
            call search(word, "b")
        endif
    endif
endfunction

function! idris#responseWin()
    if !bufexists("idris-response")
        botright 10split
        badd idris-response
        b idris-response
        set buftype=nofile
        wincmd p
    else
        botright 10split
        b idris-response
        wincmd p
    endif
endfunction

function! idris#write(str)
    if (bufexists("idris-response"))
        let bufnr = bufnr("idris-response")
        let lines = split(a:str, '\n')
        call s:BUFFER.buf_set_lines(bufnr, 0 , -1, 0, lines)
    else
        echo a:str
    endif
endfunction

function! idris#reloadToLine(cline)
    return idris#reload(1)
    "w
    "let file = expand("%:p")
    "let tc = s:idrisCommand(":lto", a:cline, file)
    "if (! (tc is ""))
    "  call idris#write(tc)
    "endif
    "return tc
endfunction


function! s:stdout(id, data, event) abort
    
endfunction

function! idris#startRepl()
    return s:JOB.start('idris --nobanner', {
        \ 'on_stdout' : function('s:stdout'),
        \ 'on_stderr' : function('s:stdout'),
        \ 'on_exit' : function('s:stdout'),
        \ })
endfunction

function! idris#showDoc()
  silent! w
  let word = expand("<cword>")
  let ty = s:idrisCommand(":doc", word)
  call idris#write(ty)
endfunction

