% script tirh_SPE_MovingAverage Ting-Tzu

% From Ivan's program
% update at Apr. 30, 2014 (Hui-cin)
%   feature: moving average added
%   comments added
%   code not used deleted
%   unnecessary code deleted/modified

% update on Dec. 11, 2015 (Ting-Tzu)
%    plot traces of raw data (donor, acceptor, and total intensity)
%    set the limit of y-axis and add outline of the box on the upper polt

% update on Jan. 8, 2016 (Ting-Tzu)
%    add the function "cutoff time" (cut off the unwanted part, e.g. photobleaching part)
%    not override the .csv files of donor and acceptor 

% update on Apr. 20, 21, 2016 (Ting-Tzu)
%   categorize traces, and save them into different automatically generated folders
%   plot bigger figures

% update on Sep. 11, 2017 (Chih-Hao)
% exchange the position of matrices
%% Preparation
% Clear work space
clear
close all;
fclose('all');
% Input directory path, and default is current directory
path = input('Directory [default= pwd]  ');
if isempty(path)
    path = cd;
%    cd(pwd);
else
    path;
%    cd(path);
end
% Input index of file name
fname = input('Index # of filename [default=1]  ');
if isempty(fname)
    fname = 1;
end
% Input time unit (exposure time of each frame), and default is 0.05 sec
timeunit = input('Time Unit [default=0.05 sec]  ');
if isempty(timeunit)
    timeunit = 0.05;
end
% Input donor leakage correction, and default is zero
leakage = input('Donor leakage correction [default=0]  ');
if isempty(leakage)
    leakage = 0;
end
% Display file information on cmd window for confirmation
disp(['hel',num2str(fname),'.traces'])
disp(['leakage = ',num2str(leakage)])
% Generate folders
mkdir('Cy3 only'); % mkdir: make a new folder called 'xxx' in the current directory
mkdir('Cy5 only');
mkdir('analyzable\significantly analyzable');
mkdir('difficult to categorize');
mkdir('NF and dwell'); % make a folder for the next step analysis
%% Read data from file
% Open file
fid = fopen(['hel',num2str(fname),'.traces'],'r');
% Read data from file
length = fread(fid,1,'int32'); % number of frames (trace length)
Ntraces = fread(fid,1,'int16'); % number of traces
raw = fread(fid,Ntraces*length,'int16'); % raw matrix
% Display file information on cmd window for confirmation
disp(['The length of the time traces is: ',num2str(length)])
disp(['The number of traces is: ',num2str(Ntraces/2)])
disp('Done reading data.');
% Close file
fclose(fid);
%% Process data
% Slice raw matrix into donor and acceptor traces
donor = zeros(Ntraces/2,length);
acceptor = zeros(Ntraces/2,length);
raw = reshape(raw,Ntraces,length);
for i = 1:(Ntraces/2),
    donor(i,:) = raw(i*2,:);  %exchanged
    acceptor(i,:) = raw(i*2-1,:);
end
% Calculate FRET efficiency
fretE = (acceptor-leakage*donor)./(acceptor-leakage*donor+donor); % "()." means each element in the matrix
% Convert number of frames to time span
time = (0:(length-1))*timeunit;
% Construct time-averaged donor, acceptor and FRET traces
lag = 10; % time-averaging window size = 10 frames
avg_donor = zeros(size(donor));
avg_acceptor = zeros(size(acceptor));
avg_fretE = zeros(size(fretE));
for i = 1:(Ntraces/2)
    avg_donor(i,:) = tsmovavg(donor(i,:),'s',lag,2); % calculate time-averaged donor trace
    avg_acceptor(i,:) = tsmovavg(acceptor(i,:),'s',lag,2); % calculate time-averaged acceptor trace
    avg_fretE(i,:) = tsmovavg(fretE(i,:),'s',lag,2); % calculate time-averaged fretE
end

csvwrite(['avg_donor_',num2str(fname),'.csv'], avg_donor);
csvwrite(['avg_acceptor_',num2str(fname),'.csv'], avg_acceptor);
csvwrite(['donor_',num2str(fname),'.csv'], donor);
csvwrite(['acceptor_',num2str(fname),'.csv'], acceptor);

avg_donor(isnan(avg_donor)) = 0; % set NaN = 0
avg_acceptor(isnan(avg_acceptor)) = 0; % set NaN = 0 _ Chia-Chuan
avg_acceptor_minusleakage = avg_acceptor - leakage*avg_donor; % leakage minus matrix _ Chia-Chuan

