" ingo/fs/path.vim: Functions for manipulating a file system path.
"
" DEPENDENCIES:
"   - ingo/os.vim autoload script
"
" Copyright: (C) 2012-2013 Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
"
" REVISION	DATE		REMARKS
"   1.014.006	26-Sep-2013	ingo#fs#path#Normalize(): Also convert between
"				the different D:\ and /cygdrive/d/ notations on
"				Windows and Cygwin.
"   1.013.005	13-Sep-2013	Use operating system detection functions from
"				ingo/os.vim.
"   1.011.004	01-Aug-2013	Extract ingo#fs#path#IsUncPathRoot().
"   1.010.003	08-Jul-2013	Add prefix to exception thrown from
"				ingo#fs#path#GetRootDir().
"   1.009.002	26-Jun-2013	Add ingo#fs#path#Equals().
"				Minor: Remove duplication.
"   1.007.001	01-Jun-2013	file creation from ingofile.vim

function! ingo#fs#path#Separator()
    return (exists('+shellslash') && ! &shellslash ? '\' : '/')
endfunction

function! ingo#fs#path#Normalize( filespec, ... )
"******************************************************************************
"* PURPOSE:
"   Change all path separators in a:filespec to the passed or the typical format
"   for the current platform.
"   On Windows and Cygwin, also converts between the different D:\ and
"   /cygdrive/d/ notations.
"* ASSUMPTIONS / PRECONDITIONS:
"   None.
"* EFFECTS / POSTCONDITIONS:
"   None.
"* INPUTS:
"   a:filespec  Filespec, potentially with mixed / and \ path separators.
"   a:pathSeparator Optional path separator to be used.
"* RETURN VALUES:
"   a:filespec with uniform path separators, according to the platform.
"******************************************************************************
    let l:pathSeparator = (a:0 ? a:1 : ingo#fs#path#Separator())
    let l:badSeparator = (l:pathSeparator ==# '/' ? '\' : '/')
    let l:result = tr(a:filespec, l:badSeparator, l:pathSeparator)

    if ingo#os#IsWinOrDos()
	let l:result = substitute(l:result, '^[/\\]cygdrive[/\\]\(\a\)\ze[/\\]', '\u\1:', '')
    elseif ingo#os#IsCygwin()
	let l:result = substitute(l:result, '^\(\a\):', '/cygdrive/\l\1', '')
    endif

    return l:result
endfunction

function! ingo#fs#path#Combine( first, ... )
"******************************************************************************
"* PURPOSE:
"   Concatenate the passed filespec fragments into a filespec, ensuring that all
"   fragments are combined with proper path separators.
"* ASSUMPTIONS / PRECONDITIONS:
"   None.
"* EFFECTS / POSTCONDITIONS:
"   None.
"* INPUTS:
"   Either pass a dirspec and one or many filenames:
"	a:dirspec, a:filename [, a:filename2, ...]
"   Or a single list containing all filespec fragments.
"	[a:dirspec, a:filename, ...]
"* RETURN VALUES:
"   Combined filespec.
"******************************************************************************
    if type(a:first) == type([])
	let l:dirspec = a:first[0]
	let l:filenames = a:first[1:]
    else
	let l:dirspec = a:first
	let l:filenames = a:000
    endif

    " Use path separator as exemplified by the passed dirspec.
    if l:dirspec =~# '\' && l:dirspec !~# '/'
	let l:pathSeparator = '\'
    elseif l:dirspec =~# '/'
	let l:pathSeparator = '/'
    else
	" The dirspec doesn't contain a path separator, fall back to the
	" system's default.
	let l:pathSeparator = ingo#fs#path#Separator()
    endif

    let l:filespec = l:dirspec
    for l:filename in l:filenames
	let l:filename = substitute(l:filename, '^[/\\]', '', '')
	let l:filespec .= (l:filespec =~# '^$\|[/\\]$' ? '' : l:pathSeparator) . l:filename
    endfor

    return l:filespec
endfunction

function! ingo#fs#path#IsUncPathRoot( filespec )
    let l:ps = escape(ingo#fs#path#Separator(), '\')
    let l:uncPathPattern = printf('^%s%s[^%s]\+%s[^%s]\+$', l:ps, l:ps, l:ps, l:ps, l:ps)
    return (a:filespec =~# l:uncPathPattern)
endfunction
function! ingo#fs#path#GetRootDir( filespec )
    if ! ingo#os#IsWinOrDos()
	return '/'
    endif

    let l:dir = a:filespec
    while fnamemodify(l:dir, ':h') !=# l:dir && ! ingo#fs#path#IsUncPathRoot(l:dir)
	let l:dir = fnamemodify(l:dir, ':h')
    endwhile

    if empty(l:dir)
	throw 'GetRootDir: Could not determine root dir!'
    endif

    return l:dir
endfunction

if ingo#os#IsWinOrDos()
    function! ingo#fs#path#Equals( p1, p2 )
	return a:p1 ==? a:p2 || ingo#fs#path#Normalize(fnamemodify(a:p1, ':p')) ==? ingo#fs#path#Normalize(fnamemodify(a:p2, ':p'))
    endfunction
else
    function! ingo#fs#path#Equals( p1, p2 )
	return a:p1 ==# a:p2 || ingo#fs#path#Normalize(fnamemodify(resolve(a:p1), ':p')) ==# ingo#fs#path#Normalize(fnamemodify(resolve(a:p2), ':p'))
    endfunction
endif

" vim: set ts=8 sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
