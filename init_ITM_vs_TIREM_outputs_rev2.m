clear;
clc;
close all;
app=NaN(1);
format shortG

folder1='C:\Local Matlab Data';  %%%%%%%Change this to where you put this matlab file
cd(folder1)
addpath(folder1)
pause(0.1)


tic;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Test to Check ITM/Terrain 
NET.addAssembly(fullfile('C:\USGS', 'SEADLib.dll')); %%%%%%Where the SEADLib.dll is located
itmp=ITMAcs.ITMP2P;


%%%%%%% 1 Equatorial, 2 Continental Subtorpical, 3 Maritime Tropical, 4 Desert, 5 Continental Temperate, 6 Maritime Over Land, 7 Maritime Over Sea
RadioClimate=int32(5);
Refractivity=301;
Dielectric=25.0;
Conductivity=0.02;
ConfPct=.50; %%%%%% 50%  %%%%Confidence Percentage
Polarity=1; %%%%%%1=Vertical, 0=Horizontal
FreqMHz=3500; %%%%%MHz

reliability=[1,2,3,4,5,6,7,8,9,10,15,20,25,30,35,40,45,50,55,60,65,70,75,80,85,90,91,92,93,94,95,96,97,98,99]';  %%%%% 1-99% (This is equivalent to [time] in p452.)
RelPct=reliability/100;  %%%%%Reliability 


TxLat = 43.05;
TxLon = -70.79;
TxHtm = 30;

RxLat =  42.3805;
RxLon = -71.0468;
RxHtm = 6.0;



TerHandler=int32(1); % 0 for GLOBE, 1 for USGS
TerDirectory='C:\USGS\';    %%%%%%%%%Where the terrain data is located
[temp_dBloss, propmodeary, errnumary] =itmp.ITMp2pAryRels(TxHtm,RxHtm,Refractivity,Conductivity,Dielectric,FreqMHz,RadioClimate,Polarity,ConfPct,RelPct,TxLat,TxLon,RxLat,RxLon,TerHandler,TerDirectory);
dBloss=double(temp_dBloss)'; 

horzcat(reliability,dBloss)

rel50_idx=find(reliability==50);
itm_pl_terrain=dBloss(rel50_idx)
propmodeary
errnumary
toc;

prop_mode=double(propmodeary)

 % 0 LOS, 4 Single Horizon, 5 Difraction Double Horizon, 8 Double Horizon, 9 Difraction Single Horizon, 6 Troposcatter Single Horizon, 10 Troposcatter Double Horizon, 333 Error

tic;
FreqHz=3.5e9; %%%%%Hz


%%%%%%%%%%%%%%%%%%%%%%Matlab TIREM and Longly Rice (This uses the Matlab Terrain)
tx = txsite('Name','Tx','Latitude',TxLat,'Longitude',TxLon,'TransmitterFrequency', FreqHz,'AntennaHeight',TxHtm);
rx = rxsite('Name','Rx','Latitude',RxLat,'Longitude',RxLon,'AntennaHeight',RxHtm);

matlab_itm_dB=NaN(length(RelPct),1);
for i=1:1:length(RelPct)
    pm = propagationModel('longley-rice','AntennaPolarization','vertical','TimeVariabilityTolerance',RelPct(i)); %%%%%%1-99% but have to do it individually.
    matlab_itm_dB(i) = pathloss(pm,rx,tx);
end

pm = propagationModel('longley-rice','AntennaPolarization','vertical','TimeVariabilityTolerance',0.50);  %%%%%%%%Just 50%
[itm_pl,itm_info]= pathloss(pm,rx,tx)
itm_info.AngleOfDeparture
itm_info.AngleOfArrival




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Tirem DLL
tiremSetup('C:\USGS\TIREM5')
pm=propagationModel('TIREM','AntennaPolarization','vertical')
[tirem_pl,tirem_info]=pathloss(pm,rx,tx)
tirem_info.AngleOfDeparture
tirem_info.AngleOfArrival


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Terrain Profile with TIREM 5.0
USGS3Secp = TerrainPcs.USGS;
CoordTx = TerrainPcs.Geolocation(TxLat,TxLon);
CoordRx = TerrainPcs.Geolocation(RxLat,RxLon);
USGS3Secp.TerrainDataPath=  "C:\USGS";
Elev=double(USGS3Secp.GetPathElevation(CoordTx,CoordRx,90,true));  %%%%%%%%%This is the "z" equivalent

%%%%%%%Need to then get the distance array --> track2 or just calculate the
%%%%%%%distance and divide by the number of element in Elev
temp_dist_km=deg2km(distance(TxLat,TxLon,RxLat,RxLon));
guess_num_steps=temp_dist_km*1000/90;
length(Elev)
r=linspace(0,temp_dist_km*1000,length(Elev));

%%%%%%%%'Need the terrain profile, If we can do that, we can get the propagation mode out of TIREM.'
z =Elev;
[tirem_pl_terrain,tirem_info_terrain]=tirempl(r,z,FreqHz,'TransmitterAntennaHeight',TxHtm,'ReceiverAntennaHeight',RxHtm)



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
'Check Outputs'
horzcat(itm_pl_terrain,itm_pl,tirem_pl,tirem_pl_terrain)

num2str(horzcat(itm_pl_terrain,itm_pl,tirem_pl,tirem_pl_terrain))























