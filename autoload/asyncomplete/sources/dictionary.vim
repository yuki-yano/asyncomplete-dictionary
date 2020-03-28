let s:String = vital#asyncompletedictionary#import('Data.String')
let s:List   = vital#asyncompletedictionary#import('Data.List')

let s:cache = {}

function! s:load_dictionary(filetype) abort
  if has_key(s:cache, a:filetype)
    return s:cache[a:filetype]
  endif

  let l:matches = []
  let l:rawpathes = split(&dictionary, '[^\\]\zs,\ze')
  let l:dictionaries = s:List.map(l:rawpathes, {v -> substitute(v, '\\,', ',', '') })

  for l:dictionary in l:dictionaries
    let l:matches = l:matches + readfile(l:dictionary)
  endfor

  let l:pairs = s:List.map(l:matches, {v -> [v] + s:String.nsplit(v, 2, '\s\+') })

  let s:cache[a:filetype] = s:List.map(l:pairs,
    \ { v
    \   -> {'word':v[1] , 'info':v[0] , 'menu':'[dict]', 'dup': 1, 'icase': 1}
    \ }
    \)

  return s:cache[a:filetype]
endfunction

function! asyncomplete#sources#dictionary#completor(opt, ctx) abort
  let l:typed = a:ctx['typed']
  let l:col = a:ctx['col']

  let l:kw = matchstr(l:typed, '\w\+$')
  let l:kwlen = len(l:kw)
  let l:startcol = l:col - l:kwlen

  let l:cache = s:load_dictionary(&filetype)

  let l:filtered_cache = s:List.filter(l:cache, {v -> match(v.word, '\c^' . s:String.escape_pattern(l:kw)) != -1})

  call asyncomplete#complete(a:opt['name'], a:ctx, l:startcol, l:filtered_cache)
endfunction

function! asyncomplete#sources#dictionary#get_source_options(opts) abort
  return extend(extend({}, a:opts), {})
endfunction

" EOF
