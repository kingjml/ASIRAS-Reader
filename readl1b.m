%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ESA ASIRAS Reader
% J King Environment and Climate Change Canada
% 21/11/2016
% Basic matlab reader for ESA ASIRAS binary files
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear all
filename='C:\Users\kingj\Documents\Projects\2016-2017\040516_SIRAS\Code\R\ASIRAS\example.DBL';

fid=fopen(filename,'r','b');  %Open binary file
%status=fseek(fid,1112,'bof');  %hop past the basic info

%Read ASIRAS main product header (MPH), 1247 Byte
hdr.mph = fread(fid,1247,'uint8=>char','ieee-be');  
hdr.mph = reshape(hdr.mph,1,length(hdr.mph))

%Read ASIRAS specific product header (SPH), 1112 Byte
hdr.sph = fread(fid,1112,'uint8=>char','ieee-be');
hdr.sph = reshape(hdr.sph,1,length(hdr.sph))

%Read ASIRAS data set descriptors (DSD), 280 Byte
hdr.dsd = fread(fid,280,'uint8=>char','ieee-be');
hdr.dsd = reshape(hdr.dsd,1,length(hdr.dsd))

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
  for block = 1:20
    tog(record,block).date=fread(fid,1,'long','ieee-be');  
    tog(record,block).sec=fread(fid,1,'ulong','ieee-be');  
    tog(record,block).msec=fread(fid,1,'ulong','ieee-be'); 
    tog(record,block).spare1=fread(fid,1,'long','ieee-be'); 
    tog(record,block).spare2=fread(fid,1,'ushort','ieee-be'); 
    tog(record,block).spare3=fread(fid,1,'ushort','ieee-be'); 
    tog(record,block).inst_conf=fread(fid,1,'ulong','ieee-be'); 
    tog(record,block).record=fread(fid,1,'ulong','ieee-be'); 
    tog(record,block).lat=fread(fid,1,'long','ieee-be'); 
    tog(record,block).lon=fread(fid,1,'long','ieee-be'); 
    tog(record,block).arf_height=fread(fid,1,'long','ieee-be'); 
    tog(record,block).alt_rate=fread(fid,1,'long','ieee-be'); 
    tog(record,block).sat_vel=fread(fid,3,'long','ieee-be'); 
    tog(record,block).real_beam=fread(fid,3,'long','ieee-be'); 
    tog(record,block).baseline=fread(fid,3,'long','ieee-be'); 
    tog(record,block).mcd=fread(fid,1,'ulong','ieee-be'); 
  end

  %Read the measurement group data (mg), 20 blocks per record
  for block = 1:20
    mg(record,block).window_delay = fread(fid,1,'int64','ieee-be');  
    mg(record,block).spare1 =fread(fid,1,'long','ieee-be'); 
    mg(record,block).ocog_width=fread(fid,1,'long','ieee-be'); 
    mg(record,block).r_range =fread(fid,1,'long','ieee-be'); 
    mg(record,block).s_elv =fread(fid,1,'long','ieee-be'); 
    mg(record,block).agc_ch1 =fread(fid,1,'long','ieee-be'); 
    mg(record,block).afc_ch2 =fread(fid,1,'long','ieee-be'); 
    mg(record,block).txrx_gain_ch1 =fread(fid,1,'long','ieee-be'); 
    mg(record,block).txrx_gain_ch2 =fread(fid,1,'long','ieee-be'); 
    mg(record,block).tx_power =fread(fid,1,'long','ieee-be'); 
    mg(record,block).dopp_rc =fread(fid,1,'long','ieee-be'); 
    mg(record,block).inst_rc_corr_txrx =fread(fid,1,'long','ieee-be'); 
    mg(record,block).inst_rc_corr_rx =fread(fid,1,'long','ieee-be'); 
    mg(record,block).spare2 =fread(fid,1,'long','ieee-be'); 
    mg(record,block).spare3 =fread(fid,1,'long','ieee-be'); 
    mg(record,block).interal_pc =fread(fid,1,'long','ieee-be'); 
    mg(record,block).external_pc =fread(fid,1,'long','ieee-be'); 
    mg(record,block).noise_power =fread(fid,1,'long','ieee-be'); 
    mg(record,block).roll =fread(fid,1,'short','ieee-be'); 
    mg(record,block).pitch=fread(fid,1,'short','ieee-be'); 
    mg(record,block).yaw=fread(fid,1,'short','ieee-be'); 
    mg(record,block).spare4=fread(fid,1,'short','ieee-be'); 
    mg(record,block).heading =fread(fid,1,'long','ieee-be'); 
    mg(record,block).roll_sd=fread(fid,1,'ushort','ieee-be'); 
    mg(record,block).pitch_sd=fread(fid,1,'ushort','ieee-be'); 
    mg(record,block).yaw_sd=fread(fid,1,'ushort','ieee-be'); 
  end
 
  %Corrections Group, once per record, should be 0 for all values
  CG(record).spare = fread(fid,64,'unsigned char','ieee-be'); 

  %Average pulse-width limited Waveform group, once per record, should be 0 for all values
  AWG(record).spare = fread(fid, 556, 'unsigned char', 'ieee-be');

  %Multilooked waveform group (MWG), repeated 20 times
  %The ESA documentation lists the size in bits, not bytes!!
  for block = 1:20
    mwg(record,block).ml_power_echo=fread(fid,256,'uint16','ieee-be'); 
    mwg(record,block).ln_scale_factor=fread(fid,1,'long','ieee-be'); 
    mwg(record,block).power_scale_factor=fread(fid,1,'long','ieee-be'); 
    mwg(record,block).ml_num=fread(fid,1,'uint16','ieee-be'); 
    mwg(record,block).flags=fread(fid,1,'uint16','ieee-be'); 
    mwg(record,block).beam_behaviour = fread(fid,50,'uint16','ieee-be'); 
  end
end

long(gj_asi_mode*2L+4L+4L+2L+2L+gj_asi_mode*2L+gj_asi_mode*4L+gj_asi_BeamBehaviourParams*2L)

2160-(100+4+4+2+2)


44+gj_asi_mode*2



  j_av_echo_sarin_len=6*4+8+((4*gj_asi_mode)*2)+4+4+2+2

