BEGIN{
	patch_indent=" "
}

{
	if ((record>=1) && (record<=4)) {
		++record
		if (record == 2) {
			print (patch_indent "// bug 1184009")
			print (patch_indent "#define MAX_PREVIEW_SOURCE_SIZE 4096")
			print (patch_indent)
		}
		else if (record == 3) {
			print $0
		}
		next
	}
	
	print $0
	
	if ($0 == (patch_indent "#define MAX_PREVIEW_SIZE 180"))
		record=1
}
