classdef psfCameraC <  handle
    % Create a point spread camera object
    %
    % Spatial units throughout are mm
    %
    % AL Vistasoft Copyright 2014
    % See Also: ppsfCameraC.
    
    % Figure out the relationship between these rays and the ppsfRays in
    % the ppsfCameraC.
    properties
        lens;
        film;
        pointSource;
        rays;
        BBoxModel;
    end
    
    methods (Access = public)
        
        %default constructor
        function obj = psfCameraC(varargin)
            % psfCameraC('lens',lens,'film',film,'point source',point);
            
            for ii=1:2:length(varargin)
                p = ieParamFormat(varargin{ii});
                switch p
                    case 'lens'
                        obj.lens = varargin{ii+1};
                    case 'film'
                        obj.film = varargin{ii+1};
                    case 'pointsource'
                        obj.pointSource = varargin{ii+1};
                    case {'blackboxmodel';'blackbox';'bbm'}
                       obj.BBoxModel = varargin{ii+1};
                    otherwise
                        error('Unknown parameter %s\n',varargin{ii});
                end
            end
            
        end
        
        function val = get(obj,param)
            % psfCamera.get('parameter name')
            % Start to set up the gets for this object
            val = [];
            param = ieParamFormat(param);
            switch param
                case 'spacing'
                    % Millimeters per sample
                    r = obj.film.resolution(1);
                    s = obj.film.size(1);
                    val = s/r;
                case 'imagecentroid'
                    % obj.get('image centroid')
                    % x,y positions (0,0) is center of the image centroid.
                    % Used for calculating centroid of the psf
                    % Could use obj.film.image for the data, rather than oi
                    % p_renderOiMatlabToolFull
                    % Figure out center pos by calculating the centroid of illuminance image
                    flm = obj.film;
                    img = flm.image;  img = sum(img,3);

                    % Force to unit area and flip up/down for a point spread
                    img = img./sum(img(:));
                    img = flipud(img);
                    % vcNewGraphWin; mesh(img);

                    % Calculate the weighted centroid/center-of-mass
                    xSample = linspace(-flm.size(1)/2, flm.size(1)/2, flm.resolution(1));
                    ySample = linspace(-flm.size(2)/2, flm.size(2)/2, flm.resolution(2));
                    [filmDistanceX, filmDistanceY] = meshgrid(xSample,ySample);
                    
                    % distanceMatrix = sqrt(filmDistanceX.^2 + filmDistanceY.^2);
                    val.X = sum(sum(img .* filmDistanceX));
                    val.Y = sum(sum(img .* filmDistanceY));
                    
                otherwise
                    error('unknown parameter %s\n',param)
            end
            
        end
        
         function val = set(obj,param,val,varargin)
            % psfCamera.set('parameter name',value)
            % Start to set up the gets for this object
