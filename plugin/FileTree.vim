" opsplorer - treeview file explorer for vim
"
" Author:  Yury Altukhou
" Date:    2004-11-21
" Email:   wind-xp@tut.by
" Version: 0.9
"
" see :help FileTree.txt for detailed description

" setup command
com! -nargs=* -complete=dir FileTree cal FileTree(<f-args>)

let g:Tree_GetSubNodesFunction="glob"
"
"
" b:file_match_pattern
" b:show_hidden_files
" s:ATTRIBUTE_SEPARATOR=':'
"
"



fu! FileTree(...) "{{{1
	" create explorer window
	" take argument as path, if given
	if a:0>0 "{{{2
		let path=a:1
	else
		" otherwise current dir
		let path=getcwd()
	end "}}}2
	" substitute leading ~
	" (doesn't work with isdirectory() otherwise!)
	let path=fnamemodify(path,":p")
	" expand, if relative path
	if path[0]!="/" "{{{2
		let path=getcwd()."/".path
	end "}}}2
	if path[ strlen (path)-1]=='/' "{{{2
		let path=strpart (path,0, strlen (path)-1)
	end "}}}2
	call Tree_NewTreeWindow (path.'<d>',1,40,40,"FileTree_InitOptions")
endf "}}}1

" callback functions for Tree Plugin

function! FileTree_InitOptions () "{{{1
		let s:ATTRIBUTE_SEPARATOR=':'
		let b:Tree_ColorFunction="FileTree_InitColors" 
		let b:Tree_IsLeafFunction="FileTree_IsLeaf" 
		let b:Tree_GetSubNodesFunction="FileTree_GetSubNodes" 
		let b:Tree_InitMappingsFunction="FileTree_InitMappings" 
		let b:Tree_OnLeafClick="FileTree_OnLeafClick"
		let b:file_match_pattern="*"
		let b:show_hidden_files=0
endfunction "}}}1

function! FileTree_InitColors () "{{{1 
		syn match Directory  "[^<>]\+\ze<d.*>"
		syn match File "[^<>]\+\ze<f.*>"
		syn match VimFile "[^<>]\+\.vim\ze<f.*>"
		syn match Hidden "<[^<>]*>"

		hi link FIle Label
		hi link VimFIle Label
		exe "hi Hidden guifg=".synIDattr (hlID("Normal"), "bg#")
		hi link Directory  Comment
endfunction "}}}1

function! FileTree_InitMappings () "{{{1
	noremap <silent> <buffer> M :call <SID>SetMatchPattern ()<CR>
	noremap <silent> <buffer> H :call <SID>ToggleShowHidden ()<CR>
	noremap <silent> <buffer> n :call <SID>InsertFilename ()<CR>
	noremap <silent> <buffer> p :call <SID>InsertFileContent ()<CR>
	noremap <silent> <buffer> s :call <SID>FileSee ()<CR>
	noremap <silent> <buffer> N :call <SID>FileRename ()<CR>
	noremap <silent> <buffer> D :call <SID>FileDelete ()<CR>
	noremap <silent> <buffer> C :call <SID>FileCopy ()<CR>
	noremap <silent> <buffer> O :call <SID>FileMove ()<CR>
endfunction	"}}}1

function! FileTree_IsLeaf (path) "{{{1 
	let attributes=s:GetAttributes(a:path)
	return attributes[0]=='f' 
endfunction "}}}1

function! FileTree_GetSubNodes (path) "{{{1 
	return s:ListDirEntries(a:path)
endfunction "}}}1

function! FileTree_OnLeafClick (path) "{{{1
	let path =s:RemoveAttributes(a:path)
	call s:OpenFile (path)
endfunction "}}}1

" script private functions

function! s:OpenFile (path) "{{{1
	if filereadable(a:path) "{{{2
		" go to last accessed buffer
		wincmd p
		" append sequence for opening file
		execute "cd ".fnamemodify(a:path,":h")
		execute "e ".a:path
		setlocal modifiable
	endif "}}}2
endfunction "}}}1

function! s:ListDirEntries(path) "{{{1
	let path=<SID>RemoveAttributes(a:path)
	let attributes=s:GetAttributes(a:path)
	"find all files in the directory
	let fileList=glob(path.'/'.b:file_match_pattern)."\n"
	if b:show_hidden_files "{{{2
		" find all hidden files 
		let fileList=fileList.glob(path.'/.'.b:file_match_pattern)."\n"
	endif "}}}2

	let fls=''
	let dirs="\n"
	while strlen(fileList)>0 "{{{2
		let entry=GetNextLine (fileList)
		let fileList=CutFirstLine(fileList)

		"skipping empty entries
		if entry=='' "{{{3 
			continue
		endif "}}}3

		if isdirectory(entry)  "{{{3
			"if entry is directory then mark it with d flag
			let entry=entry."<d>"
			let entry=substitute (entry,path.'/','','g')
			let dirs=dirs.entry."\n"
		else
			let entry=entry."<f>"
			let entry=substitute (entry,path.'/','','g')
			let fls=fls.entry."\n"
		endif "}}}3
	endwhile "}}}2

	"remove . && .. directories
	let dirs=substitute(dirs,"\n..<d>\n",'\n','g')
	let dirs=substitute(dirs,"\n.<d>\n",'\n','g')
	return dirs.fls
