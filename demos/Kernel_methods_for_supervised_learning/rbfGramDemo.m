%% Demo of an RBF gram matrix
%
%%

setSeed(2);
mu = [0 0; 0 1; 1 1; 1 0]; 
sigma = 0.05;
N = 9;
K = 4;
pi = normalize(ones(1,3));
X = zeros(N,2);
%z = sampleDiscrete(pi,1,N);
z = [1 1 1 2 2 2 3 3 3];
for c=1:3
   ndx = find(z==c);
   Nc = length(ndx);
   model = struct('mu', mu(c, :), 'Sigma', sigma*eye(2));
   X(ndx,:) = gaussSample(model, Nc);
end

figure;
%scatter(X(:,1), X(:,2));
for i=1:size(X,1)
  text(X(i,1), X(i,2), sprintf('%d', i), 'fontsize', 15);
  %plot(X(i,1), X(i,2), 'bo');
  hold on
end
colors = 'rgbc';
for i=1:K
  plot(mu(i,1), mu(i,2), 'o', 'markersize', 20, 'color', colors(i), 'linewidth', 3);
  text(mu(i,1), mu(i,2), sprintf('%d', i), 'color', colors(i), 'fontsize', 15);
end

%axis_pct
axis([-0.5 1.5 -0.5 1.5])
printPmtkFigure('rbfScatter')


K = kernelRbfSigma(X, mu, 0.5);
%figure; imagesc(K); colorbar
figure; hintonDiagram(K);
printPmtkFigure('rbfHinton')
