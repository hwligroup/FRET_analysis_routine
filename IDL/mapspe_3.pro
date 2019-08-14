device, decompose=0

; load color table
loadct, 5
COMMON colors, R_ORIG, G_ORIG, B_ORIG, R_CURR, G_CURR, B_CURR
dir= "C:\Users\IDL\TIR DATA\"
openr,1, dir + "rough.spe"
header=bytarr(4100)
readu,1,header
film_width=fix(header,42)
film_height=fix(header,656)
number_of_frames=long(header,1446)
frame=intarr(film_width,film_height)
average_frame=fltarr(film_width,film_height)
window, 0, xsize=512, ysize=512
;for j=1,10 do begin
total_frame_num = 500
for j=1,total_frame_num do begin
  readu,1,frame
  showframe=BYTSCL(frame,MAX = mean(frame)+3*stddev(frame),MIN = mean(frame)-2*stddev(frame))
  ;frame=showframe
  tv, showframe
  print, "Reading frame: ", j
  ;wait, 0.1
  average_frame=average_frame + frame
endfor
average_frame = average_frame/total_frame_num
;average_frame=BYTSCL(average_frame,MAX=3000,MIN=500)
average_frame=BYTSCL(average_frame,MAX = mean(average_frame)+6*stddev(average_frame),MIN = mean(average_frame))
frame=average_frame
tvscl,frame
close, 1


med=float(median(frame))





for i = 0, 511 do begin
  for j = 0, 511 do begin
    if frame(i,j) lt byte(med + 20) then frame(i,j) = 0
  endfor
endfor
for i = 1, 510 do begin
  for j = 1, 510 do begin
    if frame(i,j) gt 0 then begin
      neighbor_count=fix(0)
      for u = -1, 1 do begin
        for v = -1, 1 do begin
          if (u eq 0) and (v eq 0) then continue
          if frame(i+u, j+v) gt 0 then neighbor_count=neighbor_count+1
        endfor
      endfor

      if neighbor_count lt 2 then frame(i,j) = 0

    endif
  endfor
endfor
;frame=BYTSCL(frame,MAX=3000,MIN=600)
wset, 0
tv,frame
WRITE_TIFF, dir + "rough_average.tif", frame, 1, RED = R_ORIG, GREEN = G_ORIG, BLUE = B_ORIG
circle = bytarr(11,11)
circle(*,0) = [ 0,0,0,0,1,1,1,0,0,0,0]
circle(*,1) = [ 0,0,1,1,0,0,0,1,1,0,0]
circle(*,2) = [ 0,1,0,0,0,0,0,0,0,1,0]
circle(*,3) = [ 0,1,0,0,0,0,0,0,0,1,0]
circle(*,4) = [ 1,0,0,0,0,0,0,0,0,0,1]
circle(*,5) = [ 1,0,0,0,0,0,0,0,0,0,1]
circle(*,6) = [ 1,0,0,0,0,0,0,0,0,0,1]
circle(*,7) = [ 0,1,0,0,0,0,0,0,0,1,0]
circle(*,8) = [ 0,1,0,0,0,0,0,0,0,1,0]
circle(*,9) = [ 0,0,1,1,0,0,0,1,1,0,0]
circle(*,10)= [ 0,0,0,0,1,1,1,0,0,0,0]

close, 1        ; make sure unit 1 is closed，把1關起來，我們要用
frame = read_tiff(dir + "rough_average.tif")
film_width = fix(512)
film_height = fix(512)

; 使用temp_frame來做為暫時顯示用的畫面，frame則為原始tiff圖片
temp_frame = frame
; 畫一條中央分隔線
for i = 0, (film_width-1) do begin
  temp_frame((film_width/2-1),i) = 240 ;255->intensity最強，白色
  temp_frame((film_width/2),i) = 240
endfor

