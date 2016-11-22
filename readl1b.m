%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ESA ASIRAS Reader
% J King Environment and Climate Change Canada
% 21/11/2016
% Basic matlab reader for ESA ASIRAS binary files
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear all

%Const
filename='C:\Users\kingj\Documents\Projects\2016-2017\040516_SIRAS\Data\AS3OA03_ASIWL1B040320140325T160941_20140325T164233_0001.DBL';
asiMode = 256; %256 works, documentation seems to suggest its 4096 but this will cause an over-read

fid=fopen(filename,'r','b');  %Open binary file

%Read ASIRAS main product header (MPH), 1247 Byte
hdr.mph = fread(fid,1247,'uint8=>char','ieee-be');  
hdr.mph = reshape(hdr.mph,1,length(hdr.mph));

%Read ASIRAS specific product header (SPH), 1112 Byte
hdr.sph = fread(fid,1112,'uint8=>char','ieee-be');
hdr.sph = reshape(hdr.sph,1,length(hdr.sph));

%Read ASIRAS data set descriptors (DSD), 280 Byte
hdr.dsd = fread(fid,280,'uint8=>char','ieee-be');
hdr.dsd = reshape(hdr.dsd,1,length(hdr.dsd));

dsdSplit  = strsplit(hdr.dsd ,'\n')
cellIdx = find(not(cellfun('isempty', strfind(dsdSplit, 'DS_OFFSET'))));
dataOffset=regexp(dsdSplit(cellIdx),'\d+(\.)?(\d+)?','match')
dataOffset=str2double([dataOffset{:}])

cellIdx = find(not(cellfun('isempty', strfind(dsdSplit, 'NUM_DSR'))));
recordNum = regexp(dsdSplit(cellIdx),'\d+(\.)?(\d+)?','match')
recordNum=str2double([recordNum{:}])

