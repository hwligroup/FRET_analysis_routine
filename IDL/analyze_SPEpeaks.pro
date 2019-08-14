pro analyze_SPEpeaks, filename_input
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

film_width = fix(1)
film_height = fix(1)
film_length  = fix(1)

close, 1				; make sure unit 1 is closed
close, 2


openr, 1, filename_input + ".spe"
openr, 2, filename_input + ".pks"


; figure out size + allocate appropriately
; find the file_length
header=bytarr(4100)
readu,1,header
film_width=fix(header,42)
film_height=fix(header,656)
film_length=long(header,1446)
frame=intarr(film_width,film_height)

frame = intarr(film_width,film_height) ;512*512 pixels

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

;print, count_good_peak, " peaks were found in file" ;count_good_peak -> number of good peaks
if count_good_peak eq 0 then return
time_tr = intarr(count_good_peak,film_length)
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

for i = 0, film_length - 1 do begin
	;if (i mod 10) eq 0 then print, "working on : ", i, film_length
	;將frame的dimension歸零改回256*256，以正確讀取pma檔
	frame = intarr(film_width,film_height)
	readu, 1, frame ;1 為pma檔
	;frame=BYTSCL(frame,MAX=3000,MIN=600)
	;讀取後再rebin成512*512

	for j = 0, count_good_peak - 1 do begin
		apeak = gaussian_peaks(whc_gpk(j,0),whc_gpk(j,1),*,*) * float(frame(flgd(0,j)-3:flgd(0,j)+3,flgd(1,j)-3:flgd(1,j)+3)-back(j)) ;back=>background using aves，用gaussian peaks校正position差異並weight pixel intensity	
		time_tr(j,i) = round(total(apeak)) ;取某peak (7*7 pixels)內所有pixel intensity的和?
	endfor
endfor

  ;============calculate background=============
for j=0, count_good_peak - 1 do begin
  aback = gaussian_peaks(whc_gpk(j,0),whc_gpk(j,1),*,*) * float(back(j))    ;"original" background
  back_time(j,0) = round(total(aback))
endfor


close, 1
close, 2

;count_good_peak = count_good_peak
openw, 1, filename_input + ".traces"
writeu, 1, film_length
writeu, 1, count_good_peak         ;寫入有多少個trace被記錄。在matlab裡的變數是"Ntraces"
writeu, 1, time_tr
close, 1

end