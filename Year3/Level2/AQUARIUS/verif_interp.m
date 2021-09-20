% lecture des nouveaux produits Aquarius (L3 daily orbites A et D séparées)
% verification des interpolations
% generation des figures pour le rapport de validation et l'ATBD

clear

set(groot,'DefaultFigureColormap',jet)

load('G:\dataSMOS\CATDS\repro_2017\isas_CATDS_2010_2020');
load('G:\dataSMOS\CATDS\repro_2017\maskdmin_ease2')
% pp calculé pour d/1000. Valable pour des distances < 3000 km
pp=[0.010110049201987, -0.132977635067397, 0.675117460128751, -1.665973909651722, 2.080693659666045,  -1.275049681173220, 1.359776367468559];
NN=6;
ind1=find(dmin>2000);
dmin1=dmin/1000;
fact_dist=0.*dmin1;
for ipp=1:NN
    fact_dist=fact_dist+pp(ipp)*dmin1.^(NN+1-ipp);
end
fact_dist=fact_dist+pp(NN+1);
fact_dist(ind1)=1;
indf=find(fact_dist<1);
fact_dist(indf)=1;

[lat0, lon0]=meshgrid(lat_fixgrid,lon_fixgrid);
    lonaqua=-179.5:1:179.5;
    lataqua=-89.5:1:89.5;
    % on elargit pour l'interpolation
    lonaqua2=-180.5:1:180.5;
    [lataqua0 lonaqua0]=meshgrid(lataqua,lonaqua2);
    lataqua0=reshape(lataqua0,size(lataqua0,1)*size(lataqua0,2),1);
    lonaqua0=reshape(lonaqua0,size(lonaqua0,1)*size(lonaqua0,2),1);


