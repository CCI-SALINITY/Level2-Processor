

nameNC='ESACCI-SEASURFACESALINITY-L2P-SSS-SMOS_A_DAILY_25km-20100222-fv3.0.nc';

infout=ncinfo(nameNC);
% verif
ipl=1;
sss=ncread(nameNC,'sss');
sss_bias=ncread(nameNC,'sss_bias');
sss_random_error=ncread(nameNC,'sss_random_error');
Mean_Acq_Time=ncread(nameNC,'Mean_Acq_Time');
ws=ncread(nameNC,'ws');
sst=ncread(nameNC,'sst');
RR=ncread(nameNC,'rain_rate');

sss_qc=ncread(nameNC,'sss_qc');
lsc_qc=ncread(nameNC,'lsc_qc');
isc_qc=ncread(nameNC,'isc_qc');

figure;
subplot(3,3,1); hold on; title('sss'); imagesc(squeeze(sss(:,:,ipl))'); axis tight; caxis([28 38]); colorbar; hold off
subplot(3,3,2); hold on; title('sss_bias','Interpreter','none'); imagesc(squeeze(sss_bias(:,:,ipl))'); axis tight; caxis([-2 2]); colorbar; hold off
subplot(3,3,3); hold on; title('sss_random_error','Interpreter','none'); imagesc(squeeze(sss_random_error(:,:,ipl))'); axis tight; caxis([0 2]); colorbar; hold off
subplot(3,3,4); hold on; title('Mean_Acq_Time','Interpreter','none'); imagesc(squeeze(Mean_Acq_Time(:,:,ipl))'); axis tight;  colorbar; hold off
subplot(3,3,5); hold on; title('ws'); imagesc(squeeze(ws(:,:,ipl))'); axis tight; caxis([0 15]); colorbar; hold off
subplot(3,3,6); hold on; title('sst'); imagesc(squeeze(sst(:,:,ipl))'); axis tight; caxis([0 35]); colorbar; hold off
subplot(3,3,7); hold on; title('sss_qc','Interpreter','none'); imagesc(squeeze(sss_qc(:,:,ipl))'); axis tight;  caxis([-2 2]); colorbar; hold off
subplot(3,3,8); hold on; title('lsc_qc','Interpreter','none'); imagesc(squeeze(lsc_qc(:,:,ipl))'); axis tight;  caxis([-2 2]); colorbar; hold off
subplot(3,3,9); hold on; title('isc_qc','Interpreter','none'); imagesc(squeeze(isc_qc(:,:,ipl))'); axis tight;  caxis([-2 2]); colorbar; hold off

figure; hold on; title('RR'); imagesc(squeeze(RR(:,:,ipl))'); axis tight; caxis([0 20]); colorbar; hold off
