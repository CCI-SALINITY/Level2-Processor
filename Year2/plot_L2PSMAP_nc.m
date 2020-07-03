clear all;
close all;

file='/net/nfs/tmp15/chakroun/L2_output/L2P_nc/SMAP/ESACCI-SEASURFACESALINITY-L2P-SSS-SMAP_D_DAILY_25km-20180107-fv2.3.nc';

nc=netcdf.open(file,'nowrite');

lat_ID=netcdf.inqVarID(nc,'lat');
latitude=double(netcdf.getVar(nc,lat_ID));

lon_ID=netcdf.inqVarID(nc,'lon');
longitude=double(netcdf.getVar(nc,lon_ID));

SSSsmos_ID=netcdf.inqVarID(nc,'sss');
SSS=double(netcdf.getVar(nc,SSSsmos_ID));

SSSsmos_ID=netcdf.inqVarID(nc,'sss_random_error');
SSS_randomerror=double(netcdf.getVar(nc,SSSsmos_ID));

SSSsmos_ID=netcdf.inqVarID(nc,'sss_bias');
SSS_bias=double(netcdf.getVar(nc,SSSsmos_ID));

SSSsmos_ID=netcdf.inqVarID(nc,'sss_qc');
SSS_qc=double(netcdf.getVar(nc,SSSsmos_ID));

SSSsmos_ID=netcdf.inqVarID(nc,'lsc_qc');
lsc_qc=double(netcdf.getVar(nc,SSSsmos_ID));

SSSsmos_ID=netcdf.inqVarID(nc,'Mean_Acq_Time');
Mean_Acq_Time=double(netcdf.getVar(nc,SSSsmos_ID));

SSSsmos_ID=netcdf.inqVarID(nc,'isc_qc');
isc_qc=double(netcdf.getVar(nc,SSSsmos_ID));

SSSsmos_ID=netcdf.inqVarID(nc,'sst');
SST=double(netcdf.getVar(nc,SSSsmos_ID));

SSSsmos_ID=netcdf.inqVarID(nc,'ws');
WS=double(netcdf.getVar(nc,SSSsmos_ID));

isc_qc(isc_qc<-100)=nan;
lsc_qc(lsc_qc<-100)=nan;
SSS_qc(SSS_qc<-100)=nan;

load coast;
if true
figure(1)

subplot(2,4,1)
pcolor(longitude,latitude,squeeze(SSS(:,:,1))')
hold on
plot(long,lat)
shading flat
box on
colorbar
caxis([32 38])
set(gca,'Fontsize',14)
title('a. SSS')

subplot(2,4,2)
pcolor(longitude,latitude,squeeze(SSS_qc(:,:,1))')
hold on
plot(long,lat)
shading flat
box on
colorbar
caxis([-1 1])
set(gca,'Fontsize',14)
title('b. SSS qc')

subplot(2,4,3)
pcolor(longitude,latitude,squeeze(SSS_randomerror(:,:,1))')
hold on
plot(long,lat)
shading flat
box on
colorbar
caxis([-1 1])
set(gca,'Fontsize',14)
title('c. SSS random error')

subplot(2,4,4)
pcolor(longitude,latitude,squeeze(SSS_bias(:,:,1))')
hold on
plot(long,lat)
shading flat
box on
colorbar
caxis([-1 1])
set(gca,'Fontsize',14)
title('d. SSS bias')

subplot(2,4,5)
pcolor(longitude,latitude,squeeze(Mean_Acq_Time(:,:,1))')
hold on
plot(long,lat)
shading flat
box on
colorbar
set(gca,'Fontsize',14)
title('e. Mean aquisition time')

subplot(2,4,6)
pcolor(longitude,latitude,squeeze(isc_qc(:,:,1))')
hold on
plot(long,lat)
shading flat
box on
colorbar
caxis([-1 1])
set(gca,'Fontsize',14)
title('f. isc qc')

subplot(2,4,7)
pcolor(longitude,latitude,squeeze(lsc_qc(:,:,1))')
hold on
plot(long,lat)
shading flat
box on
colorbar
caxis([-1 1])
set(gca,'Fontsize',14)
title('g. lsc qc')
end
if true
figure(20)
subplot(2,1,1)
pcolor(longitude,latitude,squeeze(SST(:,:,1))')
hold on
plot(long,lat)
shading flat
box on
colorbar
set(gca,'Fontsize',14)
title('a. SST')

subplot(2,1,2)
pcolor(longitude,latitude,squeeze(WS(:,:,1))')
hold on
plot(long,lat)
shading flat
box on
colorbar
set(gca,'Fontsize',14)
title('b. WS')
end