%% Plot traces
for i = 1:(Ntraces/2)
    % Plot with two panels
    % Upper panel: time-averaged donor, acceptor, and total intensity traces (+ raw traces)
    % Lower panel: time-averaged FRET traces (or raw FRET traces)
 
    % Plot upper panel
    set(gcf,'Units','centimeters','position',[1,1.1,25,25]);  % distance from the left, distance from the bottom; length x width
    subplot(2,1,1);
    hold on  % plot in the same figure
    % Plot trace (raw data)
    % Plot donor trace (raw data)
    %plot(time,donor(i,:), '.', 'Color',[0 1 0]); 
    
    % Plot semitransparent donor trace (raw data)
    %p  = patchline(time,donor(i,:),'linestyle','-','edgecolor','g','linewidth',0.1,'edgealpha',0.15); 
    
    % Plot acceptor trace (raw data)
    %plot(time,acceptor(i,:)-leakage*donor(i,:),'.','Color',[1 0 0]); 
    
    % Plot semitransparent acceptor trace (raw data)
    %p  = patchline(time,acceptor(i,:)-leakage*donor(i,:),'linestyle','-','edgecolor','r','linewidth',0.1,'edgealpha',0.08);
    
    % Plot total intensity trace (raw data)
    %plot(time,donor(i,:)+acceptor(i,:)+5000,'.','Color',[0.8 0.8 0.8]); 
    
    % Plot semitransparent total intensity trace (raw data)
    %p  = patchline(time,donor(i,:)+acceptor(i,:)+5000,'linestyle','-','edgecolor','k','linewidth',0.1,'edgealpha',0.08);
    
    % Plot time-averaged trace    
    % Plot time-averaged donor trace
    plot(time,avg_donor(i,:),'g-'); 
    
    % Plot semitransparent time-averaged donor trace
    %p  = patchline(time,avg_donor(i,:),'linestyle','-','edgecolor','g','linewidth',1);
    
    % Plot time-averaged acceptor trace
    plot(time,avg_acceptor(i,:)-leakage*avg_donor(i,:),'r-');
    
    % Plot semitransparent time-averaged acceptor trace
    %p  = patchline(time,avg_acceptor(i,:)-leakage*avg_donor(i,:),'linestyle','-','edgecolor','r','linewidth',1);
    
    % Plot time-averaged total intensity trace
    plot(time,avg_donor(i,:)+avg_acceptor_minusleakage(i,:)+5000,'k-'); 
    
    % Plot semi-transparent time-averaged total intensity trace
    %p  = patchline(time,avg_donor(i,:)+avg_acceptor_minusleakage(i,:)+5000,'linestyle','-','edgecolor','k','linewidth',1);
    hold off  % turn off the function of "plot in the same figure"
    
    axis on
    ylim([-3000 max(avg_donor(i,:)+avg_acceptor(i,:)+8000)]);% shift y-axis
    title(['hel',num2str(fname),'  Molecule ' num2str(i)]); % add figure title
    set(gcf,'Color',[1 1 1]);
    ylabel('Intensity'); % add y-axis label
    box on; % display axis border
        
    % Add outline of the box on upper panel
    X = xlim;
    Y = ylim;
    % [ Xmin Ymin; Xmax Ymin; Xmax Ymax; Xmin Ymax ]
    v = [X(1)+0.001 Y(1); X(2) Y(1); X(2) Y(2)-100; X(1)+0.001 Y(2)-100];
    f = [1 2 3 4];
    patch('Faces',f,'Vertices',v,'FaceColor','none');
    clear X Y
    
    
    % Plot lower panel
    subplot(2,1,2);
    hold on  % plot in the same figure
    % Plot FRET trace
    %plot(time,fretE(i,:),'k-','Color',[0.8 0.8 0.8]);
    
    % Plot time-averaged FRET trace
    plot(time,avg_fretE(i,:),'b-'); % time-averaged FRET trace
    hold off  % turn off the function of "plot in the same figure"
    
    ylim([-0.1 1.1]);% shift y-axis
    ylabel('FRET efficiency'); % add y-axis label
    xlabel('Time (s)'); % add x-axis label
    box on; % display axis border
        
    % Add outline of the box on bottom panel
    X = xlim;
    Y = ylim;
    % [ Xmin Ymin; Xmax Ymin; Xmax Ymax; Xmin Ymax ]
    v = [X(1)+0.001 Y(1); X(2) Y(1); X(2) Y(2)-0.001; X(1)+0.001 Y(2)-0.001];
    f = [1 2 3 4];
    patch('Faces',f,'Vertices',v,'FaceColor','none');
    
    % Display choice menu: save/process/pass current molecule or exit program
    disp('¡ichoice¡j');
    disp('s = save');
    disp('p = process');
    disp('x = exit program');
    disp('[default = pass current molecule]');
    choice = input('? ','s');
    
    cutoffT = 200;
    switch(choice)
        case 's'
            % Display choice menu: categorize traces into Cy3 only/Cy5only/analyzable/difficult to categorize
            disp('¡icategorization¡j');
            disp('1 = Cy3 only');
            disp('2 = Cy5 only');
            disp('3 = analyzable');
            disp('4 = difficult to categorize');
            disp('[default = save trace to current directory]');
            categorization = input('? ','s');
            
            switch(categorization)
                case'1'
                    newpath = strcat(path,'\Cy3 only'); % construct the string of new path % strcat: concatenate strings horizontally 
                    cd(newpath); % change the current directory to new path
                    
                    saveas(gcf,['hel',num2str(fname),'_molecule_',num2str(i)],'png');
                    close(gcf); % close current figure window
                    csvwrite(['hel',num2str(fname),'_molecule_',num2str(i),'.csv'],[time;avg_fretE(i,:)]);
                    dlmwrite(['hel',num2str(fname),'_molecule_',num2str(i),'.dat'],[time' avg_donor(i,:)' avg_acceptor_minusleakage(i,:)'], 'delimiter', ' ');  % dat. files for HMM analysis_Chia-Chuan
            
                    cd(path); % change the current directory to path
                case'2'
                    newpath = strcat(path,'\Cy5 only'); % construct the string of new path % strcat: concatenate strings horizontally 
                    cd(newpath); % change the current directory to new path
                    
                    saveas(gcf,['hel',num2str(fname),'_molecule_',num2str(i)],'png');
                    close(gcf); % close current figure window
                    csvwrite(['hel',num2str(fname),'_molecule_',num2str(i),'.csv'],[time;avg_fretE(i,:)]);
                    dlmwrite(['hel',num2str(fname),'_molecule_',num2str(i),'.dat'],[time' avg_donor(i,:)' avg_acceptor_minusleakage(i,:)'], 'delimiter', ' ');  % dat. files for HMM analysis_Chia-Chuan
            
                    cd(path); % change the current directory to path                    
                case'3'
                    % Display choice menu: categorize traces into analyzable/significantly analyzable
                    disp('¡icategorization2¡j');
                    disp('a = analyzable');
                    disp('sa = significantly analyzable');
                    disp('[default = save trace to analyzable folder]');
                    categorization2 = input('? ','s');
                    
                    switch(categorization2)
                        case'a'
                            newpath = strcat(path,'\analyzable'); % construct the string of new path % strcat: concatenate strings horizontally 
                            cd(newpath); % change the current directory to new path
                    
                            saveas(gcf,['hel',num2str(fname),'_molecule_',num2str(i)],'png');
                            close(gcf); % close current figure window
                            csvwrite(['hel',num2str(fname),'_molecule_',num2str(i),'.csv'],[time;avg_fretE(i,:)]);
                            dlmwrite(['hel',num2str(fname),'_molecule_',num2str(i),'.dat'],[time' avg_donor(i,:)' avg_acceptor_minusleakage(i,:)'], 'delimiter', ' ');  % dat. files for HMM analysis_Chia-Chuan
            
                            cd(path); % change the current directory to path
                        case'sa'
                            newpath = strcat(path,'\analyzable\significantly analyzable');  % construct the string of new path % strcat: concatenate strings horizontally 
                            cd(newpath);  % change the current directory to new path
                    
                            saveas(gcf,['hel',num2str(fname),'_molecule_',num2str(i)],'png');
                            close(gcf); % close current figure window
                            csvwrite(['hel',num2str(fname),'_molecule_',num2str(i),'.csv'],[time;avg_fretE(i,:)]);
                            dlmwrite(['hel',num2str(fname),'_molecule_',num2str(i),'.dat'],[time' avg_donor(i,:)' avg_acceptor_minusleakage(i,:)'], 'delimiter', ' ');  % dat. files for HMM analysis_Chia-Chuan
            
                            cd(path); % change the current directory to path
                        otherwise
                            newpath = strcat(path,'\analyzable'); % construct the string of new path % strcat: concatenate strings horizontally 
                            cd(newpath); % change the current directory to new path
                    
                            saveas(gcf,['hel',num2str(fname),'_molecule_',num2str(i)],'png');
                            close(gcf); % close current figure window
                            csvwrite(['hel',num2str(fname),'_molecule_',num2str(i),'.csv'],[time;avg_fretE(i,:)]);
                            dlmwrite(['hel',num2str(fname),'_molecule_',num2str(i),'.dat'],[time' avg_donor(i,:)' avg_acceptor_minusleakage(i,:)'], 'delimiter', ' ');  % dat. files for HMM analysis_Chia-Chuan
            
                            cd(path); % change the current directory to path
                    end
                case'4'
                    newpath = strcat(path,'\difficult to categorize'); % construct the string of new path % strcat: concatenate strings horizontally 
                    cd(newpath); % change the current directory to new path
                    
                    saveas(gcf,['hel',num2str(fname),'_molecule_',num2str(i)],'png');
                    close(gcf); % close current figure window
                    csvwrite(['hel',num2str(fname),'_molecule_',num2str(i),'.csv'],[time;avg_fretE(i,:)]);
                    dlmwrite(['hel',num2str(fname),'_molecule_',num2str(i),'.dat'],[time' avg_donor(i,:)' avg_acceptor_minusleakage(i,:)'], 'delimiter', ' ');  % dat. files for HMM analysis_Chia-Chuan
            
                    cd(path); % change the current directory to path                    
                otherwise
                    saveas(gcf,['hel',num2str(fname),'_molecule_',num2str(i)],'png');
                    close(gcf); % close current figure window
                    csvwrite(['hel',num2str(fname),'_molecule_',num2str(i),'.csv'],[time;avg_fretE(i,:)]);
                    dlmwrite(['hel',num2str(fname),'_molecule_',num2str(i),'.dat'],[time' avg_donor(i,:)' avg_acceptor_minusleakage(i,:)'], 'delimiter', ' ');  % dat. files for HMM analysis_Chia-Chuan
            end
        case 'p'            
            while timeunit ~= 0  % a valid condition for while loop
                % display choice menu: save/edit/pass current molecule
                disp('¡ichoice¡j');
                disp('s = save');
                disp('e = edit');
                disp('[default = pass current molecule]'); 
                choice = input('? ','s');

                switch(choice)
                case 's'
                    % Display choice menu: categorize traces into Cy3 only/Cy5only/analyzable/difficult to categorize
                    disp('¡icategorization¡j');
                    disp('1 = Cy3 only');
                    disp('2 = Cy5 only');
                    disp('3 = analyzable');
                    disp('4 = difficult to categorize');
                    disp('[default = save trace to current directory]');
                    categorization = input('? ','s');
            
                    switch(categorization)
                        case'1'
                            newpath = strcat(path,'\Cy3 only'); % construct the string of new path % strcat: concatenate strings horizontally 
                            cd(newpath); % change the current directory to new path
                    
                            saveas(gcf,['hel',num2str(fname),'_molecule_',num2str(i)],'png');
                            close(gcf); % close current figure window
                            csvwrite(['hel',num2str(fname),'_molecule_',num2str(i),'.csv'],[time;avg_fretE(i,:)]);
                            csvwrite(['hel',num2str(fname),'_molecule_',num2str(i),'_cut.csv'],[time(1:(cutoffT/timeunit));avg_fretE(i,1:(cutoffT/timeunit))]);
                            dlmwrite(['hel',num2str(fname),'_molecule_',num2str(i),'_cut.dat'],[time(1:(cutoffT/timeunit))' avg_donor(i,1:(cutoffT/timeunit))' avg_acceptor_minusleakage(i,1:(cutoffT/timeunit))'], 'delimiter', ' ');  % dat. files for HMM analysis_Chia-Chuan            
                            cd(path); % change the current directory to path
                            break % break the while loop (current molecule) and go to the for loop (next molecule)
                        case'2'
                            newpath = strcat(path,'\Cy5 only'); % construct the string of new path % strcat: concatenate strings horizontally 
                            cd(newpath); % change the current directory to new path
                    
                            saveas(gcf,['hel',num2str(fname),'_molecule_',num2str(i)],'png');
                            close(gcf); % close current figure window
                            csvwrite(['hel',num2str(fname),'_molecule_',num2str(i),'.csv'],[time;avg_fretE(i,:)]);
                            csvwrite(['hel',num2str(fname),'_molecule_',num2str(i),'_cut.csv'],[time(1:(cutoffT/timeunit));avg_fretE(i,1:(cutoffT/timeunit))]);
                            dlmwrite(['hel',num2str(fname),'_molecule_',num2str(i),'_cut.dat'],[time(1:(cutoffT/timeunit))' avg_donor(i,1:(cutoffT/timeunit))' avg_acceptor_minusleakage(i,1:(cutoffT/timeunit))'], 'delimiter', ' ');  % dat. files for HMM analysis_Chia-Chuan            
                            cd(path); % change the current directory to path
                            break % break the while loop (current molecule) and go to the for loop (next molecule)
                        case'3'
                            % Display choice menu: categorize traces into analyzable/significantly analyzable
                            disp('¡icategorization2¡j');
                            disp('a = analyzable');
                            disp('sa = significantly analyzable');
                            disp('[default = save trace to analyzable folder]');
                            categorization2 = input('? ','s');
                    
                            switch(categorization2)
                                case'a'
                                    newpath = strcat(path,'\analyzable'); % construct the string of new path % strcat: concatenate strings horizontally 
                                    cd(newpath); % change the current directory to new path
                    
                                    saveas(gcf,['hel',num2str(fname),'_molecule_',num2str(i)],'png');
                                    close(gcf); % close current figure window
                                    csvwrite(['hel',num2str(fname),'_molecule_',num2str(i),'.csv'],[time;avg_fretE(i,:)]);
                                    csvwrite(['hel',num2str(fname),'_molecule_',num2str(i),'_cut.csv'],[time(1:(cutoffT/timeunit));avg_fretE(i,1:(cutoffT/timeunit))]);
                                    dlmwrite(['hel',num2str(fname),'_molecule_',num2str(i),'_cut.dat'],[time(1:(cutoffT/timeunit))' avg_donor(i,1:(cutoffT/timeunit))' avg_acceptor_minusleakage(i,1:(cutoffT/timeunit))'], 'delimiter', ' ');  % dat. files for HMM analysis_Chia-Chuan            
                                    cd(path); % change the current directory to path
                                    break % break the while loop (current molecule) and go to the for loop (next molecule)
                                case'sa'
                                    newpath = strcat(path,'\analyzable\significantly analyzable'); % construct the string of new path % strcat: concatenate strings horizontally 
                                    cd(newpath); % change the current directory to new path
                    
                                    saveas(gcf,['hel',num2str(fname),'_molecule_',num2str(i)],'png');
                                    close(gcf); % close current figure window
                                    csvwrite(['hel',num2str(fname),'_molecule_',num2str(i),'.csv'],[time;avg_fretE(i,:)]);
                                    csvwrite(['hel',num2str(fname),'_molecule_',num2str(i),'_cut.csv'],[time(1:(cutoffT/timeunit));avg_fretE(i,1:(cutoffT/timeunit))]);
                                    dlmwrite(['hel',num2str(fname),'_molecule_',num2str(i),'_cut.dat'],[time(1:(cutoffT/timeunit))' avg_donor(i,1:(cutoffT/timeunit))' avg_acceptor_minusleakage(i,1:(cutoffT/timeunit))'], 'delimiter', ' ');  % dat. files for HMM analysis_Chia-Chuan            
                                    cd(path); % change the current directory to path
                                    break % break the while loop (current molecule) and go to the for loop (next molecule)
                                otherwise
                                    newpath = strcat(path,'\analyzable'); % construct the string of new path % strcat: concatenate strings horizontally 
                                    cd(newpath); % change the current directory to new path
                    
                                    saveas(gcf,['hel',num2str(fname),'_molecule_',num2str(i)],'png');
                                    close(gcf); % close current figure window
                                    csvwrite(['hel',num2str(fname),'_molecule_',num2str(i),'.csv'],[time;avg_fretE(i,:)]);
                                    csvwrite(['hel',num2str(fname),'_molecule_',num2str(i),'_cut.csv'],[time(1:(cutoffT/timeunit));avg_fretE(i,1:(cutoffT/timeunit))]);
                                    dlmwrite(['hel',num2str(fname),'_molecule_',num2str(i),'_cut.dat'],[time(1:(cutoffT/timeunit))' avg_donor(i,1:(cutoffT/timeunit))' avg_acceptor_minusleakage(i,1:(cutoffT/timeunit))'], 'delimiter', ' ');  % dat. files for HMM analysis_Chia-Chuan            
                                    cd(path); % change the current directory to path
                                    break % break the while loop (current molecule) and go to the for loop (next molecule)
                            end
                        case'4'
                            newpath = strcat(path,'\difficult to categorize'); % construct the string of new path % strcat: concatenate strings horizontally 
                            cd(newpath); % change the current directory to new path
                    
                            saveas(gcf,['hel',num2str(fname),'_molecule_',num2str(i)],'png');
                            close(gcf); % close current figure window
                            csvwrite(['hel',num2str(fname),'_molecule_',num2str(i),'.csv'],[time;avg_fretE(i,:)]);
                            csvwrite(['hel',num2str(fname),'_molecule_',num2str(i),'_cut.csv'],[time(1:(cutoffT/timeunit));avg_fretE(i,1:(cutoffT/timeunit))]);
                            dlmwrite(['hel',num2str(fname),'_molecule_',num2str(i),'_cut.dat'],[time(1:(cutoffT/timeunit))' avg_donor(i,1:(cutoffT/timeunit))' avg_acceptor_minusleakage(i,1:(cutoffT/timeunit))'], 'delimiter', ' ');  % dat. files for HMM analysis_Chia-Chuan            
                            cd(path); % change the current directory to path                    
                            break % break the while loop (current molecule) and go to the for loop (next molecule)
                        otherwise
                            saveas(gcf,['hel',num2str(fname),'_molecule_',num2str(i)],'png');
                            close(gcf); % close current figure window
                            csvwrite(['hel',num2str(fname),'_molecule_',num2str(i),'.csv'],[time;avg_fretE(i,:)]);
                            csvwrite(['hel',num2str(fname),'_molecule_',num2str(i),'_cut.csv'],[time(1:(cutoffT/timeunit));avg_fretE(i,1:(cutoffT/timeunit))]);
                            dlmwrite(['hel',num2str(fname),'_molecule_',num2str(i),'_cut.dat'],[time(1:(cutoffT/timeunit))' avg_donor(i,1:(cutoffT/timeunit))' avg_acceptor_minusleakage(i,1:(cutoffT/timeunit))'], 'delimiter', ' ');  % dat. files for HMM analysis_Chia-Chuan
                            break % break the while loop (current molecule) and go to the for loop (next molecule)
                    end
 
                case 'e'
                    cutoffT = input('Cutoff time [default = 200] ');
                    if isempty(cutoffT)
                        cutoffT = 200;
                    end
                    close(gcf); % close current figure window

                    % Plot with three panels
                    % Upper panel: time-averaged donor, acceptor, and total intensity traces (+ raw traces)
                    % Middle panel: time-averaged FRET traces (or raw FRET traces)
                    % Lower panel: cutoff time-averaged FRET traces (or raw FRET traces)
 
                    % Plot upper panel
                    set(gcf,'Units','centimeters','position',[1,1.1,25,25]);  % distance from the left, distance from the bottom; length x width
                    subplot(3,1,1);
                    hold on
                    % Plot trace (raw data)
                    % Plot donor trace (raw data)
                    %plot(time,donor(i,:), '.', 'Color',[0 1 0]); 
    
                    % Plot semitransparent donor trace (raw data)
                    %p  = patchline(time,donor(i,:),'linestyle','-','edgecolor','g','linewidth',0.1,'edgealpha',0.15); 
    
                    % Plot acceptor trace (raw data)
                    %plot(time,acceptor(i,:)-leakage*donor(i,:),'.','Color',[1 0 0]); 
    
                    % Plot semitransparent acceptor trace (raw data)
                    %p  = patchline(time,acceptor(i,:)-leakage*donor(i,:),'linestyle','-','edgecolor','r','linewidth',0.1,'edgealpha',0.08);
    
                    % Plot total intensity trace (raw data)
                    %plot(time,donor(i,:)+acceptor(i,:)+5000,'.','Color',[0.8 0.8 0.8]); 
    
                    % Plot semitransparent total intensity trace (raw data)
                    %p  = patchline(time,donor(i,:)+acceptor(i,:)+5000,'linestyle','-','edgecolor','k','linewidth',0.1,'edgealpha',0.08);
    
                    % Plot time-averaged trace    
                    % Plot time-averaged donor trace
                    plot(time,avg_donor(i,:),'g-'); 
    
                    % Plot semitransparent time-averaged donor trace
                    %p  = patchline(time,avg_donor(i,:),'linestyle','-','edgecolor','g','linewidth',1);
    
                    % Plot time-averaged acceptor trace
                    plot(time,avg_acceptor(i,:)-leakage*avg_donor(i,:),'r-');
    
                    % Plot semitransparent time-averaged acceptor trace
                    %p  = patchline(time,avg_acceptor(i,:)-leakage*avg_donor(i,:),'linestyle','-','edgecolor','r','linewidth',1);
    
                    % Plot time-averaged total intensity trace
                    plot(time,avg_donor(i,:)+avg_acceptor_minusleakage(i,:)+5000,'k-'); 
    
                    % Plot semi-transparent time-averaged total intensity trace
                    %p  = patchline(time,avg_donor(i,:)+avg_acceptor_minusleakage(i,:)+5000,'linestyle','-','edgecolor','k','linewidth',1);   
                    hold off
                    axis on
    
                    ylim([-3000 max(avg_donor(i,:)+avg_acceptor(i,:)+8000)]);% shift y-axis
                    title(['hel',num2str(fname),'  Molecule ' num2str(i)]); % add figure title
                    set(gcf,'Color',[1 1 1]);
                    ylabel('Intensity'); % add y-axis label
                    box on; % display axis border
        
                    % Add outline of the box on upper panel
                    X = xlim;
                    Y = ylim;
                    % [ Xmin Ymin; Xmax Ymin; Xmax Ymax; Xmin Ymax ]
                    v = [X(1)+0.001 Y(1); X(2) Y(1); X(2) Y(2)-100; X(1)+0.001 Y(2)-100];
                    f = [1 2 3 4];
                    patch('Faces',f,'Vertices',v,'FaceColor','none');
                    clear X Y
    
    
                    % Plot middle panel
                    subplot(3,1,2);
                    hold on
                    % Plot FRET trace
                    %plot(time,fretE(i,:),'k-','Color',[0.8 0.8 0.8]);
    
                    % Plot time-averaged FRET trace
                    plot(time,avg_fretE(i,:),'b-');
                    hold off
    
                    ylim([-0.1 1.1]);% shift y-axis
                    ylabel('FRET efficiency'); % add y-axis label
                    xlabel('Time (s)');
                    box on; % display axis border
     
                    % Add outline of a box on middle panel
                    X = xlim;
                    Y = ylim;
                    % [ Xmin Ymin; Xmax Ymin; Xmax Ymax; Xmin Ymax ]
                    v = [X(1)+0.001 Y(1); X(2) Y(1); X(2) Y(2)-0.001; X(1)+0.001 Y(2)-0.001];
                    f = [1 2 3 4];
                    patch('Faces',f,'Vertices',v,'FaceColor','none');                  

    
                    % Plot lower panel
                    subplot(3,1,3);
                    hold on
                    plot( time(1:(cutoffT/timeunit)) , avg_fretE(i,1:(cutoffT/timeunit)) , 'b-');
      
                    hold off
                    ylim([-0.1 1.1]);% shift y-axis
                    ylabel('FRET efficiency'); % add y-axis label
                    xlabel('Time (s)');
                    box on; % display axis border
        
                    % Add outline of the box on lower panel
                    %X = xlim
                    %Y = ylim
                    % [ Xmin Ymin; Xmax Ymin; Xmax Ymax; Xmin Ymax ]
                    v = [X(1)+0.001 Y(1); X(2) Y(1); X(2) Y(2)-0.001; X(1)+0.001 Y(2)-0.001];
                    f = [1 2 3 4];
                    patch('Faces',f,'Vertices',v,'FaceColor','none'); 
    
                otherwise
                    close(gcf); % close current figure window
                    break % break the while loop (current molecule) and return to the for loop (next molecule)
                end
            end
            
        case 'x'
            fclose all;
            close all;
%            clear all;
            return
        otherwise
            close(gcf); % close current figure window
    end
end