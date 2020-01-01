if exists('g:autoloaded_db_verticas')
  finish
endif
let g:autoloaded_db_verticas = 1

function! db#adapter#vertica#canonicalize(url) abort
  let url = substitute(a:url, '^[^:]*:/\=/\@!', 'vertica:///', '')
  return db#url#absorb_params(url, {
		\ 'user': 'user',
		\ 'password': 'password',
		\ 'host': 'host',
		\ 'port': 'port',
		\ 'dbname': 'database'})
endfunction

function! db#adapter#vertica#interactive(url, ...) abort
  " let short = matchstr(a:url, '^[^:]*:\%(///\)\=\zs[^/?#]*$')
  " return 'vsql -w ' . (a:0 ? a:1 . ' ' : '') . shellescape(len(short) ? short : a:url)
  return 'vsql -U dbadmin -h localhost -d docker -p 5433'
endfunction

function! db#adapter#vertica#filter(url) abort
  return db#adapter#vertica#interactive(a:url,
		\ '-P columns=' . &columns . ' -v ON_ERROR_STOP=1 -f -')
endfunction

function! s:parse_columns(output, ...) abort
  let rows = map(split(a:output, "\n"), 'split(v:val, "|")')
  if a:0
    return map(filter(rows, 'len(v:val) > a:1'), 'v:val[a:1]')
  else
    return rows
  endif
endfunction

function! db#adapter#vertica#complete_database(url) abort
  let cmd = 'vsql -U dbadmin -h localhost -d docker -p 5433 --no-vsqlrc -wltAX ' .
        \ shellescape(substitute(a:url, '/[^/]*$', '/vertica', ''))
  return s:parse_columns(system(cmd), 0)
endfunction

function! db#adapter#vertica#complete_opaque(_) abort
  return db#adapter#vertica#complete_database('')
endfunction

function! db#adapter#vertica#can_echo(in, out) abort
  let out = readfile(a:out, 2)
  return len(out) == 1 && out[0] =~# '^[A-Z]\+\%( \d\+\| [A-Z]\+\)*$'
endfunction

function! db#adapter#vertica#tables(url) abort
  return s:parse_columns(system(
        \ db#adapter#vertica#filter(a:url) . ' --no-vsqlrc -tA -c "\dtvm"'), 1)
endfunction
