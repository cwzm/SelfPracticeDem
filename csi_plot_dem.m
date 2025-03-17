%% 输入参数
if ~exist('pc','var'),     pc = []; end
if ~exist('scale','var'),  scale = []; end
if isempty(scale),         scale = 'all'; end
if ~exist('figstr','var'), figstr = []; end
if ~exist('fname','var'),  fname = []; end
if ~exist('method','var'), method = []; end
if isempty(method),        method = 1; end
if method>10
    nofig = true;
    method = method-10;
else
    nofig = false;
end
if ~exist('h','var'), h = []; end
if isempty(h)
    export_dcm = false;
else
    export_dcm = true; 
end
if ~exist('t_comb','var'), t_comb = []; end
if isempty(t_comb),        t_comb = true; end

if t_comb
    spec = mean(spec,5);
end


%% 维度设置
[ns,nx,ny,nz,nt] = size(spec);
fprintf('ns = %d, nx = %d, ny = %d, nz = %d, nt = %d\n', ns, nx, ny, nz, nt);
spec = abs(spec);

%% 绘图
figure
for l5=1:nt
    % 矩阵预处理
    ss = squeeze(spec(:,:,:,:,l5));
    if method==3, ss = permute(ss,[1 3 2 4]); end
    [n1,n2,n3,n4] = size(ss);
    fprintf('n1 = %d, n2 = %d, n3 = %d, n4 = %d\n', n1, n2, n3, n4);

    % 绘图
    for l4=1:n4
        if nofig
           fid = figure('Visible','off');
        else
            if ((n4>1)||(nt>1))
                fid = figure;
            else
                fid = gcf;
                clf;
            end
        end
        
         ss = ss/max(ss(:));  % 归一化
         if regexpi(scale,'ind')
            [~,nn2]=size(ss);
            for ll=1:nn2, ss(:,ll) = 0.8*ss(:,ll)/max(ss(:,ll)); end
         end
                axes('units','norm','pos',[0 0 1 1])
                hold on
                for l2=(-n2/2:n2/2), plot([-1 1]*n3/2,l2*[1 1],'k'); end   % 绘制网格
                for l3=(-n3/2:n3/2), plot(l3*[1 1],[-1 1]*n2/2,'k'); end   % 绘制网格
                for l2=1:n2
                    plot(linspace(-n3/2,n3/2,n1*n3),reshape(ss(:,l2,:,l4)-l2+n2/2,[n1*n3 1]),'b');
                end
                hold off
    end
end