; create a window, 必為512*512
window, 0, xsize = film_width, ysize = film_height
wset, 0
tv, temp_frame
; first, have user figure out image corresondence
; x_left, y_left are left channel, x_right, y_right are right channel
; 需要3個點來找mapping，所以建立大小為3的array
x_left = fltarr(3)
y_left = fltarr(3)
x_right = fltarr(3)
y_right = fltarr(3)

; 用來控制圈圈上下左右移動的字元
control_key = 'z'

for j = 0, 2 do begin ;找3個點
  wset, 0
  x = fix(1)
  y = fix(1)
  print, " "
  print, "click on spot in left image"
  cursor, x, y, 3, /device
  x_left(j) = x
  y_left(j) = y
  x_right(j) = x_left(j) + 262
  y_right(j) = y_left(j) + 0

  print, "選點盡量形成一大三角形，以涵蓋畫面大部分區塊。若以下按鍵沒反應，請先確定游標已回到主控台閃爍"
  print, "use keyboard to tweak, <s> to stop"
  print, "for left image, use <r>(up), <f>(down), <g>(right), <d>(left)
  print, "for right image, use <i>(up), <k>(down), <l>(right), <j>(left)

  ; 把control_key歸零
  control_key = 'z'
  while control_key ne 's' do begin

    ; temp_frame需要歸零
    temp_frame = frame

    ; show spots the user picked (畫圈圈)
    for k = -5, 5 do begin
      for l = -5, 5 do begin
        if circle(k+5,l+5) gt 0 then begin
          temp_frame(x_left(j)+k,y_left(j)+l) = 90          ;90 => 圈圈用紅色
          temp_frame(x_right(j)+k,y_right(j)+l) = 90
        endif
      endfor
    endfor

    ; 每次找完點須重新畫分隔線
    for i = 0, (film_width-1) do begin
      temp_frame((film_width/2-1),i) = 240 ;255->intensity最強，白色
      temp_frame((film_width/2),i) = 240
    endfor
    wset, 0
    tv, temp_frame

    control_key = get_kbrd(1)
    case control_key of
      'r' : y_left(j) = y_left(j)+1
      'f' : y_left(j) = y_left(j)-1
      'g' : x_left(j) = x_left(j)+1
      'd' : x_left(j) = x_left(j)-1

      'i' : y_right(j) = y_right(j)+1
      'k' : y_right(j) = y_right(j)-1
      'l' : x_right(j) = x_right(j)+1
      'j' : x_right(j) = x_right(j)-1
      else : control_key = control_key
    endcase
  endwhile
  frame = temp_frame
endfor
print, "選點是否正確? 預設為y，重來選n: "
correct="y"
read, correct
if (correct ne "y") and (correct ne "n") then correct="y"


; set up matrices
; 包含剛剛圈選的三點的座標值
left_mat = fltarr(3,3)
left_mat(0,*) = 1.0
left_mat(1,*) = x_left
left_mat(2,*) = y_left

; 計算左半邊座標值矩陣的inverse matrix
inv_mat = invert(left_mat)

; calculate coefficients and save coefficients
; 將inv_mat乘上右半邊座標值矩陣即為transpose matrix，之後將此transpose matrix乘上左半邊座標值矩陣即可得右半邊的座標值矩陣
;openw, 1, dir + "rough.coeff"
;printf, 1, total(inv_mat(*,0) * x_right)
;printf, 1, total(inv_mat(*,1) * x_right)
;printf, 1, total(inv_mat(*,2) * x_right)
;printf, 1, total(inv_mat(*,0) * y_right)
;printf, 1, total(inv_mat(*,1) * y_right)
;printf, 1, total(inv_mat(*,2) * y_right)
;close, 1
trans_x_coeff = fltarr(3)
trans_y_coeff = fltarr(3)

; 以一fltarr儲存coefficients, 不用再儲存到檔案
print, "x_right= "
for j = 0, 2 do begin
  trans_x_coeff(j) = total(inv_mat(*,j) * x_right)
  print, trans_x_coeff(j)
