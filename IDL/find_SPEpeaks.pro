pro find_SPEpeaks, filename_input
; load color table
loadct, 5

COMMON colors, R_ORIG, G_ORIG, B_ORIG, R_CURR, G_CURR, B_CURR

circle = bytarr(11,11)

circle(*,0) = [ 0,0,0,0,0,0,0,0,0,0,0]
circle(*,1) = [ 0,0,0,0,1,1,1,0,0,0,0]
circle(*,2) = [ 0,0,0,1,0,0,0,1,0,0,0]
circle(*,3) = [ 0,0,1,0,0,0,0,0,1,0,0]
circle(*,4) = [ 0,1,0,0,0,0,0,0,0,1,0]
circle(*,5) = [ 0,1,0,0,0,0,0,0,0,1,0]
circle(*,6) = [ 0,1,0,0,0,0,0,0,0,1,0]
circle(*,7) = [ 0,0,1,0,0,0,0,0,1,0,0]
circle(*,8) = [ 0,0,0,1,0,0,0,1,0,0,0]
circle(*,9) = [ 0,0,0,0,1,1,1,0,0,0,0]
circle(*,10)= [ 0,0,0,0,0,0,0,0,0,0,0]

;circle(*,0) = [ 0,0,0,0,0,0,0,0,0,0,0]
;circle(*,1) = [ 0,0,0,0,0,0,0,0,0,0,0]
;circle(*,2) = [ 0,0,0,0,1,1,1,0,0,0,0]
;circle(*,3) = [ 0,0,0,1,0,0,0,1,0,0,0]
;circle(*,4) = [ 0,0,1,0,0,0,0,0,1,0,0]
;circle(*,5) = [ 0,0,1,0,0,0,0,0,1,0,0];
;circle(*,6) = [ 0,0,1,0,0,0,0,0,1,0,0]
;circle(*,7) = [ 0,0,0,1,0,0,0,1,0,0,0]
;circle(*,8) = [ 0,0,0,0,1,1,1,0,0,0,0]
;circle(*,9) = [ 0,0,0,0,0,0,0,0,0,0,0]
;circle(*,10)= [ 0,0,0,0,0,0,0,0,0,0,0]

; generate gaussian peaks
;k,l是製造peak position offset for x, y (mean)
;i,j是x, y
gaussian_peaks = fltarr(3,3,7,7)

for k = 0, 2 do begin
    for l = 0, 2 do begin
       offx = 0.5*float(k-1)
       offy = 0.5*float(l-1)
       for i = 0, 6 do begin
         for j = 0, 6 do begin
          dist = 0.4 * ((float(i)-3.0+offx)^2 + (float(j)-3.0+offy)^2)
          gaussian_peaks(k,l,i,j) = exp(-dist)
         endfor
       endfor
    endfor
endfor

; initialize variables

; fix 無條件捨去
film_width = fix(1)
film_height = fix(1)
number_of_frames  = fix(1)



;;; input film

close, 1          ; make sure unit 1 is closed

openr, 1, filename_input + ".spe"

; figure out size + allocate appropriately
; find the file_length
header=bytarr(4100)
readu,1,header
film_width=fix(header,42)
film_height=fix(header,656)
number_of_frames=long(header,1446)
frame=intarr(film_width,film_height)

ave_arr = fltarr(film_width,film_height)
;=================================================================
; 只取前10個frame 可以自行調整
if number_of_frames gt 10 then number_of_frames = 10
;=================================================================
    for j = 0, number_of_frames - 1 do begin
       ;if((j mod 5) eq 0) then print, j, number_of_frames
       readu, 1, frame
       ave_arr = ave_arr + frame
    endfor
    close, 1
    ;ave_arr = ave_arr/float(number_of_frames - 1)
    ;ave_arr = ave_arr/float(number_of_frames)
    ave_arr = ave_arr/float(number_of_frames)
    ;ave_arr=BYTSCL(ave_arr,MAX=3000,MIN=600)
    frame = ave_arr
    
; get background values, aves
temp1 = frame
temp1 = smooth(temp1,2,/EDGE_TRUNCATE)
aves = fltarr(film_width/16,film_height/16)
for i = 8, film_width, 16 do begin
    for j = 8, film_height, 16 do begin
       aves((i-8)/16,(j-8)/16) = min(temp1(i-8:i+7,j-8:j+7)) ;Background取local minimum
    endfor
 endfor

aves = rebin(aves,film_width,film_height)
aves = smooth(aves,20,/EDGE_TRUNCATE)

frame=BYTSCL(frame)

temp1 = frame
temp1 = smooth(temp1,2,/EDGE_TRUNCATE)
bkg = fltarr(film_width/16,film_height/16)
for i = 8, film_width, 16 do begin
  for j = 8, film_height, 16 do begin
    bkg((i-8)/16,(j-8)/16) = min(temp1(i-8:i+7,j-8:j+7)) ;Background取local minimum
  endfor
