function [bbs,E1] = t_edgeBoxes( I, model, varargin )


% get default parameters (unimportant parameters are undocumented)
dfs={'name','', 'alpha',.65, 'beta',.75, 'eta',1, 'minScore',.01, ...
  'maxBoxes',1e4, 'edgeMinMag',.1, 'edgeMergeThr',.5,'clusterMinMag',.5,...
  'maxAspectRatio',3, 'minBoxArea',1000, 'gamma',2, 'kappa',1.5 };
o=getPrmDflt(varargin,dfs,1); if(nargin==0), bbs=o; return; end

% run detector possibly over multiple images and optionally save results
f=o.name; if(~isempty(f) && exist(f,'file')), bbs=1; return; end
if(~iscell(I)), [bbs,E1]=edgeBoxesImg(I,model,o); else n=length(I);
  bbs=cell(n,1); parfor i=1:n, bbs{i}=edgeBoxesImg(I{i},model,o); end; end
d=fileparts(f); if(~isempty(d)&&~exist(d,'dir')), mkdir(d); end
if(~isempty(f)), save(f,'bbs'); bbs=1; end

end

function [bbs,E1] = edgeBoxesImg( I, model, o )
% Generate Edge Boxes object proposals in single image.
if(all(ischar(I))), I=imread(I); end
model.opts.nms=0; [E1,O]=edgesDetect(I,model);

% 2016-10-4
thresh=median(median(E1(find(E1>0.25))));
E1(find(E1<thresh))=0;

%
 
if(0), E=gradientMag(convTri(single(I),4)); E=E/max(E(:)); end
E=edgesNmsMex(E1,O,2,0,1,model.opts.nThreads);
bbs=edgeBoxesMex(E,O,o.alpha,o.beta,o.eta,o.minScore,o.maxBoxes,...
  o.edgeMinMag,o.edgeMergeThr,o.clusterMinMag,...
  o.maxAspectRatio,o.minBoxArea,o.gamma,o.kappa);
end