%             val = [];
            param = ieParamFormat(param);
            switch param
                case {'blackboxmodel';'blackbox';'bbm'};
                    %Get the parameters from the imaging system structure to build an  equivalent Black Box Model of the lens.
                    % The ImagSyst structure has to be built with the function 'paraxCreateImagSyst'
                    % Get 'new' origin for optical axis 
                    % INPUT
                    % val= ImagSyst struct
                    % varargin {1}: polar coordinate of pointSource [ro, theta, z]
                    ImagSyst=val;
                    psPolar=varargin{1};
                    z0 = ImagSyst.cardPoints.lastVertex;
                    % Variable to append
                    efl=ImagSyst.cardPoints.fi; %focal lenght of the system
                    obj=obj.bbmSetField('effectivefocallength',efl);
                    pRad = ImagSyst.Petzval.radius; % radius of curvature of focal plane
                    obj=obj.bbmSetField('focalradius',pRad);
                    Fi=ImagSyst.cardPoints.dFi;     %Focal point in the image space
                    obj=obj.bbmSetField('imagefocalpoint',Fi);
                    Hi=ImagSyst.cardPoints.dHi; % Principal point in the image space
                    obj=obj.bbmSetField('imageprincipalpoint',Hi);
                    Ni=ImagSyst.cardPoints.dNi;     % Nodal point in the image space
                    obj=obj.bbmSetField('imagenodalpoint',Ni);
                    Fo=ImagSyst.cardPoints.dFo-z0; %Focal point in the object space
                    obj=obj.bbmSetField('objectfocalpoint',Fo);
                    Ho=ImagSyst.cardPoints.dHo-z0; % Principal point in the object space
                    obj=obj.bbmSetField('objectprincipalpoint',Ho);
                    No=ImagSyst.cardPoints.dNo-z0; % Nodal point in the object space
                    obj=obj.bbmSetField('objectnodalpoint',No);
                    % abcd Matrix (Paraxial)
                    M = ImagSyst.matrix.abcd; % The 4 coefficients of the ABCD matrix of the overall system
                    obj=obj.bbmSetField('abcdmatrix',M);
                    
                    % IMAGE FORMATION                    
                    % Effective F number
                    Fnum=ImagSyst.object{end}.Radiance.Fnumber.eff; %effective F number
                    obj=obj.bbmSetField('fnumber',Fnum);
                    % Numerical Aperture
                    NA=ImagSyst.n_im.*sin(atan(ImagSyst.object{end}.Radiance.ExP.diam(:,1)./(ImagSyst.object{end}.ConjGauss.z_im-mean(ImagSyst.object{end}.Radiance.ExP.z_pos,2))));
                    obj=obj.bbmSetField('numericalaperture',NA);
                    %Field of View
                    FoV=ImagSyst.object{end}.Radiance.FoV;
                    obj=obj.bbmSetField('fieldofview',FoV);
                    % Lateral magnification
                    magn_lateral=ImagSyst.object{end}.ConjGauss.m_lat; %
                    obj=obj.bbmSetField('lateralmagnification',magn_lateral);                                   
                    % Exit Pupil
                    ExitPupil.zpos=mean(ImagSyst.object{end}.Radiance.ExP.z_pos,2);
                    ExitPupil.diam=ImagSyst.object{end}.Radiance.ExP.diam(:,1)-ImagSyst.object{end}.Radiance.ExP.diam(:,2);
                    obj=obj.bbmSetField('exitpupil',ExitPupil);
                    % Entrance Pupil
                    EntrancePupil.zpos=mean(ImagSyst.object{end}.Radiance.EnP.z_pos,2);
                    EntrancePupil.diam=ImagSyst.object{end}.Radiance.EnP.diam(:,1)-ImagSyst.object{end}.Radiance.EnP.diam(:,2);
                    obj=obj.bbmSetField('entrancepupil',EntrancePupil);                    
                    % Gaussian Image Point
                    iP_zpos=ImagSyst.object{end}.ConjGauss.z_im-z0; %image point z position
                    iP_h=psPolar(1).*magn_lateral;% image point distance from the optical axis
                    [iP(:,1),iP(:,2),iP(:,3)]=coordPolar2Cart3D(iP_h,psPolar(2),iP_zpos);
                    obj=obj.bbmSetField('gaussianimagepoint',iP);                    
                    % Aberration
                    % Primary Aberration
                    paCoeff=ImagSyst.object{end}.Wavefront.PeakCoeff;
                    obj=obj.bbmSetField('primaryaberration',paCoeff);
                    % Defocus
                    [obj_x,obj_y,obj_z]=coordPolar2Cart3D(psPolar(1),psPolar(2),psPolar(3)); 
                    Obj.z=obj_z; Obj.y=obj_y;
                    [defCoeff] = paEstimateDefocus(ImagSyst,Obj,'best');
                    obj=obj.bbmSetField('defocus',defCoeff);
                    
                otherwise
                    error('unknown parameter %s\n',param)
            end
            
        end
        
    end
    
end