for iorb=1:2
    
    if iorb==1; orb='A'; else; orb='D'; end;
    
    
    dirinput=['I:\Aquarius_data\RSS\L3\Aquarius_daily\SCI' orb '\'];
    
    dirin=['I:\Aquarius_data\RSS\L3\Aquarius_daily\SCI'  orb '\']
    
    dirdataaqua='I:\Aquarius_data\RSS\L3\year3\file_mat\';
    nameaqua=['aqua' orb '_20100701.mat']   % on pose A ou D
    
    for iy=1:5
        yearc=num2str(2010+iy)
        tt0=datenum(2010+iy,1,1,0,0,0);
        for iday=1:365
            tt1=tt0+iday-0.5;
            
            dvec=datevec(tt1);
            
            dayc=num2str(iday);
            while length(dayc)<3; dayc=['0' dayc]; end;
            
            namepath= [dirinput yearc filesep dayc];
            namepathin= [dirin];
            dirrep=dir(namepath);
            
            yearc=num2str(dvec(1));
            monc=num2str(dvec(2));
            if length(monc)<2; monc=['0' monc]; end;
            dayc=num2str(dvec(3));
            if length(dayc)<2; dayc=['0' dayc]; end;
            
            name_res=nameaqua;
            name_res(7:10)=yearc;
            name_res(11:12)=monc;
            name_res(13:14)=dayc;
            
            indisas=find(datemois_isas(:,2)==dvec(1)-2000 & datemois_isas(:,1)==dvec(2));
            SST1=squeeze(isasTEMP(indisas,:,:));
            
            for ii=3:length(dirrep)
                chainok='0_SSS_1deg.bz2';
                if strcmp(dirrep(ii).name(end-13:end),chainok)
                    filepath=[namepath filesep dirrep(ii).name];
                    
                    filepathin=[namepathin dirrep(ii).name];
                    copyfile(filepath,namepathin)
                    
                    delete(['Q*.*'])
                    
                    [status,result] = system(['"C:\Program Files\7-Zip\7z.exe" e ' filepathin]);
                    % on supprime les bz2
                    delete([namepathin '*.bz2'])
                    
                    % INFO = h5info(dirrep(ii).name(1:end-4))
                    jdmoy=tt1;
                    % on lit les SSS
                    %  if exist(filepathin(1:end-4))
                    
                    sss=h5read(dirrep(ii).name(1:end-4),'/l3m_data');
                    sss=sss(:,end:-1:1);  % lat dans le mauvais sens
                    SSSinit=sss;  % SSS native sur la grille native lonaqua, lataqua
                    
                    [px,py] = gradient(sss);
                    gg=px.*px+py.*py;
                    gg=gg./gg;  % masque si gg=0 (pas de gradients) alors NaN, sinon =1
                    % on remplace les fill values par des NaN
                    ind=find(sss<0);
                    sss(ind)=NaN;
                    
                    % on bouche les trous les plus évidents
                    sssb=sss; k=0;
                    for ilo=2:(length(lonaqua)-1)
                        for ila=2:(length(lataqua)-1)
                            if gg(ilo,ila)==1 & isnan(sss(ilo,ila))
                                k=k+1;
                                ssssel=sss(ilo-1:ilo+1,ila-1:ila+1);
                                indok=find(isnan(ssssel)==0);
                                if length(indok)>=5
                                    sssb(ilo,ila)=mean([ssssel(indok)]);
                                end
                                %  keyboard
                            end
                        end
                    end
                    
                    SSSsanstrou=sssb;   % SSS où on a bouche les trous sur la grille native lonaqua, lataqua
                    
                    % trous bouches
                    sss1=zeros(362,180);
                    sss1(2:end-1,:)=sssb;
                    sss1(1,:)=sssb(end,:);
                    sss1(end,:)=sssb(1,:);
                    
                    % trous non bouches
                    sss2=zeros(362,180);
                    sss2(2:end-1,:)=sss;
                    sss2(1,:)=sss(end,:);
                    sss2(end,:)=sss(1,:);
                    
                    SSS1=interp2(lonaqua2,lataqua,sss1',lon0,lat0,'nearest');  % trous bouches
                    SSS2=interp2(lonaqua2,lataqua,sss2',lon0,lat0,'nearest');  % trous
                    SSS1p=interp2(lonaqua2,lataqua,sss1',lon0,lat0,'linear');  % trous bouches
                    SSS2p=interp2(lonaqua2,lataqua,sss2',lon0,lat0,'linear');  % trous
                    masq=SSS1./SSS1;
                    
                    SSSsanstrou_nearest=SSS1;  % SSS interpolee sur EASE plus proche voisin avec bouche trous
                    SSSavectrou_nearest=SSS2;  % SSS interpolee sur EASE plus proche voisin avec trous
                    SSSsanstrou_linear=SSS1p;  % SSS interpolee bilineaire sur EASE avec bouche trous
                    SSSavectrou_linear=SSS2p;  % SSS interpolee bilineaire sur EASE avec trous
                    
                    figure
                    subplot(2,1,1); hold on; title(['SSS  orb ' orb ', native grid'])
                    imagesc(lonaqua,lataqua,SSSinit'); axis tight; caxis([32 38]); colorbar; hold off;
                    subplot(2,1,2); hold on; title(['SSS  orb ' orb ', native grid'])
                    imagesc(lonaqua,lataqua,SSSinit'); axis([-140 -130 -46 -30]); caxis([34.4 36.5]); colorbar; hold off;
                    
                    figure
                    subplot(2,2,1); hold on; title(['EASE SSS Aqua orb ' orb ', nearest']);
                    imagesc(lon_fixgrid,lat_fixgrid,SSSavectrou_nearest'); axis tight; caxis([32 38]); colorbar; hold off;
                    subplot(2,2,3); hold on; title(['zoom']);
                    imagesc(lon_fixgrid,lat_fixgrid,SSSavectrou_nearest'); axis([-140 -130 -46 -30]); caxis([34.4 36.5]); colorbar;
                    grid on; hold off
                    subplot(2,2,2); hold on; title('with completion');
                    imagesc(lon_fixgrid,lat_fixgrid,SSSsanstrou_nearest'); axis tight; caxis([32 38]); colorbar;
                    hold off
                    subplot(2,2,4); hold on; title(['zoom']);
                    imagesc(lon_fixgrid,lat_fixgrid,SSSsanstrou_nearest'); axis([-140 -130 -46 -30]); caxis([34.4 36.5]); colorbar;
                    grid on; hold off
                    
                    saveas(gcf,'nearest','png')
                    
                    figure
                    subplot(2,2,1); hold on; title(['EASE SSS Aqua orb ' orb ', linear']);
                    imagesc(lon_fixgrid,lat_fixgrid,SSSavectrou_linear'); axis tight; caxis([32 38]); colorbar; hold off;
                    subplot(2,2,3); hold on; title(['zoom']);
                    imagesc(lon_fixgrid,lat_fixgrid,SSSavectrou_linear'); axis([-140 -130 -46 -30]); caxis([34.4 36.5]); colorbar;
                    grid on; hold off
                    subplot(2,2,2); hold on; title('with completion');
                    imagesc(lon_fixgrid,lat_fixgrid,SSSsanstrou_linear'); axis tight; caxis([32 38]); colorbar;
                    hold off
                    subplot(2,2,4); hold on; title(['zoom']);
                    imagesc(lon_fixgrid,lat_fixgrid,SSSsanstrou_linear'); axis([-140 -130 -46 -30]); caxis([34.4 36.5]); colorbar;
                    grid on; hold off
                    hold off
                    
                    saveas(gcf,'linear','png')
                    
                    % tesselation sans bouche trou
                    lataqua1=lataqua0;
                    lonaqua1=lonaqua0;
                    sss0=reshape(sss2,size(sss2,1)*size(sss2,2),1);
                    F = scatteredInterpolant(lonaqua1,lataqua1,sss0);
                    SSSavectrou_tessel=F(lon0,lat0);
                    
                    % tesselation avec bouche trou
                    sss0=reshape(sss1,size(sss1,1)*size(sss1,2),1);
                    F = scatteredInterpolant(lonaqua1,lataqua1,sss0);
                    SSSsanstrou_tessel=F(lon0,lat0);
                    
                    % TESSELATION
                    figure
                    subplot(2,2,1); hold on; title(['EASE SSS Aqua orb ' orb ', tessel']);
                    imagesc(lon_fixgrid,lat_fixgrid,SSSavectrou_tessel'); axis tight; caxis([32 38]); colorbar; hold off;
                    subplot(2,2,3); hold on; title(['zoom']);
                    imagesc(lon_fixgrid,lat_fixgrid,SSSavectrou_tessel'); axis([-140 -130 -46 -30]); caxis([34.4 36.5]); colorbar;
                    grid on; hold off
                    subplot(2,2,2); hold on; title('with completion');
                    imagesc(lon_fixgrid,lat_fixgrid,SSSsanstrou_tessel'); axis tight; caxis([32 38]); colorbar;
                    hold off
                    subplot(2,2,4); hold on; title(['zoom']);
                    imagesc(lon_fixgrid,lat_fixgrid,SSSsanstrou_tessel'); axis([-140 -130 -46 -30]); caxis([34.4 36.5]); colorbar;
                    grid on; hold off
                    
                    saveas(gcf,'tesselation','png')
                    
                    % TESSEL -LINEAR
                    figure
                    subplot(2,1,1); hold on; title('tessel - linear with completion');
                    imagesc(lon_fixgrid,lat_fixgrid,SSSsanstrou_tessel'-SSSsanstrou_linear'); axis tight; caxis([-0.25 0.25]); colorbar;
                    hold off
                    subplot(2,1,2); hold on; title(['zoom']);
                    imagesc(lon_fixgrid,lat_fixgrid,SSSsanstrou_tessel'-SSSsanstrou_linear'); axis([-140 -130 -46 -30]); caxis([-0.25 0.25]); colorbar;
                    grid on; hold off
                    
                    saveas(gcf,'comp_tesselation_linear','png')
                    
                    % interpolation weight 1/d2
                    load('gridAquaNearest','indlatAqua','indlonAqua','dlonlatkm');  % les 4 plus proches voisins Aqua de la grille EASE (grille Aqua etendue lon2)

                                        
                    % On cherche les points EASE qui sont entourés d'au
                    % moins 1 SSS parmi les 4 voisins Aqua sur la grille
                    % elargie
                    SSS1=nan(length(lonDGG),length(latDGG));
                    for ilat=1:length(latDGG)
                        SSSaq=sss1(:,indlatAqua(ilat,:));
                        for ilon=1:length(lonDGG)
                            SSSsel=SSSaq(indlonAqua(ilon,:),:);
                            ind=find(SSSsel>0);
%                             if length(ind)==1
%                                 SSS1(ilon,ilat)=SSSsel(ind);
                            if length(ind)>1
                                dist=dlonlatkm(ilon,ilat,:,:);
                                dist2sel=1./(dist(ind).*dist(ind));  % ponderation par l'inverse de la distance au carre
                                sdis=sum(dist2sel);
                                SSS1(ilon,ilat)=(SSSsel(ind)'*dist2sel)/sdis;
                            else
                                SSS1(ilon,ilat)=NaN;
                            end
                        end
                    end

                     % 1/d2
                    figure
                    subplot(2,2,1); hold on; title(['EASE SSS Aqua orb ' orb ', 1/d2']);
                    imagesc(lon_fixgrid,lat_fixgrid,SSS1'); axis tight; caxis([32 38]); colorbar; hold off;
                    subplot(2,2,2); hold on; title(['EASE SSS Aqua orb ' orb ', 1/d2']);
                    imagesc(lon_fixgrid,lat_fixgrid,SSS1'); axis tight; caxis([32 38]); colorbar; hold off;
                    subplot(2,2,3); hold on; title(['zoom']);
                    imagesc(lon_fixgrid,lat_fixgrid,SSS1'); axis([-140 -130 -46 -30]); caxis([34.4 36.5]); colorbar;
                    grid on; hold off
                    subplot(2,2,4); hold on; title(['zoom']);
                    imagesc(lon_fixgrid,lat_fixgrid,SSS1'); axis([-140 -130 -46 -30]); caxis([34.4 36.5]); colorbar;
                    grid on; hold off
                    
                    saveas(gcf,'d2_2','png')
                    
                   
                    keyboard

                    
                    
                    
                    indnonnan=find(~isnan(sss1));
                    lataqua1=lataqua0(indnonnan);
                    lonaqua1=lonaqua0(indnonnan);
                    sss0=sss1(indnonnan);
                    F = scatteredInterpolant(lonaqua1,lataqua1,sss0);
                    sssinter=F(lon0,lat0);
                    
                    tSSS1=SSS1.*0+jdmoy;
                    
                    SSS1=SSS1;
                    tSSS1=tSSS1;
                    eSSS1=0.*SSS1;
                    % formule empirique
                    mask=SSS1./SSS1;
                    % eSSS1=0.17./(0.03.*SST1+0.25);
                    
                    eSSS1=0.085./(0.015.*SST1+0.25);
                    eSSS1=eSSS1.*mask;
                    
                    eSSS1=eSSS1.*fact_dist;
                    %  figure; hold on; title(['Aquarius SSS error, ' name_res(7:14) ] ); imagesc(eSSS1'); colorbar; axis tight; axis xy; hold off;
                    
                    figure; subplot(2,1,1); hold on; imagesc((sssinter.*masq)'); caxis([34 36]); hold off
                    subplot(2,1,2); hold on; imagesc(SSS1'); caxis([34 36]); hold off
                    
                    
                    
                    keyboard
                    
                    
                    save([dirdataaqua name_res],'SSS1','tSSS1','eSSS1','SST1')
                    
                    
                    %  end
                end
            end
        end
    end
end


%%%%% preparation des fichiers
% orb='D';
% dirinput=['\\Espace\tmp15\tmpJLV\SCI' orb '\'];
% dirin=['F:\CCI_data\2020\input\aqua_data\SCI'  orb '\']
%
% for iy=1:5
%     yearc=num2str(2010+iy);
%     tt0=datenum(2010+iy,1,1,0,0,0);
%     for iday=1:365
%         dayc=num2str(iday);
%         while length(dayc)<3; dayc=['0' dayc]; end;
%
%         namepath= [dirinput yearc filesep dayc];
%         namepathin= [dirin];
%         dirrep=dir(namepath);
%
%         for ii=3:length(dirrep)
%             chainok='0_SSS_1deg.bz2';
%             if strcmp(dirrep(ii).name(end-13:end),chainok)
%                 filepath=[namepath filesep dirrep(ii).name]
%                 copyfile(filepath,namepathin)
%             end
%         end
%     end
% end

% delete([namepathin filesep '*.bz2'])


