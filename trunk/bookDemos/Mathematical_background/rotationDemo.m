%% Rotation Matrix Demo
%
%%
a = (45/180)*pi;
R = [cos(a) -sin(a) 0;
     sin(a) cos(a) 0 ;
     0 0 1]
A = R*diag([1 2 3])*R'
[U,D]=eig(A)


a = -a;
RR = [cos(a) -sin(a) 0;
     sin(a) cos(a) 0 ;
     0 0 1];

assert(approxeq(R',RR))