endfor
print, "y_right= "
for j = 0, 2 do begin
  trans_y_coeff(j) = total(inv_mat(*,j) * y_right)
  print, trans_y_coeff(j)
endfor
close, 1        ; make sure unit 1 is closed，把1關起來，我們要用

film_width = fix(512)
film_height = fix(512)

window, 0, xsize = 512, ysize = 512

; 讀取已用maketiff做出來的*_average.tif檔案(假設先前的步驟都已經完成了)，且檔案必然為512*512
frame = read_tiff(dir + "rough_average.tif")
frame_smoothed = frame
temp2 = frame_smoothed
wset, 0
tv, temp2
;---------------------------------------------------------------------------------------------------
; find the peaks

temp3 = frame
temp4 = temp3
wset, 0

; good_peak -> good peak
good_peak = intarr(2,4000)
foob = bytarr(7,7)
count_good_peak = 0
for i = round(0.02*film_width), round(0.98*film_width) do begin
  if i eq (round(0.48*film_width)) then i = round(0.52*film_width)  ; skip region where channels overlap
  for j = round(0.02*film_width), round(0.98*film_width) do begin
    if temp2(i,j) gt 0 then begin

      ; find the nearest maxima

      foob = temp2(i-3:i+3,j-3:j+3)
      max_value = max(foob, max_location)
      y = max_location / 7 - 3       ;peak中心點
      x = max_location mod 7 - 3     ;peak中心點
      ;if j eq 11 then  print, "foo", max_value, foob, x, y

      ; only analyze peaks in current column,
      ; and not near edge of area analyzed

      if x gt -1 and x lt 1 then begin
        if y gt -1 and y lt 1 then begin
          y = y + j
          x = x + i


          ; check if its a good peak
          ; i.e. surrounding points below 1 stdev
          quality = 1
          for k = -5, 5 do begin
            for l = -5, 5 do begin
              if circle(k+5,l+5) gt 0 then begin
                ;if frame_smoothed(x+k,y+l) gt byte(med + 0.25 * float(max_value)) then quality = 0
                if frame_smoothed(x+k,y+l) gt byte(med + 0.65 * float(max_value)) then quality = 0
              endif
            endfor
          endfor

          if quality eq 1 then begin

            ; draw where peak was found on screen

            for k = -5, 5 do begin
              for l = -5, 5 do begin
                if circle(k+5,l+5) gt 0 then begin
                  temp4(x+k,y+l) = 90
                endif
              endfor
            endfor
            wset, 0
            tv, temp4

            good_peak(0,count_good_peak) = x
            good_peak(1,count_good_peak) = y
            count_good_peak = count_good_peak + 1
            temp3 = temp4
          endif
        endif
      endif

      ; for debugging

      ;if count_good_peak gt 10 then begin
      ; i = 514
      ; j = 514
      ;endif

    endif

  endfor
endfor
print, "there were ", count_good_peak, " good peaks"
pxl = fix(1)
pyl = fix(1)
pxr = fix(1)
pyr = fix(1)

; 下面兩個變數沒用到
; diff_x = 254
; diff_y = 1

x_left = intarr(1,1000)
y_left = intarr(1,1000)
x_right = intarr(1,1000)
y_right = intarr(1,1000)

count_pairs = 0

; load coefficients for rough map

