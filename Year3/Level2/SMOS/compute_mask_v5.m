% construction d'un masque glace a partir de Acard
% fenetre glissante de 10 jours pour une couverture complète.
% Si Acard est < seuil alors glace (Acard=2 sur la glace et 65 sur l'ocean)
% CCI 2020 repro SMOS
% nouvelle méthose d'Alex: 
% 1/ Tu prends donc les L2 Acard sur une fenêtre +/- 10 jours glissante.
% 2/ Tu calcules Acard_model(SST ecmwf, SSS smos) avec le modèle BV pour chaque mesure L2
% 3/ Si abs(Acard-Acard_model) > 1 tu comptes la mesure comme un outlier. 
% 4/ Si le pourcentage d'outliers est supérieur à 20% sur la fenêtre temporelle +/-10 jours, c'est de la glace. 
clear
set(groot,'DefaultFigureColormap',jet)

load('easegrid_new.mat')

repres='masqueAcard_10';
plot_repres='plot_masqueAcard_10';

freq=1.41350;  % GHz
alpha=0.00314; % Somaraju cste
PP=[0.000000004035165, -0.000000299656045, 0.000007662053700, -0.000078086884746, 0.000692115342716, -0.013677965710063, 1.029287588881387];
f0=17.97510;

x=[5.7230e+00, 2.2379e-02, -7.1237e-04, 5.0478e+00, -7.0315e-02, 6.0059e-04, 3.6143e+00,...
    2.8841e-02, 1.3652e-01,  1.4825e-03, 2.4166e-04];

if exist(repres)==0
    mkdir(repres)
end

if exist(plot_repres)==0
    mkdir(plot_repres)
end

repL2='J:\SSS\data\sat\dataSMOS\CCI_repro2020\file_mat_full_corr_lat_pac_RR_new\';

dirL2=dir(repL2);

indlat=find(abs(lat_fixgrid)>45);
lat_sel=lat_fixgrid(indlat);
nlat=length(lat_sel);
nlon=length(lon_fixgrid);

load('smosA_20100116.mat')
xswathlim=415;
indxswath=find(abs(xswath)<xswathlim);
ndwell=length(indxswath);
xswathsel=xswath(indxswath);
maxidw=max(indxswath);
minidw=min(indxswath);

if exist(repres)==0
    mkdir(repres)
end

if exist(plot_repres)==0
    mkdir(plot_repres)
end

% fenetre temporelle
dday=10; % pour la base temporelle gaussienne 3 jours
isigt2=1/(2*3*3);  % 1/(2sig^2)
tt=[];

ttinit=datenum(2010,1,10,0,0,0);
ttfin=datenum(2020,11,1,0,0,0);

% dtt=ttinit:ndd:ttfin;
ttlim=round(linspace(ttinit,ttfin,100));
nslice=length(ttlim)-1;
nplan=5;

for isli=1:nslice
    isli
    ndd=ttlim(isli+1)-ttlim(isli)+15;
    
    Acardtot=NaN(2*nplan*ndd,length(lon_fixgrid),length(indlat));
    vSSStot=NaN(2*nplan*ndd,length(lon_fixgrid),length(indlat));
    SSStot=NaN(2*nplan*ndd,length(lon_fixgrid),length(indlat));
    SSS0tot=NaN(2*nplan*ndd,length(lon_fixgrid),length(indlat));
    SSTtot=NaN(2*nplan*ndd,length(lon_fixgrid),length(indlat));
    tt=NaN(1,2*nplan*ndd);
    % lat_sel=lat_fixgrid(indlat);
    
    k=0;
    for ifi=(ttlim(isli)-dday):(ttlim(isli+1)+dday)  % on prend +/- dday pour eviter les coupures sur les bords
        ifi;
        datev=datevec(ifi);
        imonth=datev(2);
        monthc=num2str(datev(2));
        if length(monthc)==1; monthc=['0' monthc]; end
        dayc=num2str(datev(3));
        if length(dayc)==1; dayc=['0' dayc]; end
        annee=num2str(datev(1));
        
        nameA=['smosA_' annee monthc dayc '.mat'];
        nameD=['smosD_' annee monthc dayc '.mat'];
        
        totA=[repL2 nameA];
        totD=[repL2 nameD];
        if exist(totA) ~= 0
            
            load(totA)
            innonok=find(idwSSS0 >= maxidw | idwSSS0 <= minidw);
            SSScorrRR(innonok)=NaN;
            SSS0(innonok)=NaN;
            Acard0(innonok)=NaN;
            eSSS0(innonok)=NaN;
            SST0(innonok)=NaN;
            
            for iplan=1:nplan
                k=k+1;
                tt(k)=floor(nanmean(tSSS0(:,280,iplan)));
                if isnan(tt(k)); tt(k)=ifi; end;
                Acardtot(k,:,:)=Acard0(:,indlat,iplan);
                vSSStot(k,:,:)=1./(eSSS0(:,indlat,iplan).*eSSS0(:,indlat,iplan));
                SSStot(k,:,:)=SSScorrRR(:,indlat,iplan);
                SSS0tot(k,:,:)=SSS0(:,indlat,iplan);  % on ne prends que le premier plan temporel
                SSTtot(k,:,:)=SST0(:,indlat,iplan);
            end
        end
        if exist(totD) ~= 0 % & imonth ~= 1 & imonth ~= 10 & imonth ~= 11 & imonth ~= 12
            load(totD)
            % on supprime la partie de la fauchee foireuse pendant les mois
            % a eclipse. On fait cette supression egalement le reste de
            % l'annee pour etre homogene en couverture
            innonok=find(idwSSS0 >= maxidw | idwSSS0 <= 15);
            SSScorrRR(innonok)=NaN;
            SSS0(innonok)=NaN;
            Acard0(innonok)=NaN;
            eSSS0(innonok)=NaN;
            SST0(innonok)=NaN;
            for iplan=1:nplan
                k=k+1;
                tt(k)=floor(nanmean(tSSS0(:,280,iplan)));
                if isnan(tt(k)); tt(k)=ifi; end;
                Acardtot(k,:,:)=Acard0(:,indlat,iplan);
                vSSStot(k,:,:)=1./(eSSS0(:,indlat,iplan).*eSSS0(:,indlat,iplan));
                SSStot(k,:,:)=SSScorrRR(:,indlat,iplan);
                SSS0tot(k,:,:)=SSS0(:,indlat,iplan);
                SSTtot(k,:,:)=SST0(:,indlat,iplan);
            end
            
        end
        % SSStot(k,:,:)=SSScorrRR(:,indlat);
        % SSTtot(k,:,:)=SST0(:,indlat);
    end
    
    Acardtot=Acardtot(1:k,:,:);
    SSStot=SSStot(1:k,:,:);
    vSSStot=vSSStot(1:k,:,:);
    SSTtot=SSTtot(1:k,:,:);
    SSS0tot=SSS0tot(1:k,:,:);
    tt=tt(1:k);
    
    n1fSST=((45.00 + SSTtot)./(x(4) + x(5).*SSTtot + x(6).*SSTtot.*SSTtot)).*(PP(1)*SSTtot.*SSTtot.*SSTtot.*SSTtot.*SSTtot.*SSTtot + PP(2)*SSTtot.*SSTtot.*SSTtot.*SSTtot.*SSTtot + PP(3)*SSTtot.*SSTtot.*SSTtot.*SSTtot + PP(4)*SSTtot.*SSTtot.*SSTtot + PP(5)*SSTtot.*SSTtot + PP(6)*SSTtot + PP(7));
    epsr = ((1-SSS0tot.*alpha).*((3.70886e4 - 8.2168e1*SSTtot)./(4.21854e2 + SSTtot)) - (x(1) + x(2).*SSTtot + x(3).*SSTtot.*SSTtot))./(1.0 + j.*(freq./(n1fSST))) + (x(1) + x(2).*SSTtot + x(3).*SSTtot.*SSTtot) - j.*(2.903602 + 8.60700e-2.*SSTtot + 4.738817e-4.*SSTtot.*SSTtot - 2.9910e-6.*SSTtot.*SSTtot.*SSTtot + 4.3047e-9.*SSTtot.*SSTtot.*SSTtot.*SSTtot).*(SSS0tot.*(37.5109+5.45216.*SSS0tot+1.4409e-2.*SSS0tot.*SSS0tot)./(1004.75+182.283.*SSS0tot+SSS0tot.*SSS0tot)).*(1.0 + (SSTtot-15.0).*((6.9431+3.2841.*SSS0tot-9.9486e-2.*SSS0tot.*SSS0tot)./(84.850+69.024.*SSS0tot+SSS0tot.*SSS0tot))./((49.843 - 0.2276.*SSS0tot + 0.198e-2.*SSS0tot.*SSS0tot)+SSTtot)).*f0./freq;
    
    %  epsr=epsr_BV(SST0,SSS0);
    Acardmodtot=eps2acard(epsr);
    
    clear epsr
    
    for ij=ttlim(isli):ttlim(isli+1)
        tt0=ij;
        
        %Acard_mean=squeeze(nanmedian(Acardtot(indt,:,:)));
        %Acardmod_mean=squeeze(nanmedian(Acardmodtot(indt,:,:)));
        indt2=find(tt<tt0+dday & tt>tt0-dday);
        length(indt2);
        SSSsel=SSStot(indt2,:,:);
        SSTsel=SSTtot(indt2,:,:);
        mask=SSSsel./SSSsel;
        Acardsel=Acardtot(indt2,:,:).*mask;
        Acardmodsel=Acardmodtot(indt2,:,:).*mask;
        dAcard=Acardsel-Acardmodsel;
        ndata=squeeze(nansum(mask));
        imeasAcardsup1=find(abs(dAcard)>1);
        dAcardNsup1=zeros(size(dAcard,1),size(dAcard,2),size(dAcard,3));
        dAcardNsup1(imeasAcardsup1)=1;
        propsup1=squeeze(sum(dAcardNsup1))./ndata;
                
        Acard_std=squeeze(nanstd(Acardsel));
        SSS_std=squeeze(nanstd(SSSsel.*mask));
        
        SSS_mean=squeeze(nanmean(SSSsel.*mask));
        SST_mean=squeeze(nanmean(SSTsel.*mask));
        Acard_mean=squeeze(nanmean(Acardsel));
        Acardmod_mean=squeeze(nanmean(Acardmodsel));
        
        % SSS_mean=squeeze(nanmedian(SSStot(indt,:,:)));
        % SST_mean=squeeze(nanmedian(SSTtot(indt,:,:)));
        datev=datevec(tt0);
        yyy=datev(1);
        monthc=num2str(datev(2));
        if length(monthc)==1; monthc=['0' monthc]; end
        dayc=num2str(datev(3));
        if length(dayc)==1; dayc=['0' dayc]; end
        save([repres '/Acard_' num2str(datev(1)) monthc dayc],'Acard_mean','Acard_std','Acardmod_mean','SSS_mean','SST_mean','ndata','indlat','lat_sel','propsup1')
        
        
        if mod(ij,5)==0 & yyy==2015
            figure
            subplot(2,3,1); hold on; title(['ndata,' num2str(datev(1)) monthc dayc ])
            imagesc(ndata'); caxis([0 20]); colorbar; axis tight; hold off
            subplot(2,3,2); hold on; title('SSS mean')
            imagesc(SSS_mean'); caxis([28 38]); colorbar; axis tight; hold off
            subplot(2,3,3); hold on; title('Acard mean')
            imagesc(Acard_mean'); caxis([40 55]); colorbar; axis tight; hold off
            subplot(2,3,4); hold on; title('Acard std')
            imagesc(Acard_std'); caxis([0 5]); colorbar; axis tight; hold off
            subplot(2,3,5); hold on; title('Acard-mod')
            imagesc(Acard_mean'-Acardmod_mean'); caxis([-1 1]); colorbar; axis tight; hold off
            subplot(2,3,6); hold on; title('SSS std')
            imagesc(SSS_std'); caxis([0 5]); colorbar; axis tight; hold off
            saveas(gcf,[plot_repres  '/Acard_' num2str(datev(1)) monthc dayc ],'png')
            
            close all
        end
    end
    % keyboard
end

figure
subplot(2,3,1)
hold on
title('SST mean')
imagesc(SST_mean'); caxis([0 10]); colorbar; axis tight
hold off
subplot(2,3,2)
hold on
title('SSS mean')
imagesc(SSS_mean'); caxis([28 38]); colorbar; axis tight
hold off
subplot(2,3,3)
hold on
title('Acard mean')
imagesc(Acard_mean'); caxis([40 55]); colorbar; axis tight
hold off
subplot(2,3,4)
hold on
title('Acard std')
imagesc(Acard_std'); caxis([0 10]); colorbar; axis tight
hold off
subplot(2,3,5)
hold on
title('Acard-mod')
imagesc(Acard_mean'-Acardmod_mean'); caxis([-1 1]); colorbar; axis tight
hold off