endfor

bkg = rebin(bkg,film_width,film_height)
bkg = smooth(bkg,20,/EDGE_TRUNCATE)



med=float(median(frame))

for i = 0, 511 do begin
  for j = 0, 511 do begin
    if frame(i,j) lt byte(med + 25) then frame(i,j) = 0 
  endfor
endfor

;--------despeckle----------------------
for i = 1, 510 do begin
  for j=1, 510 do begin
    if frame(i,j) gt 0 then begin
      neighbor_count=fix(0)
      for u = -1, 1  do begin
        for v = -1, 1  do begin
          if (u eq 0) and (v eq 0) then continue
          if frame(i+u, j+v) gt 0 then neighbor_count=neighbor_count+1
        endfor
      endfor
      
      if neighbor_count lt 2 then frame(i,j) = 0 
      
    endif
  endfor
endfor
;---------despeckle---------------------
frame=byte(frame)
    WRITE_TIFF, filename_input + "_ave.tif", frame, 1, RED = R_ORIG, GREEN = G_ORIG, BLUE = B_ORIG
;endelse

;rebin後，所有圖檔應皆為512*512
film_width=fix(512)
film_height=fix(512)
;for rebin

; subtracts background 前面已經先做完
;temp1 = frame
;temp1 = smooth(temp1,2,/EDGE_TRUNCATE)
;去背
;aves = fltarr(film_width/16,film_height/16)
;for i = 8, film_width, 16 do begin
;    for j = 8, film_height, 16 do begin
;       aves((i-8)/16,(j-8)/16) = min(temp1(i-8:i+7,j-8:j+7))
;    endfor
; endfor
;aves = rebin(aves,film_width,film_height)
;aves = smooth(aves,20,/EDGE_TRUNCATE)
;temp1 = frame - (byte(aves) - 10)

temp1=frame ;已去背完

; open file that contains how the channels map onto each other
; P and Q are mapping parameter
P = fltarr(4,4)
Q = fltarr(4,4)
max_location = float(1)

; 開啟polynomial mapping檔
;print, ""
openr, 1, "C:\Users\IDL\TIR DATA\rough.map" ;

readf, 1, P
readf, 1, Q
close, 1

; and map the right half of the screen onto the left half of the screen
; 把左半圖和右半圖(經過mapping運算後)疊在一起
left_image  = temp1(0:(film_width/2-1),0:(film_height-1))
right_image = temp1((film_width/2):(film_width-1),0:(film_height-1))

right_image = POLY_2D(right_image, P, Q, 2) ; P, Q由之前POLYWARP所得
combined_image = (left_image + right_image)
; thresholds the image for peak finding purposes

combined_image=1*combined_image ;調整factor可以調整contrast

temp2 = combined_image
median_value = float(median(combined_image))   ; median中位數
combined_stf=moment(combined_image)
combined_std=sqrt(combined_stf(1))
;print, "Combined_std= ", combined_std
;print, "Median for combined image= ", median_value
std = 25

;如果點小於全部的median_value+2*combined_std則把此點去掉(變成0) thresholding(去掉疊圖後訊號太弱的點)
for i = 0, (film_width/2-1) do begin
    for j = 0, film_height - 1 do begin
       if temp2(i,j) lt byte(median_value + std) then temp2(i,j) = 0
    endfor
endfor

; =============================================================

window, 0, xsize = film_width, ysize = film_height
tv, frame
window, 1, xsize = (film_width/2-1), ysize = film_height
tv, combined_image

; find the peaks

temp3 = frame
temp4 = combined_image

good_peak = fltarr(2,4000)
back = fltarr(4000)
foob = bytarr(7,7)
diff = fltarr(3,3)

count_good_peak = 0

;===========================================
; temp2 左右兩邊疊起來的圖 256*512 經過thresholding
; temp3 平均的圖
; temp4 左右兩邊疊起來的圖