trans_x = fltarr(3)
trans_y = fltarr(3)
trans_x=trans_x_coeff
trans_y=trans_y_coeff
for i = 0, count_good_peak - 1 do begin
  if good_peak(0,i) lt (film_width/2) then begin   ; 只找左半邊

    ; calculate location of pair
    ; 將左半邊good peak的座標乘上transpose matrix得到右半邊座標, mapped(xf,yf)
    xf = round(trans_x(0) + trans_x(1)*float(good_peak(0,i)) + trans_x(2)*float(good_peak(1,i))) ; xf = ax + bx * xi + cx * yi
    yf = round(trans_y(0) + trans_y(1)*float(good_peak(0,i)) + trans_y(2)*float(good_peak(1,i))) ; yf = ay + by * xi + cy * yi
    for j = i + 1, count_good_peak - 1 do begin         ; 暴力去找每一個找過的peak
      if abs(good_peak(0,j) - xf) lt 3 then begin   ; x, y的誤差在正負3之內都算有pair到
        if abs(good_peak(1,j) - yf) lt 3 then begin

          ; temp4 = temp3

          ; circle the two peaks

          for k = -5, 5 do begin
            for l = -5, 5 do begin
              if circle(k+5,l+5) gt 0 then begin
                temp4(good_peak(0,i)+k,good_peak(1,i)+l) = 240
                temp4(good_peak(0,j)+k,good_peak(1,j)+l) = 240
              endif
            endfor
          endfor
          wset, 0
          tv, temp4

          x_left(count_pairs) = good_peak(0,i)
          y_left(count_pairs) = good_peak(1,i)
          x_right(count_pairs) = good_peak(0,j) - (film_width/2) ;先將右半邊點座標平移至左邊，供後面POLYWARP進行變形疊圖
          y_right(count_pairs) = good_peak(1,j)
          count_pairs = count_pairs + 1

        endif
      endif
    endfor
  endif
endfor

if count_pairs gt 16 then begin ;POLYWARP需要16組點，以解出16組coefficients

  print, "found ", count_pairs, " pairs"

  nlines = FILE_LINES(dir+'location.dat')
  sarr = intarr(nlines/4,4)
  print,'location line =' ,nlines
  OPENR, 10, dir+'location.dat'
  READF, 10, sarr
  PRINT, sarr

  x_right_pre = intarr(1,nlines/4)
  y_right_pre = intarr(1,nlines/4)
  x_left_pre = intarr(1,nlines/4)
  y_left_pre = intarr(1,nlines/4)

  x_right_pre(0:nlines/4 - 1) = sarr(*,0)
  y_right_pre(0:nlines/4 - 1) = sarr(*,1)
  x_left_pre(0:nlines/4 - 1) = sarr(*,2)
  y_left_pre(0:nlines/4 - 1) = sarr(*,3)


  ;把資訊存到一個 (count_pairs,4)矩陣裡
  location = intarr(count_pairs + (nlines/4),4)
  location(*,0) = [x_right(0:count_pairs -1),TRANSPOSE(x_right_pre)]
  location(*,1) = [y_right(0:count_pairs -1),TRANSPOSE(y_right_pre)]
  location(*,2) = [x_left(0:count_pairs -1),TRANSPOSE(x_left_pre)]
  location(*,3) = [y_left(0:count_pairs -1),TRANSPOSE(y_left_pre)]

  print,'x_right =', location(*,0)
  print,'y_right =', location(*,1)
  print,'x_left =', location(*,2)
  print,'y_left =', location(*,3)
  
  close, 10

  openw, 1, dir + "location.dat"

  for i = 0, 4*(count_pairs + nlines/4) -1 do begin
    printf, 1, location(i)
  endfor
  close, 1

  ;print, "x_right= ", x_right
  ;print, "y_right= ", y_right

  ; POLYWARP, x_right, y_right, x_left, y_left, 3, P, Q
  POLYWARP, location(*,0), location(*,1), location(*,2), location(*,3), 3, P, Q
  ; P, Q為利用POLYWARP所得之transpose matrix (coefficient)，皆為3x3矩陣

  openw, 1, dir + "rough.map"

  for i = 0, 15 do begin
    printf, 1, P(i)
  endfor
  for i = 0, 15 do begin
    printf, 1, Q(i)
  endfor
  close, 1

  print, "P= ", P
  print, "Q= ", Q
  print, "New 3rd-order polynomial coefficients are saved"
  print, " "
endif else begin
  print, "Not enough matches"
  return
endelse
end