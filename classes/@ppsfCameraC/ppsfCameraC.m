classdef ppsfCameraC <  psfCameraC
    % The superclass is psfCameraC.
    % This ppsfRay object is added to this subclass.
    %
    %   ppsfCamera = ppsfCameraC;
    %
    % Spatial units throughout are mm
    %
    % For ray tracing, the sensor plane is called the 'film'.  At some
    % point we will need to be able to convert data from the ISET sensor
    % object and this film object.  In the fullness of time, they may be
    % closely coordinated.
    %
    % The film properties are
    %
    %   position - relative to lens
    %   size     - size in millimeters (height, width)
    %   wave     - sample wavelengths
    %   waveConversion - we will see
    %   resolution - Number of samples (pixels) in the film plane
    %
    % AL Vistasoft Copyright 2014
    
    properties
        ppsfRays;
    end
    
    methods (Access = public)
         function obj = ppsfCameraC(varargin)
             % Initialize so ppsf = ppsfCameraC; will work
             lens = [];
             film = [];
             pointSource = [];
             
             % Set the parameters
             for ii=1:2:length(varargin)
                p = ieParamFormat(varargin{ii});
                switch p
                    case 'lens'
                        lens = varargin{ii+1};
                    case 'film'
                        film = varargin{ii+1};  %must be a 2 element vector
                    case 'pointsource'
                        pointSource = varargin{ii+1};
                    otherwise
                        error('Unknown parameter %s\n',varargin{ii});
                end
             end
             
             %Use the psfCameraC constructor
             obj = obj@psfCameraC('lens', lens,...
                 'film', film, ...
                 'pointSource', pointSource);
             
             % Should we clear out rays on return and only keep ppsfRays?
             % What is the plan here?
             
         end
         
         
         
         
         function obj = recordOnFilm(obj)
             %records the psf onto film 
             % The ppsfRays 
             %film
             %obj = recordOnFilm(obj)
             %
             
            obj.ppsfRays.recordOnFilm(obj.film); 
         end
    end
    
end