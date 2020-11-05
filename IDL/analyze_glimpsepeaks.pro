pro analyze_glimpsepeaks, filename_input
filename_input=['1']
loadct, 5

gaussian_peaks = fltarr(2,2,7,7)

for k = 0, 1 do begin
	for l = 0, 1 do begin
		offx = -0.5*float(k) ;若-0.5表示peak position偏移+0.5 (因為是減掉mean)
		offy = -0.5*float(l)
		for i = 0, 6 do begin
			for j = 0, 6 do begin
				;dist = 0.4 * ((float(i)-3.0+offx)^2 + (float(j)-3.0+offy)^2)
				dist = 0.3 * ((float(i)-3.0+offx)^2 + (float(j)-3.0+offy)^2)
				gaussian_peaks(k,l,i,j) = 2.0*exp(-dist)
			endfor
		endfor
	endfor
endfor

apeak  = fltarr(7,7)	; temp storage for analysis

; initialize variables

width = fix(1)
height = fix(1)
nframes  = fix(1)

close, 1				; make sure unit 1 is closed
close, 2


;;; input film
;;;;;openr, 1, filename_input + ".spe"
openr, 2, filename_input + ".pks"
cd, CURRENT=current_dir

; Read header.mat file using HDF5 functions
; The file needs to be v7.3 mat file
file = FILEPATH('header.mat', ROOT_DIR=current_dir)
file_id = H5F_OPEN(file)

nframes_id = H5D_OPEN(file_id, '/vid/nframes')
nframes = H5D_READ(nframes_id)
; index since read data gives array
nframes = LONG(nframes[0])
H5D_CLOSE, nframes_id

width_id = H5D_OPEN(file_id, '/vid/width/')
width = H5D_READ(width_id)
width = FIX(width[0])  ; The FIX function converts double to integer
H5D_CLOSE, width_id

height_id = H5D_OPEN(file_id, '/vid/height/')
height = H5D_READ(height_id)
height = FIX(height[0])
H5D_CLOSE, height_id


PRINT, nframes
PRINT, width
PRINT, height

filenumber_id = H5D_OPEN(file_id, '/vid/filenumber/')
filenumber = FIX(H5D_READ(filenumber_id))  ; The FIX function converts double to integer
H5D_CLOSE, filenumber_id

offset_id = H5D_OPEN(file_id, '/vid/offset')  ; The FIX function converts double to long integer (32 bit)
offset = LONG(H5D_READ(offset_id))
H5D_CLOSE, offset_id

; PRINT, offset
; PRINT, filenumber

H5F_CLOSE, file_id



;;;;;FOR i=0,nframes-1 DO BEGIN
 ;;;;; gfilename = STRING(filenumber[i], FORMAT='(I1)') + '.glimpse'
 ;;;;; gfile_path = FILEPATH(gfilename, ROOT_DIR=current_dir)
  ;PRINT, gfile_path
  ;PRINT, gfilename

 ;;;;; image = READ_BINARY(gfile_path, DATA_TYPE=2, DATA_START=offset[i], DATA_DIMS=[width, height], ENDIAN='big')  ; Data type == 12: UINT (16 bit)
  ; Note that the LabVIEW array is row based, and IDL array is column based, so the array is transposed
  ; compared to the original recording
  ;;;;;image = UINT(LONG(image) + 32768)
  ; In order to use LabVIEW's imaq image, the u16 image array was casted to i16, by
  ; casting to i32 first and then subtracting 2^15 then cast to i16
  ; The previous line is the reverse of the process
  ;TV, image  ; But somehow the TV displays the image correctly
;;;;;ENDFOR
;;;;;PRINT, SIZE(image)
;PRINT, image[0, *]



; figure out size + allocate appropriately
; find the file_length
;;;;;header=bytarr(4100)
;;;;;readu,1,header
;;;;;width=fix(header,42)
;;;;;height=fix(header,656)
;;;;;nframes=long(header,1446)
;frame=intarr(width,height)

frame = intarr(width,height) ;512*512 pixels

; load the locations of the peaks

foo = fix(0)
x = float(0)
y = float(0)
b = float(0)
count_good_peak = 0              
good_peak = fltarr(2,10000)
back = fltarr(10000)

;==========Declare background output=======
aback = fltarr(7,7)
;==========Declare background output end===

while EOF(2) ne 1 do begin
	readf, 2, foo, x, y, b
	good_peak(0,count_good_peak) = x
	good_peak(1,count_good_peak) = y
	back(count_good_peak) = b
	count_good_peak = count_good_peak + 1
endwhile

flgd = intarr(2,10000)
flgd(0,*) = floor(good_peak(0,*));peak position無條件捨去
flgd(1,*) = floor(good_peak(1,*))