endfunction "}}}1

function! s:IsDirectory(path) "{{{1
	let path=s:RemoveAttributes (a:path)
	let attributes=s:GetAttributes (a:path)
	return attributes[0]!='f'
endfunction "}}}1

function! s:SetMatchPattern () "{{{1
	let b:file_match_pattern=input ("Match pattern: ",b:file_match_pattern)
	call Tree_RebuildTree()
endfunction "}}}1

function! s:ToggleShowHidden() "{{{1
	let b:show_hidden_files = 1-b:show_hidden_files
	call Tree_RebuildTree()
endfunction "}}}1

function! s:GetPathUnderCursor () "{{{1
	let path=Tree_GetPathUnderCursor()
	return <SID>RemoveAttributes (path)
endfunction "}}}1

function! s:RemoveAttributes (path) "{{{1
	return substitute(a:path,"<[^><]*>",'','g')
endfunction "}}}1

function! s:GetAttributes (path) "{{{1
	return substitute(a:path,'.*<\([^<>]*\)>$','\1','')
endfunction "}}}1

function! s:InsertFilename() "{{{1
	"normal 1|g^
	let filename=<SID>GetPathUnderCursor()
	wincmd p
	execute "normal a".filename
endfunction "}}}1

function! s:InsertFileContent() "{{{1
	"norm 1|g^
	let filename=<SID>GetPathUnderCursor()
	if filereadable(filename) "{{{2
		wincmd p
		execute "r ".filename
	endif "}}}2
endfunction "}}}1

function! s:FileSee() "{{{1
	let filename=<SID>GetPathUnderCursor()
	if filereadable(filename) "{{{2
		let i=system("see ".filename."&")
	endif "}}}2
endf "}}}1

function! s:FileRename() "{{{1
	let filename=<SID>GetPathUnderCursor()
	if filereadable(filename) "{{{2
		let newfilename=input("Rename to: ",filename)
		if filereadable(newfilename) "{{{3
			if input("File exists, overwrite?")=~"^[yY]" "{{{4
				setlocal ma
				let i=system("mv -f ".filename." ".newfilename)
				" refresh display
				normal gg$
				call Tree_RebuildTree ()
				"call OnDoubleClick(-1)
			endif "}}}4
		else
			" rename file
			setlocal ma
			let i=system("mv ".filename." ".newfilename)
			normal gg$
			"call OnDoubleClick(-1)
			call Tree_RebuildTree ()

		endif "}}}3
	endif "}}}2
endf "}}}1

function! s:FileDelete() "{{{1
	let filename=<SID>GetPathUnderCursor()
	if filereadable(filename) "{{{2
		if input("OK to delete ".fnamemodify(filename,":t")."? ")[0]=~"[yY]" "{{{3
			let i=system("rm -f ".filename)
			setlocal modifiable
			normal ddg^
			setlocal nomodifiable nomodified
		endif "}}}3
	endif  "}}}2
endfunction "}}}1

function! s:FileCopy() "{{{1
	let filename=<SID>GetPathUnderCursor()
	if filereadable(filename) "{{{2
		let newfilename=input("Copy to: ",filename)
		if filereadable(newfilename) "{{{3
			if input("File exists, overwrite?")=~"^[yY]" "{{{4
				" copy file
				let i=system("cp -f ".filename." ".newfilename)
				call Tree_RebuildTree()	
			endif "}}}4
		else
			" copy file
			let i=system("cp ".filename." ".newfilename)
			call Tree_RebuildTree()
		endif "}}}3
	endif "}}}2
endfunction "}}}1

function! s:FileMove() "{{{1
	let filename=<SID>GetPathUnderCursor ()
	if filereadable(filename) "{{{2
		let newfilename=input("Move to: ",filename)
		if filereadable(newfilename) "{{{3
			if input("File exists, overwrite?")=~"^[yY]" "{{{4
				" move file
				let i=system("mv -f ".filename." ".newfilename)
				call Tree_RebuildTree()
			endif "}}}4
		else
			" move file
			let i=system("mv ".filename." ".newfilename)
			call Tree_RebuildTree()
		endif "}}}3
	endif "}}}2
endfunction "}}}1 
