% construction de produits mensuels Aquarius pour test
% a partir des fichiers Tesselation
% comparaison avec les fichiers plus proche voisin

load('G:\dataSMOS\CATDS\repro_2017\maskdmin_ease2')
Nlat=length(latDGG);
Nlon=length(lonDGG);

% repertoire des fichiers tesselation
dirTess='I:\Aquarius_data\RSS\L3\year3\file_mat\';

% repertoire des fichiers ponderation 1/d2
dirD2='I:\Aquarius_data\RSS\L3\year3\file_mat_2\';

% repertoire des fichiers plus proche voisin
dirNear='I:\Aquarius_data\RSS\L3\year2\file_mat\';

orb='A';
nameaqua=['aqua' orb '_20130701.mat']   % on pose A ou D
% Construction des produits mensuels 2012
SSSmonthTess=nan(Nlon,Nlat,12);
SSSmonthNear=nan(Nlon,Nlat,12);
SSSmonthD2=nan(Nlon,Nlat,12);
for imonth=8:12
    monthc=num2str(imonth)
    if length(monthc)<2; monthc=['0' monthc]; end;
    SSSTess=nan(Nlon,Nlat,31);
    SSSNear=nan(Nlon,Nlat,31);
    SSSD2=nan(Nlon,Nlat,31);
    for iday=1:31
        dayc=num2str(iday);
        if length(dayc)<2; dayc=['0' dayc]; end;
        nameA= nameaqua;
        nameaqua(11:12)=monthc;
        nameaqua(13:14)=dayc;
        if exist([dirTess nameaqua])
            load([dirTess nameaqua])
            SSSTess(:,:,iday)=SSS1;
            load([dirNear nameaqua])
            SSSNear(:,:,iday)=SSS1;
            load([dirD2 nameaqua])
            SSSD2(:,:,iday)=SSS1;
        end
    end
    
    SSSmonthTess(:,:,imonth)=squeeze(nanmean(SSSTess,3));
    SSSmonthNear(:,:,imonth)=nanmean(SSSNear,3);
    SSSmonthD2(:,:,imonth)=nanmean(SSSD2,3);
    figure; subplot(3,2,1); hold on; title('Tessel'); imagesc(squeeze(SSSmonthTess(:,:,imonth))'); axis tight; caxis([32 38]); colorbar; hold off
    subplot(3,2,2); hold on; title('Neirest'); imagesc(SSSmonthNear(:,:,imonth)'); axis tight; caxis([32 38]); colorbar; hold off
    subplot(3,2,3); hold on; title('d2 weight'); imagesc(SSSmonthD2(:,:,imonth)'); axis tight; caxis([32 38]); colorbar; hold off
    subplot(3,2,4); hold on; title('Tess-d2'); imagesc(squeeze(SSSmonthTess(:,:,imonth))'-SSSmonthD2(:,:,imonth)'); axis tight; caxis([-0.2 0.2]); colorbar; hold off
    subplot(3,2,5); hold on; title('Neirest-d2'); imagesc(squeeze(SSSmonthNear(:,:,imonth))'-SSSmonthD2(:,:,imonth)'); axis tight; caxis([-0.2 0.2]); colorbar; hold off
    subplot(3,2,6); hold on; title('Neirest-Tess'); imagesc(squeeze(SSSmonthNear(:,:,imonth))'-SSSmonthTess(:,:,imonth)'); axis tight; caxis([-0.2 0.2]); colorbar; hold off
    
end