print, count_good_peak, " peaks were found in file" ;count_good_peak -> number of good peaks
if count_good_peak eq 0 then return
time_tr = intarr(count_good_peak,nframes)
whc_gpk = intarr(count_good_peak,2)
;=====Declare background output=========
back_time = intarr(count_good_peak,1)
;=====Declare background output=========


; calculate which peak to use for each time trace based on
; peak position

for i = 1, count_good_peak - 1 do begin
	whc_gpk(i,0) = round(2.0 * (good_peak(0,i) - flgd(0,i))) ;whc_gpk => which_good_peak，計算真正的peak position與floor position之間的差異
	whc_gpk(i,1) = round(2.0 * (good_peak(1,i) - flgd(1,i)))
endfor

; load the average image
;ave_frame = read_tiff(filename_input + "_ave.tif") ;用不到

; now read values at peak locations into time_tr array

;if (i mod 10) eq 0 then print, "working on : ", i, nframes
;將frame的dimension歸零改回256*256，以正確讀取pma檔
;;;;frame = intarr(width,height)
;;;;;readu, 1, frame ;1 為pma檔
;frame=BYTSCL(frame,MAX=3000,MIN=600)
;讀取後再rebin成512*512

FOR i=0, nframes-1 DO BEGIN
gfilename = STRING(filenumber[i], FORMAT='(I1)') + '.glimpse'
gfile_path = FILEPATH(gfilename, ROOT_DIR=current_dir)

frame = intarr(width,height)
image = READ_BINARY(gfile_path, DATA_TYPE=2, DATA_START=offset[i], DATA_DIMS=[width, height], ENDIAN='big')  ; Data type == 12: UINT (16 bit)
; Note that the LabVIEW array is row based, and IDL array is column based, so the array is transposed
; compared to the original recording
image = UINT(LONG(image)+ 32768)
; In order to use LabVIEW's imaq image, the u16 image array was casted to i16, by
; casting to i32 first and then subtracting 2^15 then cast to i16
; The previous line is the reverse of the process
frame=image
;;;;;ave_arr = ave_arr + frame
;tv, frame
ENDFOR
 
;print, nframes
for i = 0, nframes - 1 do begin
  
	frame = intarr(width,height)
	;if (i mod 10) eq 0 then print, "working on : ", i, nframes
	;將frame的dimension歸零改回256*256，以正確讀取pma檔
	;;;;frame = intarr(width,height)
	;;;;;readu, 1, frame ;1 為pma檔
	;frame=BYTSCL(frame,MAX=3000,MIN=600)
	;讀取後再rebin成512*512

	  image = READ_BINARY(gfile_path, DATA_TYPE=2, DATA_START=offset[i], DATA_DIMS=[width, height], ENDIAN='big')  ; Data type == 12: UINT (16 bit)
	  ; Note that the LabVIEW array is row based, and IDL array is column based, so the array is transposed
	  ; compared to the original recording
	  image = UINT(LONG(image))
	  ;+ 32768
	  ; In order to use LabVIEW's imaq image, the u16 image array was casted to i16, by
	  ; casting to i32 first and then subtracting 2^15 then cast to i16
	  ; The previous line is the reverse of the process
	  frame=image
	  ;;;;;ave_arr = ave_arr + frame
;print, size(frame)

 tv, frame
	for j = 0, count_good_peak - 1 do begin
		apeak = gaussian_peaks(whc_gpk(j,0),whc_gpk(j,1),*,*) * float(frame(flgd(0,j)-3:flgd(0,j)+3,flgd(1,j)-3:flgd(1,j)+3)-back(j)) ;back=>background using aves，用gaussian peaks校正position差異並weight pixel intensity	
		time_tr(j,i) = round(total(apeak)) ;取某peak (7*7 pixels)內所有pixel intensity的和?
   ;print, time_tr(j,i)
	endfor
endfor

    ;print, apeak
    print, size(time_tr)
  ;============calculate background=============
for j=0, count_good_peak - 1 do begin
  aback = gaussian_peaks(whc_gpk(j,0),whc_gpk(j,1),*,*) * float(back(j))    ;"original" background
  back_time(j,0) = round(total(aback))
endfor
;print, size(back_time)

close, 1
close, 2

film_length=nframes

;count_good_peak = count_good_peak
;openw, 1, filename_input + ".traces"
openw, 1,  "hel1.traces"
writeu, 1, film_length
writeu, 1, count_good_peak         ;寫入有多少個trace被記錄。在matlab裡的變數是"Ntraces"
writeu, 1, time_tr
close, 1
print, typename(film_length)
;print, typename(time_tr)
print, film_length 
;print, count_good_peak
;print, time_tr

end
