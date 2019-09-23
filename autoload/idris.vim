function! idris#Reload(p)
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
