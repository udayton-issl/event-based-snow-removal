clc; clear; close all;

% Camera Specs:
P = 4.86 *10^-6;    % Camera sensor width: m/pixel
W = 1280;           % Sensor Width:        pixel
H = 720;            % Sensor Hight         pixel
f = 5*10^-3;        % Focal length         m
Z = 10;             % Object Distance      m
x = P*W;            % Image Plane Width    m
y = P*H;            % Image Plane Hight    m
X = (Z./f)*x;       % Object Plane width   m
Y = (Z./f)*y;       % Object Plane hight   m

% Snow Model Parameter
D = 3*10^-3;                    % Snow Diameter        m
V = 40*(1.609344/3.6)*10^-6;    % Veichel Speed        m/uSec
N = 500;                        % Num of snowfalke in scene
Dt_threshold =.1;               % Min detection dist.  m
Dt = Z:-V:Dt_threshold;         % Snow Depth range     m

Xi = X*(rand(1,N)-.5);               % x-coordinates
Yi = Y*(rand(1,N)-.5);               % y-coordinates
Zi = Z*(ones(1,N)-.5);               % z-coordinates



% Simulate each particle idependaly & export it per file
for j = 1:length(Xi)
    % Snow Flake x,y location
    X1 = Xi(j);
    Y1 = Yi(j);

    ex=[];
    % Project particel x-location to image plane (Rang from -640 to 640)
    % for all time
    X_loc_st = (X1*f/P)./Dt(1)
    X_loc_v = (X1*f/P)./Dt;
    Band = 5;
    Xrange = [floor(X_loc_st)-sign(X_loc_st)*Band,sign(X_loc_st)*640]

    % Project particel y-location to image plane (Rang from -360 to 360)
    % for all time
    Y_loc_st = (Y1*f/P)./Dt(1)
    Y_loc_v = (Y1*f/P)./Dt;
    Yrange = [floor(Y_loc_st)-sign(Y_loc_st)*Band,sign(Y_loc_st)*360]

    % Determine the required time for the now flake to exit the sensor size
    LastT = min(sum(Y_loc_v<360 & Y_loc_v>-360),sum(X_loc_v<640 & X_loc_v>-640))

    % identify only the active region that the particle passing through
    [XX,YY] = meshgrid((min(Xrange):max(Xrange)),(min(Yrange):max(Yrange)));

    % Vectorize X & Y matrices
    XX = XX(:); 
    YY = YY(:);

    % Particle Range at the senosr plane
    Cord = [min(XX),max(XX),min(YY),max(YY)]


    if LastT>0
        DT = 1:LastT;
        X_loc = (X1*f/P)./Dt(1:LastT);
        X_loc(1)
        Y_loc = (Y1*f/P)./Dt(1:LastT);
        Y_loc(1)
        Sig_v =  D *f/P./Dt(1:LastT);

        for m=1:length(XX)
            % Perform Gaussin filter to compute the intesity of each pixel for all T
            OUT=50*exp(-((XX(m)-X_loc).^2+(YY(m)-Y_loc).^2)./(0.5*Sig_v.^2));
            if sum(abs(OUT))~=0
                % 1. Apply log filter (add 0.3679 to avoid going to -inf)
                OUT2 = log(OUT+0.3679)+1;

                % 2. Low Pass Filter
                    %       y[n] = alpha y[n-1] + (1 - alpha) x[n]
                    % =>    Y[z] = alpha * z^-1 * Y[z] + (1-alpha) X[z]
                    %              Y[z]      (1 - alpha)
                    %       H[z] = ----- = ------------------
                    %              X[z]     (1 - alpha z^-1)
                    %  b1 = 1-alpha;
                    %  a1 = 1
                    %  a2 = -alpha;

                alpha = 0.92;
  
                b = (1-alpha);
                a = [1 -alpha];
                OUT2= filter(b,a,OUT2');
                OUT2=OUT2';

                % 3. Quantization (2,1.5,3.5)
                OUT2 = floor(OUT2*1.2);

                % 4. Compartor (where +ve and -ve increments)
                OUT2 = OUT2(:,2:end)-OUT2(:,1:end-1);

                A=find(OUT2);
                
                % if any events exists, log all:
                if isempty(A)==0
                    if isempty(ex)==1
                        ex=repmat(XX(m),size(A))';
                        ey=repmat(YY(m),size(A))';
                        ets=A';
                        ep=OUT2(A)';
                    else
                        ex=[ex;repmat(XX(m),size(A))'];
                        ey=[ey;repmat(YY(m),size(A))'];
                        ets=[ets;A'];
                        ep=[ep;OUT2(A)'];
                    end
                end
            end
        end

    end
    
    %  Sort events per time stamp and add offset in x & y
    [~,idx]=sort(ets);
    ev.x=ex(idx)+641;
    ev.y=ey(idx)+361;
    ev.ts=ets(idx);
    ev.p=ep(idx);


    clearvars -except ev Xi Yi Zi D f Z P W H N V i Dt j 

    FileName= sprintf('SnowModel_40mh_%0.0f.mat',j);
    save(FileName,'ev','-v7.3')
    clear ev

end





