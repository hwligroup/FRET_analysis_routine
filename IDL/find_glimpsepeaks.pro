pro find_glimpsepeaks, filename_input
  ; load color table
  filename_input=['1']
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
  width = fix(1)
  height = fix(1)
  nframes  = fix(1)

  ;=================================================================

  ;;; input film

  close, 1          ; make sure unit 1 is closed
  cd, CURRENT=current_dir

  ; Read header.mat file using HDF5 functions
  ; The file needs to be v7.3 mat file
  file = FILEPATH('header.mat', ROOT_DIR=current_dir)
  file_id = H5F_OPEN(file)

  nframes_id = H5D_OPEN(file_id, '/vid/nframes')
  nframes = H5D_READ(nframes_id)
  ; index since read data gives array
  nframes = nframes[0]
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


  FOR i=0,nframes-1 DO BEGIN
    gfilename = STRING(filenumber[i], FORMAT='(I1)') + '.glimpse'
    gfile_path = FILEPATH(gfilename, ROOT_DIR=current_dir)
    ;PRINT, gfile_path
    ;PRINT, gfilename

    image = READ_BINARY(gfile_path, DATA_TYPE=2, DATA_START=offset[i], DATA_DIMS=[width, height], ENDIAN='big')  ; Data type == 12: UINT (16 bit)
    ; Note that the LabVIEW array is row based, and IDL array is column based, so the array is transposed
    ; compared to the original recording
    image = UINT(LONG(image))
    ;+ 32768
    ; In order to use LabVIEW's imaq image, the u16 image array was casted to i16, by
    ; casting to i32 first and then subtracting 2^15 then cast to i16
    ; The previous line is the reverse of the process
    ;TV, image  ; But somehow the TV displays the image correctly
  ENDFOR
  PRINT, SIZE(image)
  ;PRINT, image[0, *]

  ;;;;;;end
  ;;;;close, 1  ; make sure unit 1 is closed
  ;;;openr, 1, image


  ; figure out size + allocate appropriately
  ; find the file_length

  ;;;;;;header=bytarr(4100)
  ;;;;;;readu,1,header
  ;;;;;;width=fix(header,42)
  ;;;;;;height=fix(header,656)

  ;;;;;;nframes=long(header,1446)

  ;=================================================================
  frame=intarr(width,height)

  ave_arr = fltarr(width,height)
 ;print, ave_arr
  ;=================================================================
  ; 只取前10個frame 可以自行調整
  if nframes gt 200 then nframes = 10
  PRINT, NFRAMES
  ;=================================================================
  for j = 0, nframes - 1 do begin
    ;if((j mod 5) eq 0) then print, j, nframes
    ;;;;readu, 1, frame
    image = READ_BINARY(gfile_path, DATA_TYPE=2, DATA_START=offset[j], DATA_DIMS=[width, height], ENDIAN='big')  ; Data type == 12: UINT (16 bit)
    ; Note that the LabVIEW array is row based, and IDL array is column based, so the array is transposed
    ; compared to the original recording
    image = UINT(LONG(image))
    ; + 32768
    ; In order to use LabVIEW's imaq image, the u16 image array was casted to i16, by
    ; casting to i32 first and then subtracting 2^15 then cast to i16
    ; The previous line is the reverse of the process
    frame=image
    ave_arr = ave_arr + frame
    tv, frame
  endfor
  ;PRINT, ave_arr
  ;;;;;close, 1
  ;ave_arr = ave_arr/float(nframes - 1)
  ;ave_arr = ave_arr/float(nframes)
  ave_arr = ave_arr/float(nframes)
  ;ave_arr=BYTSCL(ave_arr,MAX=3000,MIN=600)
  ;print, ave_arr
  frame = ave_arr

  ; get background values, aves
  temp1 = frame
  temp1 = smooth(temp1,2,/EDGE_TRUNCATE)
  aves = fltarr(width/16,height/16)
  for i = 8, width, 16 do begin
    for j = 8, height, 16 do begin
      aves((i-8)/16,(j-8)/16) = min(temp1(i-8:i+7,j-8:j+7)) ;Background取local minimum
    endfor
  endfor

  aves = rebin(aves,width,height)
  aves = smooth(aves,20,/EDGE_TRUNCATE)

  frame=BYTSCL(frame)

  temp1 = frame
  temp1 = smooth(temp1,2,/EDGE_TRUNCATE)
  bkg = fltarr(width/16,height/16)
  for i = 8, width, 16 do begin
    for j = 8, height, 16 do begin
      bkg((i-8)/16,(j-8)/16) = min(temp1(i-8:i+7,j-8:j+7)) ;Background取local minimum
    endfor
  endfor

  bkg = rebin(bkg,width,height)
  bkg = smooth(bkg,20,/EDGE_TRUNCATE)

  med = float(median(frame))
  med_left = float(median(frame(0:255,*)))
  med_right = float(median(frame(256:511,*)))

  ; 把 frame 存成 csv 檔案
  ;WRITE_CSV,filename_input + "_frame.csv",frame
  ;WRITE_CSV,filename_input + "_frame_Left.csv",frame(0:255,*)
  ;WRITE_CSV,filename_input + "_frame_Right.csv",frame(256:511,*)

  back_criteria_left = float(STDDEV(frame(0:255,*)))
  back_criteria_right = float(STDDEV(frame(256:511,*)))

  ;WRITE_CSV,filename_input + "_frame_criteria_Left.csv",back_criteria_left
  ;WRITE_CSV,filename_input + "_frame_criteria_Right.csv",back_criteria_right

  ; 左右背景強度不同，設定不同criteria，0:255 是 left， 256:511 是 right (HLY)
  for i = 0, 255 do begin
    for j = 0,511 do begin
      ;if frame(i,j) lt byte(med + 25) then frame(i,j) = 0
      if frame(i,j) lt byte( med_left + 2*back_criteria_left ) then frame(i,j) = 0
    endfor
  endfor

  for i = 256, 511 do begin
    for j = 0, 511 do begin
      ;if frame(i,j) lt byte(med + 25) then frame(i,j) = 0
      if frame(i,j) lt byte( med_right + 2*back_criteria_right  ) then frame(i,j) = 0
    endfor
  endfor


  ;for i = 0, 511 do begin
  ;  for j = 0, 511 do begin
  ;    if frame(i,j) lt byte(med + 25) then frame(i,j) = 0
  ;  endfor
  ;endfor

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
  width=fix(512)
  height=fix(512)
  ;for rebin

  ; subtracts background 前面已經先做完
  ;temp1 = frame
  ;temp1 = smooth(temp1,2,/EDGE_TRUNCATE)
  ;去背
  ;aves = fltarr(width/16,height/11)
  ;for i = 8, width, 16 do begin
  ;    for j = 8, height, 16 do begin
  ;       aves((i-8)/16,(j-8)/16) = min(temp1(i-8:i+7,j-8:j+7))
  ;    endfor
  ; endfor
  ;aves = rebin(aves,width,height)
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
  openr, 1, "F:\WHL(TIRF)\FRET\20200529 2uM hRAD51 73 bp cy3-510 int reprepare trolox low b tube\rough.map" ;

  readf, 1, P
  readf, 1, Q
  close, 1

  ; and map the right half of the screen onto the left half of the screen
  ; 把左半圖和右半圖(經過mapping運算後)疊在一起
  left_image  = temp1(0:(width/2-1),0:(height-1))
  right_image = temp1((width/2):(width-1),0:(height-1))

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
  for i = 0, (width/2-1) do begin
    for j = 0, height - 1 do begin
      if temp2(i,j) lt byte(median_value + std) then temp2(i,j) = 0
    endfor
  endfor

  ; =============================================================

  window, 0, xsize = width, ysize = height
  tv, frame
  window, 1, xsize = (width/2-1), ysize = height
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


  for i = (ceil(0.03*width)), (floor(0.45*width)) do begin
    for j = (round(0.03*height)), (round(0.97*height)) do begin
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
              xf = width/2
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
              ;if int_xf gt round(0.95*width) then begin
              ;  print, "xf", int_xf, "yf", int_yf
              ;  continue
              ;endif
              ;if int_yf gt round(0.95*height) then begin
              ;  print, "yf", int_yf
              ;  continue
              ;endif
              if int_xf gt round(0.99*width) then continue
              if int_yf gt round(0.99*height) then continue
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



  ;window, 0, xsize = width, ysize = height
  ;window, 1, xsize = (width/2-1), ysize = height
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