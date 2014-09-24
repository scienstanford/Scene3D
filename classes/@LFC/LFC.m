classdef LFC
    %LFC (light field class) consists of a light field and operations that
    %can be performed on a light field.
    %   
    % See Also: ppsfRayC
    
    properties
        %A 4xn matrix.  The first two rows signify the X and Y positions of
        %rays.  The last two rows signifies the x and y coordinates of a
        %unit direction vector for the rays.
        LF;  
        %The corresponding waveIndex for each ray.  nx1 in size.  n must
        %match for LF and waveIndex.
        waveIndex;
        %The wavelengths referenced by waveIndex.  wave(waveIndex) will
        %give all the wavelengths of each ray of the light field.
        wave;
    end
    
    methods
        function obj = LFC(varargin)
        % Initialization of the Light Field Class Object
        %
        %  LFC('LF',lf,'wave',wave,'waveIdx',waveIdx);
        %
        
            for ii=1:2:length(varargin)
                p = ieParamFormat(varargin{ii});
                switch p
                    case 'lf'  %TODO: error checking for LF matching waveIndex
                        obj.LF = varargin{ii+1};
                    case 'waveindex'
                        obj.waveIndex = varargin{ii+1};
                    case 'wave'
                        obj.wave = varargin{ii+1};
                    otherwise
                        error('Unknown parameter %s\n',varargin{ii});
                end
            end
        end     
        
                % Get VoLT properties
        function res = get(obj,pName,varargin)
            % Get various derived lens properties though this call
            pName = ieParamFormat(pName);
            switch pName
                case 'lf'
                    res = obj.LF;
                case 'waveindex'
                    res = obj.waveIndex;
                case 'wave'
                    res = obj.wave;
                case 'ray'
                    % Convert the light field to a ray representation with
                    % origin and direction
                    % This should probably become a rayC object that knows
                    % about its wavelength.
                    rayOrigin = zeros(3, size(obj.LF, 2));
                    rayDir = rayOrigin;
                    
                    rayOrigin(1,:) = obj.LF(1,:);
                    rayOrigin(2,:) = obj.LF(2,:);
                    rayOrigin(3,:) = 0;        % Probably should be a variable name
                    
                    rayDir(1,:) = obj.LF(3,:);
                    rayDir(2,:) = obj.LF(4,:);
                    rayDir(3,:) = 1 - rayDir(1,:).^2 + rayDir(2,:).^2;
                    res.rayDir = rayDir; res.rayOrigin = rayOrigin;
                    
                otherwise
                    error('Unknown parameter %s\n',pName);
            end
        end
    end
    
end

