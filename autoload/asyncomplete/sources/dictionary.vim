let s:String = vital#asyncompletedictionary#import('Data.String')
let s:List   = vital#asyncompletedictionary#import('Data.List')

let s:loaded_dictionary = 0
let s:dictionary_cache = {}

let s:filetype_cache = {}

function! s:load_dictionary() abort
  if !s:loaded_dictionary
    let l:matches = []
    let l:rawpathes = split(&dictionary, '[^\\]\zs,\ze')
    let l:dictionaries = s:List.map(l:rawpathes, {v -> substitute(v, '\\,', ',', '') })

    for l:dictionary in l:dictionaries
      if filereadable(l:dictionary)
        let s:dictionary_cache[l:dictionary] = readfile(l:dictionary)
        sleep 100m
      endif
    endfor

    let s:loaded_dictionary = 1
    call asyncomplete#log('dictionary', 'cached dictionary')
  endif
endfunction

function! s:get_cache(filetype) abort
  " If not loaded, return null list
  if !s:loaded_dictionary
    return []
  endif

  " If has cache data, return this
  if has_key(s:filetype_cache, a:filetype)
    return s:filetype_cache[a:filetype]
  endif

  let l:matches = []

  for l:dictionary in values(s:dictionary_cache)
    let l:matches = l:matches + l:dictionary
  endfor

  let l:pairs = s:List.map(l:matches, {v -> [v] + s:String.nsplit(v, 2, '\s\+') })

  let s:filetype_cache[a:filetype] = s:List.map(l:pairs,
    \ { v
    \   -> {'word':v[1] , 'info':v[0] , 'menu':'[dict]', 'dup': 1, 'icase': 1}
    \ }
    \)

  call asyncomplete#log('dictionary','cached filetype', a:filetype)
  return s:filetype_cache[a:filetype]
endfunction

function! asyncomplete#sources#dictionary#completor(opt, ctx) abort
  let l:typed = a:ctx['typed']
  let l:col = a:ctx['col']

  let l:kw = matchstr(l:typed, '\w\+$')
  let l:kwlen = len(l:kw)
  let l:startcol = l:col - l:kwlen

  if a:opt['minlen'] <= l:kwlen
    let l:cache = s:get_cache(&filetype)

    let l:filtered_cache = s:List.filter(l:cache,
      \ {v -> match(v.word, '\c^' . s:String.escape_pattern(l:kw)) != -1})

    call asyncomplete#complete(a:opt['name'], a:ctx, l:startcol, l:filtered_cache)
  else
    call asyncomplete#log('dictionary', 'not fire,refresh need', l:kw, string(l:kwlen))
    call asyncomplete#complete(a:opt['name'], a:ctx, l:startcol, [], 1)
  endif
endfunction

function! asyncomplete#sources#dictionary#get_source_options(opts) abort

  " load dictionary
  call timer_start(0, { timer ->  s:load_dictionary() })

  return extend(extend({}, a:opts), {
    \ 'minlen': 3,
    \ })
endfunction

" EOF