status=fseek(fid,dataOffset,'bof');  %Reposition pointer to data
%Read the ASIRAS measurement dataset (MSD)
h = waitbar(0,'Initializing waitbar...');
for record = 1:recordNum
  perc = round((record/recordNum)*100,1);
  waitbar(perc/100,h,sprintf('%d%% along...',perc))
  
  %Read the time & Orbit group data (TOG), 20 blocks per record
  %84 bytes per block, 1680 per record
  for block = 1:20
    tog(block,record).date=fread(fid,1,'long','ieee-be'); 
    tog(block,record).sec=fread(fid,1,'ulong','ieee-be');  
    tog(block,record).msec=fread(fid,1,'ulong','ieee-be'); 
    tog(block,record).spare1=fread(fid,1,'long','ieee-be'); 
    tog(block,record).spare2=fread(fid,1,'ushort','ieee-be'); 
    tog(block,record).spare3=fread(fid,1,'ushort','ieee-be'); 
    tog(block,record).inst_conf=fread(fid,1,'ulong','ieee-be'); 
    tog(block,record).record=fread(fid,1,'ulong','ieee-be'); 
    tog(block,record).lat=fread(fid,1,'long','ieee-be'); 
    tog(block,record).lon=fread(fid,1,'long','ieee-be'); 
    tog(block,record).arf_height=fread(fid,1,'long','ieee-be'); 
    tog(block,record).alt_rate=fread(fid,1,'long','ieee-be'); 
    tog(block,record).sat_vel=fread(fid,3,'long','ieee-be'); 
    tog(block,record).real_beam=fread(fid,3,'long','ieee-be'); 
    tog(block,record).baseline=fread(fid,3,'long','ieee-be'); 
    tog(block,record).mcd=fread(fid,1,'ulong','ieee-be'); 
  end
  
  %Read the measurement group data (mg), 20 blocks per record
  %94 bytes per block, 1880 per record
  for block = 1:20
    mg(block,record).window_delay = fread(fid,1,'int64','ieee-be');  
    mg(block,record).spare1 =fread(fid,1,'long','ieee-be'); 
    mg(block,record).ocog_width=fread(fid,1,'long','ieee-be'); 
    mg(block,record).r_range =fread(fid,1,'long','ieee-be'); 
    mg(block,record).s_elv =fread(fid,1,'long','ieee-be'); 
    mg(block,record).agc_ch1 =fread(fid,1,'long','ieee-be'); 
    mg(block,record).afc_ch2 =fread(fid,1,'long','ieee-be'); 
    mg(block,record).txrx_gain_ch1 =fread(fid,1,'long','ieee-be'); 
    mg(block,record).txrx_gain_ch2 =fread(fid,1,'long','ieee-be'); 
    mg(block,record).tx_power =fread(fid,1,'long','ieee-be'); 
    mg(block,record).dopp_rc =fread(fid,1,'long','ieee-be'); 
    mg(block,record).inst_rc_corr_txrx =fread(fid,1,'long','ieee-be'); 
    mg(block,record).inst_rc_corr_rx =fread(fid,1,'long','ieee-be'); 
    mg(block,record).spare2 =fread(fid,1,'long','ieee-be'); 
    mg(block,record).spare3 =fread(fid,1,'long','ieee-be'); 
    mg(block,record).interal_pc =fread(fid,1,'long','ieee-be'); 
    mg(block,record).external_pc =fread(fid,1,'long','ieee-be'); 
    mg(block,record).noise_power =fread(fid,1,'long','ieee-be'); 
    mg(block,record).roll =fread(fid,1,'short','ieee-be'); 
    mg(block,record).pitch=fread(fid,1,'short','ieee-be'); 
    mg(block,record).yaw=fread(fid,1,'short','ieee-be'); 
    mg(block,record).spare4=fread(fid,1,'short','ieee-be'); 
    mg(block,record).heading =fread(fid,1,'long','ieee-be'); 
    mg(block,record).roll_sd=fread(fid,1,'ushort','ieee-be'); 
    mg(block,record).pitch_sd=fread(fid,1,'ushort','ieee-be'); 
    mg(block,record).yaw_sd=fread(fid,1,'ushort','ieee-be'); 
  end
 
  %Corrections Group, once per record, should be 0 for all values
  %64 bytes per record
  cg(record).spare = fread(fid,64,'unsigned char','ieee-be'); 

  %CG(record).spare = fread(fid,64,'unsigned char','ieee-be'); 

  %Average pulse-width limited Waveform group, once per record, should be 0 for all values
  %556 bytes per record, changes with asMode  mode!
  awg(record).spare = fread(fid, ((asiMode*2)+44), 'unsigned char', 'ieee-be');
  %AWG(record).spare = fread(fid, (200000), 'unsigned char', 'ieee-be');

  %Multilooked waveform group (MWG), repeated 20 times
  %The ESA documentation lists the first paramter as 4096*2, is it in bits?
  %624 bytes per block, 12480 per block
  for block = 1:20
    mwg(block,record).ml_power_echo=fread(fid,asiMode,'uint16','ieee-be'); % 2 byte
    mwg(block,record).ln_scale_factor=fread(fid,1,'long','ieee-be'); 
    mwg(block,record).power_scale_factor=fread(fid,1,'long','ieee-be'); 
    mwg(block,record).ml_num=fread(fid,1,'uint16','ieee-be'); 
    mwg(block,record).flags=fread(fid,1,'uint16','ieee-be'); 
    mwg(block,record).beam_behaviour = fread(fid,50,'uint16','ieee-be'); 
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Extras
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
plot([mg.s_elv].*10^(-3))
ylim([0 10])


plot(mwg(1500,1).ml_power_echo)

temp = [mwg.ml_power_echo];
plot(temp(1,1:recordNum))
imagesc([temp(1:1:recordNum).ml_power_echo]./maxAmp)




bstart = 1500
bstop = 2000
tog(:,bstart:bstop).lat


scatter([tog(:,bstart:bstop).lon].*10^(-7),[tog(:,bstart:bstop).lat].*10^(-7))

maxAmp = max(max([mwg(:,bstart:bstop).ml_power_echo]))


temp = [mwg(1,1000).ml_power_echo]/[mwg(1,1000).ln_scale_factor]


[mwg(1,1000).ln_scale_factor]

imagesc([mwg.ml_power_echo])

image(10*log10([mwg.ml_power_echo]));
colormap('Gray')
ylim([30 60])


imagesc([mwg(:,bstart:bstop).ml_power_echo]./maxAmp);
colormap('Gray')
ylim([30 60])
xlabel('Record number')
ylabel('Trace number')


y = resample([mwg.ml_power_echo],3,2);

xmin=35
xmax = 60
xrange = xmax-xmin
range = [1:256]*0.1
plot(range(xmin:xmax),mwg(500,1).ml_power_echo(xmin:xmax)./max(mwg(500,1).ml_power_echo(xmin:xmax)))


xlim([0 xrange+5])

scatter([tog.lon].*10^(-7),[tog.lat].*10^(-7))