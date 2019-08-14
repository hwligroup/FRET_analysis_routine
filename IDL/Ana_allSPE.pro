device, decompose=0

; load color table
loadct, 5
COMMON colors, R_ORIG, G_ORIG, B_ORIG, R_CURR, G_CURR, B_CURR
;dir= "C:\Users\Chih-Hao\.idl\IDL program"
;dir = "C:\Users\Chih-Hao\.idl\IDL program"
dir = "C:\Users\IDL\TIR DATA\"
;dir="F:\Chihhao mRAD51 assembly smFRET\"
print, "輸入資料夾名稱後，會自動分析所有子資料夾中的PMA檔，找點是利用前10 frames"
dir_input = ""
read, dir_input
wdelete, 0
path = dir + dir_input
print, path

foo_dirs = findfile(path + '\*')
nfoo_dirs = size(foo_dirs)

nsub_dirs = 0                ; figure number of sub-directories
for i = 2, nfoo_dirs(1) - 1 do begin
  if rstrpos(foo_dirs(i),'\') eq (strlen(foo_dirs(i)) - 1) then begin
    nsub_dirs = nsub_dirs + 1
  endif
endfor

; print, "found : ", nsub_dirs, " sub-directories, which are :"
sub_dirs = strarr(nsub_dirs)
j = 0
for i = 2, nfoo_dirs(1) - 1 do begin    ; get sub-directory names
  if rstrpos(foo_dirs(i),'\') eq (strlen(foo_dirs(i)) - 1) then begin
    sub_dirs(j) = foo_dirs(i)
    j = j + 1
  endif
endfor

; for i = 0, nsub_dirs - 1 do begin     ; print sub_directory names
;   print, sub_dirs(i)
; endfor

; now go through sub-directories finding the files to be analyzed and
; analyzing them if necessary.

for i = 0, nsub_dirs - 1 do begin

  print, "Current Directory : ", sub_dirs(i)
  
  ; find all the *.pma files in the sub-directory
  ; analyze them if there is no currently existing .pks file
  
  f_to_a = findfile(sub_dirs(i) + '*.spe')
  nf_to_a = size(f_to_a)
  
  for j = 0, nf_to_a(1) - 1 do begin
    f_to_a(j) = strmid(f_to_a(j), 0, strlen(f_to_a(j)) - 4)
    ;openr, 1, f_to_a(j) + ".pks", ERROR = err
    close, 1

      ; print, "Working on : ", f_to_a(j), err
      print, ""
      print, "Working on : ", f_to_a(j)
      find_SPEpeaks, f_to_a(j)
      print, ""
      print, "Extracting frames..."
      analyze_SPEpeaks, f_to_a(j)
      
      
      ;if cy5_flag eq "y" then begin
      ;find_peaks_shutter, f_to_a(j)
      ;analyze_peaks_shutter, f_to_a(j)
      ;endif else begin
      
      ;endelse

  endfor
endfor

print, ""
print, "Done."
print, "\^O^/"
print, ""
end