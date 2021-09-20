% lecture des nouveaux produits Aquarius (L3 daily orbites A et D séparées)
% on ne bouche pas les trous et on abandonne la tesselation
% on pondere par l'inverse de la distance au carre
% utilise gridAquaEqua, gridAquaNorth, gridAquaSouth (produits par
% computeGRID_new.m
% correction bug sur l'annee 2012 (probleme fichiers 2011 qui se sont
% retrouves dans le repertoire 2012) Ajout d'une verif sur l'annee.

clear


for igrid=2:3
    if igrid==1
        load('G:\dataSMOS\CATDS\repro_2017\isas_CATDS_2010_2020_PlateCarree.mat');
        load('G:\dataSMOS\CATDS\repro_2017\maskdmin_ease2')
        [lat0, lon0]=meshgrid(latDGG,lonDGG);
        load('gridAquaEqua','indlatAqua','indlonAqua','dlonlatkm');  % les 4 plus proches voisins Aqua de la grille EASE (grille Aqua etendue lon2)
        % augmentation du bruit près des cotes : seulement pour grille Equa
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
        dirdataaqua='I:\Aquarius_data\RSS\L3\year3\file_mat_4\';
    elseif igrid ==2
        load('G:\dataSMOS\CATDS\repro_2017\isas_CATDS_2010_2020_Polar_North.mat');
        load('gridAquaNorth','indlatAqua','indlonAqua','dlonlatkm');
        namegrid='Polar_North.nc';
        lat0=ncread(namegrid,'latitude');
        lon0=ncread(namegrid,'longitude');
        fact_dist=0.*lat0+1;
        dirdataaqua='I:\Aquarius_data\RSS\L3\year3\file_mat_polaire_2\';
    else
        load('G:\dataSMOS\CATDS\repro_2017\isas_CATDS_2010_2020_Polar_South.mat');
        load('gridAquaSouth','indlatAqua','indlonAqua','dlonlatkm');
        namegrid='Polar_South.nc';
        lat0=ncread(namegrid,'latitude');
        lon0=ncread(namegrid,'longitude');
        fact_dist=0.*lat0+1;
        dirdataaqua='I:\Aquarius_data\RSS\L3\year3\file_mat_polaire_2\';
    end
    
    lonaqua=-179.5:1:179.5;
    lataqua=-89.5:1:89.5;
    % on elargit pour l'interpolation
    lonaqua2=-180.5:1:180.5;
    [lataqua0 lonaqua0]=meshgrid(lataqua,lonaqua2);
    lataqua0=reshape(lataqua0,size(lataqua0,1)*size(lataqua0,2),1);
    lonaqua0=reshape(lonaqua0,size(lonaqua0,1)*size(lonaqua0,2),1);
    
    if exist(dirdataaqua)==0; mkdir(dirdataaqua); end;
    
    for iorb=1:2
        
        if iorb==1; orb='A'; else; orb='D'; end;
        
        dirinput=['I:\Aquarius_data\RSS\L3\AQUA\'];
        if igrid==1
            nameaqua=['aqua' orb '_20100701.mat']   % on pose A ou D
        elseif igrid==2
            nameaqua=['aqua' orb '_north_20100701.mat']   % on pose A ou D
        else
            nameaqua=['aqua' orb '_south_20100701.mat']   % on pose A ou D
        end
        
        for iy=1:5
            year0=2010+iy;
            yearc=num2str(year0);
            tt0=datenum(2010+iy,1,1,0,0,0);
            for iday=1:365
                tt1=tt0+iday-0.5;
                dvec=datevec(tt1);
                
                dayc=num2str(iday);
                while length(dayc)<3; dayc=['0' dayc]; end;
                
                namepath= [dirinput yearc filesep];
                dirrep=dir(namepath);
                
                yearc=num2str(dvec(1));
                monc=num2str(dvec(2));
                if length(monc)<2; monc=['0' monc]; end;
                dayc=num2str(dvec(3));
                if length(dayc)<2; dayc=['0' dayc]; end;
                
                name_res=nameaqua;
                if igrid==1      % Equat
                    name_res(7:10)=yearc;
                    name_res(11:12)=monc;
                    name_res(13:14)=dayc;
                elseif igrid==2  % North
                    name_res(13:16)=yearc;
                    name_res(17:18)=monc;
                    name_res(19:20)=dayc;
                else             % South
                    name_res(13:16)=yearc;
                    name_res(17:18)=monc;
                    name_res(19:20)=dayc;
                end
                
                name_res;
                
                % on cherche le jour et l'orbite
                k=0;
                for ifi=3:length(dirrep)
                    namef=dirrep(ifi).name;
                    if str2num(namef(2:5))==year0 & str2num(namef(6:8))==iday & namef(21)==orb & dirrep(ifi).bytes > 5000  % ajout d'un test sur l'annee, 17/04/2021
                        k=1;
                        break
                    else
                        k=0;
                    end
                end
                
                
                if k==1;  % pas de jour correspondant ou jour deja traite, on quitte la boucle iday
                    
                    indisas=find(datemois_isas(:,2)==dvec(1)-2000 & datemois_isas(:,1)==dvec(2));
                    SST1=squeeze(isasTEMP(indisas,:,:));
                    
                    filepath=[namepath namef];
                    
                    % INFO = h5info(dirrep(ii).name(1:end-4))
                    jdmoy=tt1;
                    
                    % on lit les SSS
                    %  if exist(filepathin(1:end-4))
                    sss=ncread(filepath,'l3m_data');
                    sss=sss(:,end:-1:1);  % lat dans le mauvais sens
                    
                    % on élargit les bords de la grille Aquarius
                    sss1=zeros(362,180);
                    sss1(2:end-1,:)=sss;
                    sss1(1,:)=sss(end,:);
                    sss1(end,:)=sss(1,:);
                    
                    lataqua1=lataqua0;
                    lonaqua1=lonaqua0;
                    
                    % On cherche les points EASE qui sont entourés d'au
                    % moins 1 SSS parmi les 4 voisins Aqua sur la grille
                    % elargie
                    SSS1=nan(size(lat0,1)*size(lat0,2),1);
                    for igp=1:length(indlatAqua)
                        if isnan(indlatAqua(igp,1))==0
                            SSSaq=sss1(:,indlatAqua(igp,:));
                            SSSsel=SSSaq(indlonAqua(igp,:),:);
                            ind=find(SSSsel>0);
                            % if length(ind)==1
                            %     SSS1(igp)=SSSsel(ind);
                            if length(ind)>1
                                dist=dlonlatkm(igp,:,:);
                                dist2sel=1./(dist(ind).*dist(ind));  % ponderation par l'inverse de la distance au carre
                                sdis=sum(dist2sel);
                                SSS1(igp)=(SSSsel(ind)'*dist2sel)/sdis;
                            else
                                SSS1(igp)=NaN;
                            end
                        else
                            SSS1(igp)=NaN;
                        end
                    end
                    SSS1=reshape(SSS1,size(lat0,1),size(lat0,2));
                    tSSS1=SSS1.*0+jdmoy;
                    
                    eSSS1=0.*SSS1;
                    % formule empirique
                    mask=SSS1./SSS1;
                    % eSSS1=0.17./(0.03.*SST1+0.25);
                    
                    eSSS1=0.085./(0.015.*SST1+0.25);
                    eSSS1=eSSS1.*mask;
                    
                    eSSS1=eSSS1.*fact_dist;
                    
                    save([dirdataaqua name_res],'SSS1','tSSS1','eSSS1','SST1')
                end
            end
        end
        
    end
    
end


% verif 2012
name_res='aquaD_20121115.mat';
dirdataaqua='I:\Aquarius_data\RSS\L3\year3\file_mat_3\';
load([dirdataaqua name_res])
SSS_old=SSS1;
dirdataaqua='I:\Aquarius_data\RSS\L3\year3\file_mat_4\';
load([dirdataaqua name_res])
SSS_new=SSS1;

figure; hold on; imagesc(SSS_old'); caxis([28 38]); hold off   % en principe, ce n'est pas le memes orbites
figure; hold on; imagesc(SSS_old'-SSS_new');  hold off   % en principe, ce n'est pas le memes orbites