for i = (ceil(0.03*film_width)), (floor(0.40*film_width)) do begin
  for j = (round(0.03*film_height)), (round(0.97*film_height)) do begin
    if temp2(i,j) gt 0 then begin   ; thresholding後有訊號的點才找
      
      ; find the nearest maxima
      
      foob = temp2(i-3:i+3,j-3:j+3) ; foob 圈選一塊7*7的window找點，使此window掃過整張圖 
      max_value = max(foob, max_location)   ;max的意思... foob是要找max的array, max_location是max所在的座標, 因為是7*7所以要做下面的x和y運算
      y = max_location / 7 - 3
      x = max_location mod 7 - 3
      ; === debug ==== 之後再來看0403
      ;print, x, y         ; 如果有人有空請看看x和y在跑的時候會不會有變化(在-3,3之間變化,會不會是看點有沒有drift)
      ; ==============

      ; only analyze peaks in current column,
      ; and not near edge of area analyzed

      ; 如果最大值在中間的話(i,j)是範圍內的最大值, 才繼續做下面的動作
      if x eq 0 then begin
        if y eq 0 then begin
          y = y + j   ; y = j
          x = x + i   ; x = i
          ; check if its a good peak
          ; i.e. surrounding points below 1 stdev
          quality = 1
          
          
          ;===Check 圓邊界intensity===
          for k = -5, 5 do begin
            for l = -5, 5 do begin
              if circle(k+5,l+5) gt 0 then begin ;在圓邊界上的pixel
                if combined_image(x+k,y+l) gt byte(median_value + 0.45 * float(max_value)) then quality = 0         ; quality等於1是peak，等於0(邊界太亮)不是peak
                ;if combined_image(x+k,y+l) gt byte(median_value + 0.85 * float(max_value)) then quality = 0          ;較大的點需要用此行quality check，因為intensity下降的沒這麼快
              endif
            endfor
          endfor
          ;===Check 圓邊界intensity===
          
          if quality eq 1 then begin
            ; draw where peak was found on screen
            for k = -5, 5 do begin
              for l = -5, 5 do begin
                if circle(k+5,l+5) gt 0 then begin
                  temp3(x+k,y+l) = 90
                  temp4(x+k,y+l) = 90
                endif
              endfor
            endfor
            ; compute difference between peak and gaussian peak
            cur_best = 10000.0
            for k = 0, 2 do begin

              for l = 0, 2 do begin
                diff(k,l) = total(abs((float(max_value) - bkg(x,y)) * gaussian_peaks(k,l,*,*) - (float(temp1(x-3:x+3,y-3:y+3)) - bkg(x,y)))) ;計算何種偏斜的gaussian peak最符合pixels，用來校正peak position
                if diff(k,l) lt cur_best then begin
                  best_x = k
                  best_y = l
                  cur_best = diff(k,l)
                endif
              endfor
            endfor
            flt_x = float(x) - 0.5*float(best_x-1) ;根據剛剛找到最好的gaussian peak校正之position，因此輸出的peak postion不是整數而是以0.5為最小單位。
            flt_y = float(y) - 0.5*float(best_y-1)
            ; calculate and draw location of companion peak
            xf = film_width/2
            yf = 0.0
            for k = 0, 3 do begin
              for l = 0, 3 do begin
                xf = xf + P(k,l) * float(flt_x^l) * float(flt_y^k);map到右邊positions
                yf = yf + Q(k,l) * float(flt_x^l) * float(flt_y^k)
              endfor
            endfor
;======================================
; int_xf and int_yf may out of range
            int_xf = round(xf)
            int_yf = round(yf)
            ;if int_xf gt round(0.95*film_width) then begin
            ;  print, "xf", int_xf, "yf", int_yf
            ;  continue
            ;endif
            ;if int_yf gt round(0.95*film_height) then begin 
            ;  print, "yf", int_yf
            ;  continue
            ;endif
            if int_xf gt round(0.99*film_width) then continue
            if int_yf gt round(0.99*film_height) then continue
;======================================
            for k = -5, 5 do begin
              for l = -5, 5 do begin
                if (circle(k+5,l+5) gt 0) then begin
                  temp3(int_xf+k,int_yf+l) = 90
                endif
              endfor
            endfor
            xf = float(round(2.0 * xf)) * 0.5
            yf = float(round(2.0 * yf)) * 0.5
            wset, 0
            tv, temp3
            wset, 1
            tv, temp4
            good_peak(0,count_good_peak) = flt_x
            good_peak(1,count_good_peak) = flt_y
            back(count_good_peak) = aves(x,y)
            count_good_peak = count_good_peak + 1
            good_peak(0,count_good_peak) = xf
            good_peak(1,count_good_peak) = yf
            back(count_good_peak) = aves(int_xf,int_yf)
            count_good_peak = count_good_peak + 1
          endif
        endif
      endif
    endif
  endfor
endfor



;window, 0, xsize = film_width, ysize = film_height
;window, 1, xsize = (film_width/2-1), ysize = film_height
;wset, 0
;tv, temp3
;wset, 1
;tv, temp4

WRITE_TIFF, filename_input + "_selected.tif", temp3, 1, RED = R_ORIG, GREEN = G_ORIG, BLUE = B_ORIG

;print, "there were", count_good_peak, " good peaks"

close, 1
openw, 1, filename_input + ".pks"
for i = 0, count_good_peak - 1 do begin
    printf, 1, i+1, good_peak(0,i),good_peak(1,i),back(i)
endfor

close, 1
end